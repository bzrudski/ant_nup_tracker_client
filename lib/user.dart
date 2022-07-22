/*
 * user.dart
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
import 'package:ant_nup_tracker/users.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;

import 'exceptions.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String username;

  @JsonKey(name: "professional")
  final bool isProfessional;

  @JsonKey(name: "flagged")
  final bool isFlagged;

  final String institution;
  final String description;

  User(
    this.username,
    this.isProfessional,
    this.isFlagged,
    this.institution,
    this.description,
  );

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  Role get role {
    if (isFlagged) return Role.flagged;
    if (isProfessional) return Role.professional;
    return Role.citizen;
  }
}

Future<User> fetchDetailsForUser(String username) async {
  final userUrl = UrlManager.shared.urlForUser(username);
  final response = await http.get(userUrl, headers: SessionManager.shared.headers);

  if (response.statusCode == 401) throw FailedAuthenticationException();
  if (response.statusCode != 200) throw GetException(response.statusCode);

  final User user;

  try {
    user = User.fromJson(jsonDecode(response.body));
    return user;
  } catch (err, stack) {
    // print(err);
    // print(stack);
    throw JsonException();
  }
}
