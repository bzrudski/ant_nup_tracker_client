/*
 * changelog.dart
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
import 'package:ant_nup_tracker/sessions.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import 'exceptions.dart';

part 'changelog.g.dart';

@JsonSerializable()
class Changelog {
  String user;
  DateTime date;
  String event;

  Changelog(this.user, this.date, this.event);

  factory Changelog.fromJson(Map<String, dynamic> json) =>
      _$ChangelogFromJson(json);
  Map<String, dynamic> toJson() => _$ChangelogToJson(this);
}


Future<List<Changelog>> fetchChangelogForFlight(int id) async {
  final changelogUrl = UrlManager.shared.urlForHistory(id);
  // return await Future.delayed(Duration(seconds: 3), ()=>throw NoResponseException());
  try {
    final response = await http.get(changelogUrl, headers: SessionManager.shared.headers);

    if (response.statusCode == 401) throw FailedAuthenticationException();
    if (response.statusCode != 200) throw ReadException(response.statusCode);

    try {
      final parsedChanges = jsonDecode(response.body).cast<
          Map<String, dynamic>>();
      return parsedChanges
          .map<Changelog>((json) => Changelog.fromJson(json))
          .toList();
    } catch (err, stack) {
      // print(err);
      // print(stack);
      throw JsonException();
    }
  } catch (error) {
    throw NoResponseException();
  }
}

// Future<void> main() async {
//   const id = 19;
//   final changelog = await fetchChangelogForFlight(id);
//
//   // for (final change in changelog){
//   //   // print("Reading change:");
//   //   // print(change.event);
//   // }
//
//   // print("Done changelog!");
// }