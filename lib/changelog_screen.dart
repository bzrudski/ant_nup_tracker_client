/*
 * changelog_screen.dart
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

import 'package:ant_nup_tracker/changelog.dart';
import 'package:ant_nup_tracker/detail_screen.dart';
// import 'package:ant_nup_tracker/user.dart';
// import 'package:ant_nup_tracker/users.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// import 'exceptions.dart';

class ChangelogScreen extends DetailScreen<int, List<Changelog>> {
  // final int _id;

  const ChangelogScreen(int id, {List<Changelog>? initialValue, Key? key})
      : super(id, initialValue: initialValue, key: key);

  @override
  _ChangelogScreenState createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends DetailScreenState<int, List<Changelog>> {
  late TextStyle _labelStyle;

  _ChangelogScreenState() : super();

  @override
  Widget buildDetailScreen(List<Changelog> history) {
    final appLocalization = AppLocalizations.of(context)!;
    final currentLocale = appLocalization.localeName;

    TextStyle changelogTextStyle = _labelStyle.apply(fontSizeFactor: 1, fontWeightDelta: 2);

    return ListView.builder(
      itemCount: history.length * 2,
      itemBuilder: (context, index) {
        if (index.isOdd) return const Divider();
        final changelog = history[index ~/ 2];

        return Container(
          margin: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                        child:
                            Text(changelog.event, style: changelogTextStyle)),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: Text(
                    changelog.user,
                    style: _labelStyle,
                    textAlign: TextAlign.end,
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: Text(
                    DateFormat.yMMMd(currentLocale)
                        .add_jm()
                        .format(changelog.date),
                    style: _labelStyle,
                    textAlign: TextAlign.end,
                  )),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  void loadDetailFuture(int id, {bool forceReload = false}) {
    setState(() {
      detailFuture = fetchChangelogForFlight(id);
    });
  }

  @override
  String get appBarHeader =>
      AppLocalizations.of(context)!.flightHistoryAppBarHeader(id);

  @override
  Widget build(BuildContext context) {
    _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);

    return super.build(context);
  }
}
