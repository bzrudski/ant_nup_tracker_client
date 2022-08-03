/*
 * sessions.dart
 * Copyright (c) 2020-2022, Abouheif Lab.
 *
 * AntNupTracker, mobile app for recording and managing ant nuptial flight data
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:convert';
import 'dart:io';
import 'package:ant_nup_tracker/common_ui_elements.dart';
import 'package:ant_nup_tracker/edit_user_profile.dart';
import 'package:ant_nup_tracker/exceptions.dart';
import 'package:ant_nup_tracker/filtering.dart';
import 'package:ant_nup_tracker/flights.dart';
import 'package:ant_nup_tracker/launch_url.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'users.dart';
import 'dark_mode_theme_ext.dart';

part 'sessions.g.dart';
//
// abstract class LoginObserver {
//   void loggedIn();
// }
//
// abstract class LogoutObserver {
//   void loggedOut();
// }

class SessionManager {
  SessionManager._();

  static final shared = SessionManager._();

  // LoginObserver? loginObserver;
  // LogoutObserver? logoutObserver;

  Session? _session;
  String? firebaseToken;
  bool get isLoggedIn => _session != null;
  Session? get session => _session;

  Map<String, String> get headers =>
      {if (isLoggedIn) "Authorization": "Token ${_session!.token}"};

  final secureStorage = const FlutterSecureStorage();

  Future<void> login(BuildContext context,
      {required String username, required String password}) async {
    // print("Device token: $firebaseToken");
    _session = await _login(context,
        username: username,
        password: password,
        notificationToken: firebaseToken);
    _session!.loadNotificationSettings();
    saveCredentials();
    // loginObserver?.loggedIn();
  }

  Future<void> logout() async {
    if (_session != null) {
      await _logout(_session!);
      _session = null;
      clearCredentials();
    }
    // logoutObserver?.loggedOut();
  }

  Future<bool> saveCredentials() async {
    if (!isLoggedIn) {
      return true;
    }

    final credentials = jsonEncode({
      "username": _session!.username,
      "token": _session!.token,
      "deviceId": _session!.deviceId
    });

    try {
      await secureStorage.write(key: "credentials", value: credentials);
      // print("Saved credentials");
      return true;
    } on PlatformException catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      return false;
    }
  }

  Future<bool> loadAndVerifyCredentials() async {
    try {
      // await clearCredentials();
      final credentials = await secureStorage.read(key: "credentials");

      // print("Loaded credentials: $credentials");

      if (credentials == null) return false;

      final decodedCredentials =
          jsonDecode(credentials) as Map<String, dynamic>;
      final username = decodedCredentials["username"] as String;
      final token = decodedCredentials["token"] as String;
      final deviceId = decodedCredentials["deviceId"] as int;

      _session = await verifyToken(username, token, deviceId);

      if (_session != null) {
        _session!.loadNotificationSettings();
        return true;
      }

      return false;
    } on PlatformException catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      return false;
    } on LocalisableException {
      rethrow;
    } on Exception catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      throw JsonException();
    }
  }

  Future<bool> clearCredentials() async {
    try {
      await secureStorage.deleteAll();
      return true;
    } on PlatformException catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      return false;
    }
  }

  void updateUserInformation(User user) {
    _session = Session(_session!.token, _session!.deviceId, user);
  }
}

@JsonSerializable(createToJson: false, explicitToJson: true)
class Session {
  final String token;

  @JsonKey(name: "deviceID")
  final int deviceId;

  @JsonKey(name: "user")
  final User user;

  Role get role => user.role;
  String get username => user.username;
  String get institution => user.institution;
  String get description => user.description;

  Session(this.token, this.deviceId, this.user);

  @JsonKey(ignore: true)
  TaxonomyFilter? _notificationSettings;

  bool get hasNotificationSettingsLoaded => _notificationSettings != null;
  TaxonomyFilter get notificationSettings => _notificationSettings!;

  // late Future<TaxonomyFilter> _loadNotificationSettingsFuture;
  //
  // Future<TaxonomyFilter> get loadNotificationSettingsFuture =>
  //     _loadNotificationSettingsFuture;

  Future<TaxonomyFilter> loadNotificationSettings(
      {bool forceReload = false}) async {
    // _notificationSettings = await _getNotificationSettings();
    // _loadNotificationSettingsFuture = _getNotificationSettings()
    //     .then((settings) {
    //       print("Loaded ${settings.genera.length} genera and ${settings.species.length} species");
    //       return _notificationSettings = settings;
    //     })
    //     .onError((error, stackTrace) {
    //   print(error);
    //   print(stackTrace);
    //   throw Exception("Error loading notification settings.");
    // });

    if (!forceReload && hasNotificationSettingsLoaded) {
      return notificationSettings;
    }

    _notificationSettings = await _getNotificationSettings();
    // print(
    //     "Loaded ${_notificationSettings!.genera.length} genera and ${_notificationSettings!.species.length} species");
    return _notificationSettings!;
  }

  Future<void> updateNotificationSettings({
    Set<Genus> addedGenera = const {},
    Set<Species> addedSpecies = const {},
    Set<Genus> removedGenera = const {},
    Set<Species> removedSpecies = const {},
  }) async {
    final generaUrl = UrlManager.shared.myGeneraUrl;
    final speciesUrl = UrlManager.shared.mySpeciesUrl;

    final headers = {
      "Authorization": "Token $token",
      "Content-Type": "application/json"
    };

    List<Genus>? newGenera;
    List<Species>? newSpecies;

    try {
      if (addedGenera.isNotEmpty) {
        final body = jsonEncode(addedGenera.map((e) => {"id": e.id}).toList());

        // print("Sending $body");

        final response =
            await http.post(generaUrl, body: body, headers: headers);

        final statusCode = response.statusCode;

        if (statusCode == 401) throw FailedAuthenticationException();
        if (statusCode != 200) throw NotificationUpdateException(statusCode);

        try {
          final results = jsonDecode(response.body) as List<dynamic>;
          newGenera = results.map((e) => Genus.get(e["id"] as int)).toList();
        } catch (err, stacktrace) {
          // print(err);
          // print(stacktrace);
          throw JsonException();
        }
      }

      if (addedSpecies.isNotEmpty) {
        final body = jsonEncode(addedSpecies.map((e) => {"id": e.id}).toList());

        final response =
            await http.post(speciesUrl, body: body, headers: headers);

        final statusCode = response.statusCode;

        if (statusCode == 401) throw FailedAuthenticationException();
        if (statusCode != 200) throw NotificationUpdateException(statusCode);

        try {
          final results = jsonDecode(response.body) as List<dynamic>;
          newSpecies = results.map((e) => Species.get(e["id"] as int)).toList();
        } catch (err, stacktrace) {
          // print(err);
          // print(stacktrace);
          throw JsonException();
        }
      }
      if (removedGenera.isNotEmpty) {
        final body =
            jsonEncode(removedGenera.map((e) => {"id": e.id}).toList());

        final response =
            await http.delete(generaUrl, body: body, headers: headers);

        final statusCode = response.statusCode;

        if (statusCode == 401) throw FailedAuthenticationException();
        if (statusCode != 200) throw NotificationUpdateException(statusCode);

        try {
          final results = jsonDecode(response.body) as List<dynamic>;
          newGenera = results.map((e) => Genus.get(e["id"] as int)).toList();
        } catch (err, stacktrace) {
          // print(err);
          // print(stacktrace);
          throw JsonException();
        }
      }

      if (removedSpecies.isNotEmpty) {
        final body =
            jsonEncode(removedSpecies.map((e) => {"id": e.id}).toList());

        final response =
            await http.delete(speciesUrl, body: body, headers: headers);

        final statusCode = response.statusCode;

        if (statusCode == 401) throw FailedAuthenticationException();
        if (statusCode != 200) throw NotificationUpdateException(statusCode);

        try {
          final results = jsonDecode(response.body) as List<dynamic>;
          newSpecies = results.map((e) => Species.get(e["id"] as int)).toList();
        } catch (err, stacktrace) {
          // print(err);
          // print(stacktrace);
          throw JsonException();
        }
      }

      final newSettings = TaxonomyFilter(
        species: newSpecies ?? notificationSettings.species,
        genera: newGenera ?? notificationSettings.genera,
      );

      _notificationSettings = newSettings;
    } on IOException {
      throw NoResponseException();
    }
  }

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}

Future<TaxonomyFilter> _getNotificationSettings() async {
  assert(SessionManager.shared.isLoggedIn);

  final mySpeciesUrl = UrlManager.shared.mySpeciesUrl;
  final myGeneraUrl = UrlManager.shared.myGeneraUrl;

  try {
    final requestHeaders = {
      "Authorization": "Token ${SessionManager.shared.session!.token}"
    };
    final generaResponse = await http.get(myGeneraUrl, headers: requestHeaders);

    final generaStatus = generaResponse.statusCode;

    // print(generaResponse.body);

    if (generaStatus == 401) throw FailedAuthenticationException();
    if (generaStatus != 200) throw ReadException(generaStatus);

    final Iterable<Genus> genera;

    try {
      final rawGeneraList = jsonDecode(generaResponse.body) as List<dynamic>;
      final generaIds = rawGeneraList.map((jsonRow) => jsonRow["id"] as int);
      genera = generaIds.map((id) => Genus.get(id));
      // genera = rawGeneraList.map((e) => Genus.fromJson(e));
      // print("Loaded genera: $genera");
    } catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      throw JsonException();
    }

    final speciesResponse =
        await http.get(mySpeciesUrl, headers: requestHeaders);

    // print(speciesResponse.body);

    final speciesStatus = generaResponse.statusCode;

    if (speciesStatus == 401) throw FailedAuthenticationException();
    if (speciesStatus != 200) throw ReadException(speciesStatus);

    final Iterable<Species> species;

    try {
      final rawSpeciesList = jsonDecode(speciesResponse.body) as List<dynamic>;
      final speciesIds = rawSpeciesList.map((jsonRow) => jsonRow["id"] as int);
      species = speciesIds.map((id) => Species.get(id));
      // species = rawSpeciesList.map((e) => Species.fromJson(e));
      // print("Loaded species: $species");
    } catch (e, stacktrace) {
      // print(e);
      // print(stacktrace);
      throw JsonException();
    }

    return TaxonomyFilter(genera: genera, species: species);
  } on IOException catch (error, stacktrace) {
    // print("Error!: $error");
    // print(stacktrace);
    throw NoResponseException();
  }
}

Future<Session?> verifyToken(
    String username, String token, int deviceId) async {
  final verificationUrl = UrlManager.shared.verifyUrl;

  final body = jsonEncode({
    "deviceID": deviceId,
    "deviceToken": SessionManager.shared.firebaseToken
  });

  try {
    final response = await http.post(verificationUrl, body: body, headers: {
      "Authorization": "Token $token",
      "Content-Type": "application/json"
    });

    final status = response.statusCode;

    // print("Response: ${response.body}");

    if (status == 401) return null;
    if (status != 200) throw TokenVerificationException(status);

    try {
      final user = User.fromJson(jsonDecode(response.body));
      return Session(token, deviceId, user);
    } on Exception catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);

      throw JsonException();
    }
  } on IOException {
    throw NoResponseException();
  }
}

Map<String, String> getDeviceInfo(BuildContext context,
    [String? notificationToken]) {
  final deviceInfo = <String, String>{};

  final platform = Theme.of(context).platform;

  final String platformName;

  switch (platform) {
    case TargetPlatform.android:
      platformName = "ANDROID";
      break;
    case TargetPlatform.fuchsia:
      platformName = "FUCHSIA";
      break;
    case TargetPlatform.iOS:
      platformName = "IOS";
      break;
    case TargetPlatform.linux:
      platformName = "LINUX";
      break;
    case TargetPlatform.macOS:
      platformName = "MACOS";
      break;
    case TargetPlatform.windows:
      platformName = "WINDOWS";
      break;
  }

  // deviceInfo["platform"] = Platform.operatingSystem;
  deviceInfo["platform"] = platformName;
  deviceInfo["model"] = "device";
  if (notificationToken != null) deviceInfo["deviceToken"] = notificationToken;

  return deviceInfo;
}

Future<Session> _login(BuildContext context,
    {required String username,
    required String password,
    String? notificationToken}) async {
  if (username.isEmpty || password.isEmpty) {
    throw EmptyUsernamePasswordException();
  }

  final deviceInfo = getDeviceInfo(context, notificationToken);
  final loginUrl = UrlManager.shared.loginUrl;

  var rawAuthorization = "$username:$password";
  var authorizationBytes = rawAuthorization.codeUnits;
  final authorization = base64Encode(authorizationBytes);

  try {
    final response = await http.post(
      loginUrl,
      headers: {
        "Authorization": "Basic $authorization",
        "Content-Type": "application/json",
      },
      body: jsonEncode(deviceInfo),
    );

    final status = response.statusCode;

    if (status == 401) throw IncorrectCredentialsException();
    if (status == 403) throw ForbiddenAccessException();

    if (status != 200) throw LoginException(status);

    try {
      return Session.fromJson(jsonDecode(response.body));
    } catch (err, stacktrace) {
      // print(err);
      // print(stacktrace);
      throw JsonException();
    }
  } on IOException catch (err, stacktrace) {
    // print(err);
    // print(stacktrace);
    throw NoResponseException();
  }
}

Future<void> _logout(Session session) async {
  final logoutUrl = UrlManager.shared.logoutUrl;

  try {
    final response = await http.post(
      logoutUrl,
      headers: {
        "Authorization": "Token ${session.token}",
        "Content-Type": "application/json"
      },
    );

    final status = response.statusCode;

    if (status != 200 && status != 204) throw LogoutException(status);
  } on IOException {
    throw NoResponseException();
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loginAppBarHeader),
      ),
      body: const LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _globalKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLoading = false;

  void _triggerLogin({required String username, required String password}) {
    // print("Triggering login!!!");
    SessionManager.shared
        .login(context, username: username, password: password)
        .then((_) {
      Navigator.of(context).pop(true);
    }).catchError(
      (error, stacktrace) {
        // print(error);
        // print(stacktrace);
        final loginException = error as LocalisableException;
        showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: Text(loginException.getLocalisedName(context)),
                  content:
                      Text(loginException.getLocalisedDescription(context)),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.cancelButton),
                    )
                  ],
                ),
            barrierDismissible: false);
      },
      test: (error) => error is LocalisableException,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;

    return ListView(
      shrinkWrap: true,
      primary: true,
      // mainAxisAlignment: MainAxisAlignment.center,
      // mainAxisSize: MainAxisSize.min,
      // physics: ClampingScrollPhysics(),
      children: [
        Text(
          appLocalization.loginScreenHeader,
          style: Theme.of(context).textTheme.headline4,
          textAlign: TextAlign.center,
        ),
        Image(
          image: Theme.of(context).isDarkMode
              ? const AssetImage("assets/cartoon_ant/dark/cartoon_ant.png")
              : const AssetImage("assets/cartoon_ant/cartoon_ant.png"),
          height: 128,
        ),
        // Image.asset(name),
        Form(
          key: _globalKey,
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: TextFormField(
                  decoration: InputDecoration(
                      hintText: appLocalization.usernameLabel,
                      filled: true,
                      icon: const Icon(Icons.person)),
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalization.enterUsernameMessage;
                    }
                    return null;
                  },
                ),
              ),
              // SizedBox(),
              SizedBox(
                height: 80,
                child: TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                      hintText: appLocalization.passwordLabel,
                      filled: true,
                      icon: const Icon(Icons.lock)),
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalization.enterPasswordMessage;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submitForm(),
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(appLocalization.loginButton),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          label: Text(appLocalization.forgotPassword),
          icon: const Icon(Icons.open_in_new),
          onPressed: () async {
            final urlString = UrlManager.shared.passwordResetUrl.toString();
            await launchUrl(urlString);
          },
        ),
        ElevatedButton.icon(
          label: Text(appLocalization.createNewUser),
          icon: const Icon(Icons.open_in_new),
          onPressed: () async {
            final urlString = UrlManager.shared.createAccountUrl.toString();
            await launchUrl(urlString);
          },
        )
      ],
    );
  }

  void _submitForm() {
    if (_globalKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _triggerLogin(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextStyle _labelStyle;
  late TextStyle _headerStyle;

  Widget _buildTextLabelDetailRow({
    required String label,
    String? detail,
    TextStyle? detailStyle,
  }) {
    var textStyle = detailStyle ?? _labelStyle.apply(fontWeightDelta: 2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: _labelStyle)),
          if (detail != null)
            Expanded(
                child: Text(
              detail,
              style: textStyle,
              textAlign: TextAlign.end,
            )),
        ],
      ),
    );
  }

  Widget _buildTextLabelLongDetailRow({
    required String label,
    String? detail,
    TextStyle? detailStyle,
  }) {
    var textStyle = detailStyle ?? _labelStyle.apply(fontWeightDelta: 2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(child: Text(label, style: _labelStyle)),
              ],
            ),
          ),
          if (detail != null)
            Row(
              children: [
                Expanded(
                    child: Text(
                  detail,
                  style: textStyle,
                  textAlign: TextAlign.start,
                )),
              ],
            ),
        ],
      ),
    );
  }

  String getUserRoleString(Role role) {
    switch (role) {
      case Role.citizen:
        return AppLocalizations.of(context)!.citizenUser;
      case Role.professional:
        return AppLocalizations.of(context)!.professionalUser;
      case Role.flagged:
        return AppLocalizations.of(context)!.flaggedUser;
    }
  }

  Widget _buildUserRoleRow({required String label, required Role userRole}) {
    var textStyle = _labelStyle.apply(fontWeightDelta: 2);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: _labelStyle)),
          Container(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    getUserRoleString(userRole),
                    style: textStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
                if (userRole == Role.professional)
                  // const Icon(Icons.verified, color: Colors.green),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: const Image(
                      image: AssetImage("assets/ant_circles/green_ant.png"),
                      width: 32.0,
                    ),
                  ),
                if (userRole == Role.flagged)
                  // const Icon(Icons.warning, color: Colors.red)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: const Image(
                      image: AssetImage("assets/ant_circles/red_ant.png"),
                      width: 32.0,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await SessionManager.shared.logout();
    Navigator.of(context).pop(true);
  }

  Future<void> editUserInfo() async {
    // Actions for editing user profile information go here.
    final didChangeUserInfo = await Navigator.of(context).push(
        MaterialPageRoute<bool>(
            builder: (context) => const EditUserProfileScreen(),
            fullscreenDialog: true));

    if (didChangeUserInfo ?? false) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SessionManager.shared.session!.username),
        actions: [
          IconButton(
            onPressed: editUserInfo,
            icon: const Icon(Icons.edit),
            tooltip: AppLocalizations.of(context)!.edit,
          )
        ],
      ),
      body:
          SafeArea(child: _buildUserTable(SessionManager.shared.session!.user)),
    );
  }

  Widget _buildUserTable(User user) {
    final appLocalization = AppLocalizations.of(context)!;
    // final currentLocale = appLocalization.localeName;
    _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);
    _headerStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontWeightDelta: 2);

    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(16),
      textStyle: _headerStyle,
      primary: Colors.red,
    );

    return RefreshIndicator(
      onRefresh: () async {
        SessionManager.shared.session!
            .loadNotificationSettings(forceReload: true);
        setState(() {});
      },
      child: ListView(
        primary: true,
        padding: const EdgeInsets.all(16.0),
        children: [
          HeaderRow(label: appLocalization.userInformation),
          _buildTextLabelDetailRow(
              label: appLocalization.usernameLabel, detail: user.username),
          _buildUserRoleRow(
              label: appLocalization.userRoleLabel, userRole: user.role),
          if (user.institution.isNotEmpty)
            _buildTextLabelDetailRow(
                label: appLocalization.institutionLabel,
                detail: user.institution),
          if (user.description.isNotEmpty)
            _buildTextLabelLongDetailRow(
                label: appLocalization.userDescriptionLabel,
                detail: user.description),
          const SizedBox(height: 16),
          HeaderRow(label: appLocalization.notificationSettings),
          TaxonomyNotificationRow(
            onNotificationSettingsChanged: (newFilter) {
              SessionManager.shared.session!.loadNotificationSettings();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: logout,
              label: Text(appLocalization.logoutButton),
              icon: const Icon(Icons.logout),
              style: buttonStyle,
            ),
          ),
          HeaderRow(label: appLocalization.moreInformation),
          ListTile(
            title: Text(appLocalization.homePageButton),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final urlString = UrlManager.shared.homeUrl.toString();
              await launchUrl(urlString);
            },
          ),
          ListTile(
            title: Text(appLocalization.privacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final urlString = UrlManager.shared.privacyUrl.toString();
              await launchUrl(urlString);
            },
          ),
          ListTile(
            title: Text(appLocalization.termsOfUse),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final urlString = UrlManager.shared.termsUrl.toString();
              await launchUrl(urlString);
            },
          ),
          ListTile(
            title: Text(appLocalization.contactUs),
            trailing: const Icon(Icons.email),
            onTap: () async {
              final urlString = UrlManager.shared.contactUrl.toString();
              await launchUrl(urlString);
            },
          ),
          ListTile(
            title: Text(appLocalization.packagesInfo),
            trailing: const Icon(Icons.code),
            onTap: () async {
              // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PackagesScreen()));
              showLicensePage(
                  context: context,
                  applicationLegalese: appLocalization.applicationLegalese,
                  applicationIcon: Image(
                    image: Theme.of(context).isDarkMode
                        ? const AssetImage(
                            "assets/cartoon_ant/dark/cartoon_ant.png")
                        : const AssetImage(
                            "assets/cartoon_ant/cartoon_ant.png"),
                    height: 80,
                    matchTextDirection: true,
                  ));
            },
          ),
        ],
      ),
    );
  }
}

class TaxonomyNotificationRow extends StatefulWidget {
  const TaxonomyNotificationRow({
    Key? key,
    // required this.future,
    required this.onNotificationSettingsChanged,
  }) : super(key: key);

  // final Future<TaxonomyFilter> future;
  final void Function(TaxonomyFilter) onNotificationSettingsChanged;

  @override
  _TaxonomyNotificationRowState createState() =>
      _TaxonomyNotificationRowState();
}

class _TaxonomyNotificationRowState extends State<TaxonomyNotificationRow> {
  late AppLocalizations _appLocalizations;

  Future<TaxonomyFilter> future =
      SessionManager.shared.session!.loadNotificationSettings();

  final _genera = <Genus>{};
  final _species = <Species>{};

  // @override
  // void initState() {
  //   // future = widget.future;
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    var labelTheme = Theme.of(context).textTheme.subtitle1;

    return FutureBuilder(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<TaxonomyFilter> snapshot) {
        // print("Future has state: ${snapshot.connectionState}");
        // print("Future has data: ${snapshot.data}");

        if (snapshot.hasError) {
          final error = snapshot.error as LocalisableException;
          return ExceptionWidget(error, () {
            SessionManager.shared.session!.loadNotificationSettings();
            setState(() => future =
                SessionManager.shared.session!.loadNotificationSettings());
          });
        }

        if (snapshot.connectionState == ConnectionState.done) {
          final notificationSettings = snapshot.data!;
          _genera
            ..clear()
            ..addAll(notificationSettings.genera);
          _species
            ..clear()
            ..addAll(notificationSettings.species);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _appLocalizations.notifyingByGenera(_genera.length),
                      style: labelTheme,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _appLocalizations.notifyingBySpecies(_species.length),
                      style: labelTheme,
                    ),
                  )
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: _appLocalizations.edit,
                onPressed: () async {
                  // final newFilter = await Navigator.of(context)
                  //     .push<TaxonomyFilter>(MaterialPageRoute(
                  //   builder: (context) => TaxonomyFilteringScreen(
                  //     selectedGenera: _genera,
                  //     selectedSpecies: _species,
                  //   ),
                  // ));

                  final newFilter = await Navigator.of(context)
                      .push<TaxonomyFilter>(MaterialPageRoute(
                          builder: (context) => TaxonomyFilteringScreen(
                                selectedGenera: List.of(_genera),
                                selectedSpecies: List.of(_species),
                                taxonomySelectionScreenType:
                                    TaxonomySelectionScreenType.notifications,
                                onFilteringSaved: (newFilter) async {
                                  if (newFilter == null) return;

                                  final newGenera = newFilter.genera.toSet();
                                  final newSpecies = newFilter.species.toSet();

                                  final addedGenera =
                                      newGenera.difference(_genera);
                                  final addedSpecies =
                                      newSpecies.difference(_species);

                                  final removedGenera =
                                      _genera.difference(newGenera);
                                  final removedSpecies =
                                      _species.difference(newSpecies);

                                  await SessionManager.shared.session!
                                      .updateNotificationSettings(
                                          addedGenera: addedGenera,
                                          addedSpecies: addedSpecies,
                                          removedGenera: removedGenera,
                                          removedSpecies: removedSpecies);
                                },
                              ),
                          fullscreenDialog: true));

                  if (newFilter == null) {
                    // print("No new filter");
                    return;
                  }

                  // print("Reloading");

                  setState(() {
                    // _genera
                    //   ..clear()
                    //   ..addAll(newFilter.genera);
                    // _species
                    //   ..clear()
                    //   ..addAll(newFilter.species);

                    future = Future(() =>
                        SessionManager.shared.session!.notificationSettings);

                    // future = SessionManager.shared.session!
                    //     .loadNotificationSettings(forceReload: true);
                  });

                  // widget.onNotificationSettingsChanged(newFilter);

                  // SessionManager.shared.session!.loadNotificationSettings();
                  // setState(() => future = SessionManager
                  //     .shared.session!.loadNotificationSettings(forceReload: true));

                  // if (newFilter != null) {
                  //   setState(() {
                  //     _genera = newFilter.genera;
                  //     _species = newFilter.species;
                  //   });
                  // }
                },
              )
            ],
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              Text(_appLocalizations.loadingNotificationSettings)
            ],
          );
        }
      },
    );
  }
}
