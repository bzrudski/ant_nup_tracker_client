/*
 * user_detail_screen.dart
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

import 'package:ant_nup_tracker/detail_screen.dart';
import 'package:ant_nup_tracker/user.dart';
import 'package:ant_nup_tracker/users.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserDetailScreen extends DetailScreen<String, User> {
  // final String _username;

  const UserDetailScreen(String username, {User? initialValue, Key? key})
      : super(username, initialValue: initialValue, key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends DetailScreenState<String, User> {
  // final String _username;

  late TextStyle _labelStyle;
  // late TextStyle _headerStyle;
  late AppLocalizations _appLocalizations;

  _UserDetailScreenState() : super();

  Widget _buildTextLabelDetailRow({
    required String label,
    String? detail,
    TextStyle? detailStyle,
  }) {
    var textStyle = detailStyle ?? _labelStyle.apply(fontWeightDelta: 2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
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
      margin: const EdgeInsets.symmetric(vertical: 12.0),
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
      margin: const EdgeInsets.symmetric(vertical: 12.0),
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
                      image:
                      AssetImage("assets/ant_circles/green_ant.png"),
                      width: 32.0,
                    ),
                  ),
                if (userRole == Role.flagged)
                  // const Icon(Icons.warning, color: Colors.red)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: const Image(
                      image:
                      AssetImage("assets/ant_circles/red_ant.png"),
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

  @override
  Widget buildDetailScreen(User user) {
    // final _appLocalizations = AppLocalizations.of(context)!;
    // final currentLocale = _appLocalizations.localeName;

    _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);
    // _headerStyle =
    //     Theme.of(context).textTheme.bodyText2!.apply(fontWeightDelta: 2);

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        _buildTextLabelDetailRow(
            label: _appLocalizations.usernameLabel, detail: user.username),
        _buildUserRoleRow(
            label: _appLocalizations.userRoleLabel, userRole: user.role),
        if (user.institution.isNotEmpty)
          _buildTextLabelDetailRow(
              label: _appLocalizations.institutionLabel,
              detail: user.institution),
        if (user.description.isNotEmpty)
          _buildTextLabelLongDetailRow(
              label: _appLocalizations.userDescriptionLabel,
              detail: user.description)
      ],
    );
  }

  @override
  String get appBarHeader =>
      AppLocalizations.of(context)!.userDetailsAppBarHeader(id);

  @override
  void loadDetailFuture(String id, {bool forceReload = false}) {
    setState(() {
      detailFuture = fetchDetailsForUser(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    // final currentLocale = AppLocalizations.of(context)!.localeName;
    _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);
    // _headerStyle =
    //     Theme.of(context).textTheme.bodyText2!.apply(fontWeightDelta: 2);

    return super.build(context);

    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text(),
    //   ),
    //   body: FutureBuilder(
    //     future: fetchDetailsForUser(_username),
    //     builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
    //       if (snapshot.hasData) {
    //         return _buildUserTable(snapshot.data!);
    //       } else {
    //         return CircularProgressIndicator();
    //       }
    //     },
    //   ),
    // );
  }
}
