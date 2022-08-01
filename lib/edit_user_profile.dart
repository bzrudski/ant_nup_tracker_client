/*
 * edit_user_profile.dart
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

import 'package:ant_nup_tracker/exceptions.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:ant_nup_tracker/user.dart';
import 'package:ant_nup_tracker/users.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'sessions.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  Future<void> saveUserInformation() async {
    if (!_globalKey.currentState!.validate()) {
      return;
    }

    final existingUser = SessionManager.shared.session!.user;
    final description = _descriptionController.text;
    final institution = _institutionController.text;
    final newUser = User(
      existingUser.username,
      existingUser.isProfessional,
      existingUser.isFlagged,
      institution,
      description,
    );
    try {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(_appLocalizations.updatingProfileDetails),
                content: const LinearProgressIndicator(),
              ),
          barrierDismissible: false);
      await updateUserProfile(newUser);
      Navigator.of(context).pop(true);
      SessionManager.shared.updateUserInformation(newUser);
      Navigator.of(context).pop(true);
    } on LocalisableException catch (error) {
      Navigator.of(context).pop(true);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(error.getLocalisedName(context)),
          content: Text(error.getLocalisedDescription(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(_appLocalizations.ok),
            )
          ],
        ),
      );
    }
  }

  final _globalKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _institutionController =
        TextEditingController(text: SessionManager.shared.session!.institution);
    _descriptionController =
        TextEditingController(text: SessionManager.shared.session!.description);
  }

  late final TextEditingController _institutionController;
  late final TextEditingController _descriptionController;

  String getUserRoleString(Role role) {
    switch (role) {
      case Role.citizen:
        return _appLocalizations.citizenUser;
      case Role.professional:
        return _appLocalizations.professionalUser;
      case Role.flagged:
        return _appLocalizations.flaggedUser;
    }
  }

  late AppLocalizations _appLocalizations;

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_appLocalizations.editUserProfile),
        actions: [
          IconButton(
            onPressed: saveUserInformation,
            icon: const Icon(Icons.done),
            tooltip: _appLocalizations.done,
          )
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            _globalKey.currentState!.save();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: _globalKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              primary: true,
              children: [
                SizedBox(
                  height: 92,
                  child: TextFormField(
                    initialValue: SessionManager.shared.session!.username,
                    readOnly: true,
                    decoration: InputDecoration(
                        filled: true,
                        labelText: _appLocalizations.usernameLabel,
                        helperText: _appLocalizations.cannotEditUsername),
                  ),
                ),
                SizedBox(
                  height: 92,
                  child: TextFormField(
                    initialValue:
                        getUserRoleString(SessionManager.shared.session!.role),
                    readOnly: true,
                    decoration: InputDecoration(
                        filled: true,
                        labelText: _appLocalizations.userRoleLabel,
                        helperText: _appLocalizations.cannotEditRole),
                  ),
                ),
                if (SessionManager.shared.session!.role == Role.professional)
                  SizedBox(
                    height: 92,
                    child: TextFormField(
                        controller: _institutionController,
                        decoration: InputDecoration(
                            filled: true,
                            labelText: _appLocalizations.institutionLabel),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return _appLocalizations.enterInstitutionMessage;
                          }

                          return null;
                        },
                        textCapitalization: TextCapitalization.words),
                  ),
                SizedBox(
                  height: 184,
                  child: TextFormField(
                    controller: _descriptionController,
                    minLines: 6,
                    maxLines: 6,
                    decoration: InputDecoration(
                        filled: true,
                        labelText: _appLocalizations.userDescriptionLabel,
                        helperText: _appLocalizations.optionalField),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> updateUserProfile(User user) async {
  final url = UrlManager.shared.urlForUser(user.username);
  final body = jsonEncode(user);
  final headers = Map<String, String>.from(SessionManager.shared.headers);

  headers["Content-Type"] = "application/json";

  try {
    final response = await http.put(url, body: body, headers: headers);
    final statusCode = response.statusCode;

    // print(response.body);

    if (statusCode == 403) {
      throw ForbiddenAccessException();
    }

    if (statusCode == 401) {
      throw InsufficientPrivilegesException();
    }

    if (statusCode != 200) {
      throw EditUserException(statusCode);
    }
  } on IOException catch (error, stacktrace) {
    // print(error);
    // print(stacktrace);
    throw NoResponseException();
  }
}
