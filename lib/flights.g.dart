/*
 * flights.g.dart
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

part of 'flights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// BaseFlight _$BaseFlightFromJson(Map<String, dynamic> json) {
//
//   final latitude = (json['latitude'] as num).toDouble();
//   final longitude = (json['longitude'] as num).toDouble();
//
//   final timezone = latLngToTimezoneString(latitude, longitude);
//
//   return BaseFlight(
//     json['flightID'] as int,
//     Species.fromJson(json['taxonomy'] as Map<String, dynamic>),
//     DateTime.parse(json['dateOfFlight'] as String),
//     latitude,
//     longitude,
//     DateTime.parse(json['lastUpdated'] as String),
//     json['owner'] as String,
//     _$enumDecode(_$RoleEnumMap, json['ownerRole']),
//     json['validated'] as bool,
//   );
// }

// Map<String, dynamic> _$BaseFlightToJson(BaseFlight instance) =>
//     <String, dynamic>{
//       'flightID': instance.flightID,
//       'taxonomy': instance.taxonomy.toJson(),
//       'dateOfFlight': instance.dateOfFlight.toIso8601String(),
//       'latitude': instance.latitude,
//       'longitude': instance.longitude,
//       'lastUpdated': instance.lastUpdated.toIso8601String(),
//       'owner': instance.owner,
//       'ownerRole': _$RoleEnumMap[instance.ownerRole],
//       'validated': instance.validated,
//     };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$RoleEnumMap = {
  Role.citizen: 0,
  Role.professional: 1,
  Role.flagged: -1,
};

Flight _$FlightFromJson(Map<String, dynamic> json) {

  final latitude = (json['latitude'] as num).toDouble();
  final longitude = (json['longitude'] as num).toDouble();

  final timezone = latLngToTimezoneString(latitude, longitude);

  final location = getLocation(timezone);

  final speciesId = json['taxonomy'] as int;
  final species = Species.get(speciesId);

  return Flight(
    json['flightID'] as int,
    species,
    _$enumDecode(_$ConfidenceLevelsEnumMap, json['confidence']),
    TZDateTime.parse(location, json['dateOfFlight'] as String),
    _$enumDecode(_$FlightSizeEnumMap, json['size']),
    latitude,
    longitude,
    (json['radius'] as num).toDouble(),
    DateTime.parse(json['dateRecorded'] as String),
    json['owner'] as String,
    _$enumDecode(_$RoleEnumMap, json['ownerRole']),
    json['weather'] as bool,
    // json['image'] == null ? null : Uri.parse(json['image'] as String),
    json['validated'] as bool,
    // (json['comments'] as List<dynamic>)
    //     .map((e) => Comment.fromJson(e as Map<String, dynamic>))
    //     .toList(),
      json['validatedBy'] as String?,
      json['validatedAt'] == null
            ? null
            : DateTime.parse(json['validatedAt'] as String)
  );
    // ..validatedBy = json['validatedBy'] as String?
    // ..validatedAt = json['validatedAt'] == null
    //     ? null
    //     : DateTime.parse(json['validatedAt'] as String);
}

Map<String, dynamic> _$FlightToJson(Flight instance) => <String, dynamic>{
      'flightID': instance.flightID,
      'taxonomy': instance.taxonomy.toJson(),
      'confidence': _$ConfidenceLevelsEnumMap[instance.confidence],
      'dateOfFlight': instance.dateOfFlight.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'owner': instance.owner,
      'ownerRole': _$RoleEnumMap[instance.ownerRole],
      'validated': instance.validated,
      'radius': instance.radius,
      'dateRecorded': instance.dateRecorded.toIso8601String(),
      'weather': instance.hasWeather,
      // 'image': instance.imageUrl?.toString(),
      'size': _$FlightSizeEnumMap[instance.size],
      'validatedBy': instance.validatedBy,
      'validatedAt': instance.validatedAt?.toIso8601String(),
      // 'comments': instance.comments.map((e) => e.toJson()).toList(),
    };

const _$ConfidenceLevelsEnumMap = {
  ConfidenceLevels.low: 0,
  ConfidenceLevels.high: 1,
};

const _$FlightSizeEnumMap = {
  FlightSize.manyQueens: 0,
  FlightSize.singleQueen: 1,
};
