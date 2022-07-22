/*
 * changelog.g.dart
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changelog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Changelog _$ChangelogFromJson(Map<String, dynamic> json) {
  return Changelog(
    json['user'] as String,
    DateTime.parse(json['date'] as String),
    json['event'] as String,
  );
}

Map<String, dynamic> _$ChangelogToJson(Changelog instance) => <String, dynamic>{
      'user': instance.user,
      'date': instance.date.toIso8601String(),
      'event': instance.event,
    };
