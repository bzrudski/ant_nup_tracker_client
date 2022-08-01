/*
 * comments.dart
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
import 'package:ant_nup_tracker/users.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;

import 'sessions.dart';

part 'comments.g.dart';

@JsonSerializable()
class Comment {
  final int id;
  @JsonKey(name: 'flight')
  final int flightID;
  final String author;

  @JsonKey(name: 'role')
  final Role authorRole;
  final String text;
  final DateTime time;

  const Comment(this.id, this.flightID, this.author, this.authorRole, this.text,
      this.time);

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  // Map<String, dynamic> toJson() => _$CommentToJson(this);
  Map<String, dynamic> toJson() => {
        "text": text,
      };
}

Future<List<Comment>> getCommentsForFlight(int id) async {
  final url = UrlManager.shared.urlForComments(id);

  try {

    final response = await http.get(url, headers: SessionManager.shared.headers);

    final status = response.statusCode;

    if (status != 200) throw ReadException(status);

    try {
      final rawComments = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final comments = rawComments.map((e) => Comment.fromJson(e)).toList();
      return comments;
    } catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      throw JsonException();
    }

  } on IOException {
    throw NoResponseException();
  }
}

Future<void> addNewComment(int id, String commentText) async {
  // final data = comment.toJson();
  final data = {
    "text": commentText
  };
  final url = UrlManager.shared.urlForComments(id);

  final response = await http.post(url, body: jsonEncode(data), headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Token ${SessionManager.shared.session!.token}',
  });

  // print(response.statusCode);
  // print(response.body);

  final statusCode = response.statusCode;

  if (statusCode == 404) throw NoFlightException(id);
  if (statusCode == 401) throw FailedAuthenticationException();
  if (statusCode != 201) throw CommentCreationException(statusCode);
}

Future<void> updateComment(int id, Comment comment) async {
  final data = comment.toJson();
  final url = UrlManager.shared.urlForCommentEdit(id, comment.id);

  final response = await http.put(url, body: jsonEncode(data), headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Token ${SessionManager.shared.session!.token}',
  });

  // print(response.statusCode);
  // print(response.body);

  final statusCode = response.statusCode;

  if (statusCode == 404) throw NoFlightException(id);
  if (statusCode == 401) throw FailedAuthenticationException();
  if (statusCode != 200) throw CommentCreationException(statusCode);
}