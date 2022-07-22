/*
 * weather.g.dart
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

part of 'weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// Weather _$WeatherFromJson(Map<String, dynamic> json) {
//   return Weather(
//     json['flightID'] as int,
//     WeatherDescription.fromJson(json['description'] as Map<String, dynamic>),
//     WeatherBasic.fromJson(json['weather'] as Map<String, dynamic>),
//     WeatherDay.fromJson(json['day'] as Map<String, dynamic>),
//     json['rain'] == null
//         ? null
//         : WeatherRain.fromJson(json['rain'] as Map<String, dynamic>),
//     json['wind'] == null
//         ? null
//         : WeatherWind.fromJson(json['wind'] as Map<String, dynamic>),
//     DateTime.parse(json['timeFetched'] as String),
//   );
// }

WeatherDescription _$WeatherDescriptionFromJson(Map<String, dynamic> json) {
  return WeatherDescription(
    json['desc'] as String,
    json['longDesc'] as String,
  );
}

WeatherBasic _$WeatherBasicFromJson(Map<String, dynamic> json) {
  return WeatherBasic(
    (json['temperature'] as num).toDouble(),
    (json['pressure'] as num).toDouble(),
    (json['pressureSea'] as num?)?.toDouble(),
    (json['pressureGround'] as num?)?.toDouble(),
    json['humidity'] as int,
    (json['tempMin'] as num?)?.toDouble(),
    (json['tempMax'] as num?)?.toDouble(),
    json['clouds'] as int,
  );
}

// WeatherDay _$WeatherDayFromJson(Map<String, dynamic> json) {
//   return WeatherDay(
//     DateTime.parse(json['sunrise'] as String),
//     DateTime.parse(json['sunset'] as String),
//   );
// }

WeatherRain _$WeatherRainFromJson(Map<String, dynamic> json) {
  return WeatherRain(
    (json['rain1'] as num?)?.toDouble(),
    (json['rain3'] as num?)?.toDouble(),
  );
}

WeatherWind _$WeatherWindFromJson(Map<String, dynamic> json) {
  return WeatherWind(
    (json['windSpeed'] as num?)?.toDouble(),
    json['windDegree'] as int?,
  );
}
