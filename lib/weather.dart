/*
 * weather.dart
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
import 'package:ant_nup_tracker/sessions.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';

part 'weather.g.dart';

abstract class ConvertibleToWeatherSection {
  WeatherSection toWeatherSection(BuildContext context);
}

@JsonSerializable(explicitToJson: true, createToJson: false)
class Weather {
  final int flightID;
  final WeatherDescription description;
  final WeatherBasic weather;
  final WeatherDay day;
  final WeatherRain? rain;
  final WeatherWind? wind;
  final DateTime timeFetched;

  const Weather(this.flightID, this.description, this.weather, this.day,
      this.rain, this.wind, this.timeFetched);

  factory Weather.fromJson(Map<String, dynamic> json, {required double latitude, required double longitude}) {

    final timezone = latLngToTimezoneString(latitude, longitude);
    final location = getLocation(timezone);

    return Weather(
      json['flightID'] as int,
      WeatherDescription.fromJson(json['description'] as Map<String, dynamic>),
      WeatherBasic.fromJson(json['weather'] as Map<String, dynamic>),
      WeatherDay.fromJson(json['day'] as Map<String, dynamic>, latitude: latitude, longitude: longitude),
      json['rain'] == null
          ? null
          : WeatherRain.fromJson(json['rain'] as Map<String, dynamic>),
      json['wind'] == null
          ? null
          : WeatherWind.fromJson(json['wind'] as Map<String, dynamic>),
      TZDateTime.parse(location, json['timeFetched'] as String),
    );
  }

  WeatherSection _createTimeFetchedSection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    final locale = appLocalization.localeName;

    final rows = <WeatherRow>[
      WeatherRow(appLocalization.weatherTimeFetchedLabel,
          DateFormat.yMMMd(locale).add_jm().format(timeFetched))
    ];

    return WeatherSection(appLocalization.weatherTimeFetchedHeader, rows);
  }

  List<WeatherSection> toWeatherSectionList(BuildContext context) {
    return <WeatherSection>[
      description.toWeatherSection(context),
      weather.toWeatherSection(context),
      day.toWeatherSection(context),
      if (rain != null) rain!.toWeatherSection(context),
      if (wind != null) wind!.toWeatherSection(context),
      _createTimeFetchedSection(context)
    ];
  }
}

@JsonSerializable(createToJson: false)
class WeatherDescription implements ConvertibleToWeatherSection {
  @JsonKey(name: "desc")
  final String description;

  @JsonKey(name: "longDesc")
  final String longDescription;

  const WeatherDescription(this.description, this.longDescription);

  factory WeatherDescription.fromJson(Map<String, dynamic> json) =>
      _$WeatherDescriptionFromJson(json);

  @override
  WeatherSection toWeatherSection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    final rows = [
      WeatherRow(appLocalization.weatherDescriptionLabel, description),
      WeatherRow(appLocalization.weatherLongDescriptionLabel,
          longDescription.sentenceCase),
    ];

    return WeatherSection(appLocalization.weatherDescriptionHeader, rows);
  }
}

@JsonSerializable(createToJson: false)
class WeatherBasic implements ConvertibleToWeatherSection {
  final double temperature;
  final double pressure;
  final double? pressureSea;
  final double? pressureGround;
  final int humidity;

  @JsonKey(name: "tempMin")
  final double? minTemperature;

  @JsonKey(name: "tempMax")
  final double? maxTemperature;
  final int clouds;

  const WeatherBasic(
    this.temperature,
    this.pressure,
    this.pressureSea,
    this.pressureGround,
    this.humidity,
    this.minTemperature,
    this.maxTemperature,
    this.clouds,
  );

  factory WeatherBasic.fromJson(Map<String, dynamic> json) =>
      _$WeatherBasicFromJson(json);

  @override
  WeatherSection toWeatherSection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    final rows = [
      WeatherRow(appLocalization.weatherTemperatureLabel,
          appLocalization.degreesCelsius(temperature)),
      WeatherRow(appLocalization.weatherPressureLabel,
          appLocalization.hPaPressure(pressure)),
      if (pressureSea != null)
        WeatherRow(appLocalization.weatherSeaPressureLabel,
            appLocalization.hPaPressure(pressureSea!)),
      if (pressureGround != null)
        WeatherRow(appLocalization.weatherGroundPressureLabel,
            appLocalization.hPaPressure(pressureGround!)),
      WeatherRow(appLocalization.weatherHumidityLabel,
          appLocalization.percent(humidity)),
      WeatherRow(
          appLocalization.weatherCloudsLabel, appLocalization.percent(clouds)),
      if (maxTemperature != null)
        WeatherRow(appLocalization.weatherMaxTemperatureLabel,
            appLocalization.degreesCelsius(maxTemperature!)),
      if (minTemperature != null)
        WeatherRow(appLocalization.weatherMinTemperatureLabel,
            appLocalization.degreesCelsius(minTemperature!)),
    ];

    return WeatherSection(appLocalization.weatherBasicDescriptionHeader, rows);
  }
}

@JsonSerializable(createToJson: false)
class WeatherDay implements ConvertibleToWeatherSection {
  final DateTime sunrise;
  final DateTime sunset;

  const WeatherDay(this.sunrise, this.sunset);

  factory WeatherDay.fromJson(Map<String, dynamic> json, {required double latitude, required double longitude}) {
    final timezone = latLngToTimezoneString(latitude, longitude);
    final location = getLocation(timezone);

    return WeatherDay(
      TZDateTime.parse(location, json['sunrise'] as String),
      TZDateTime.parse(location, json['sunset'] as String),
    );
  }

  @override
  WeatherSection toWeatherSection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    final locale = appLocalization.localeName;

    final rows = [
      WeatherRow(appLocalization.sunriseLabel,
          DateFormat.jm(locale).add_yMMMd().format(sunrise)),
      WeatherRow(appLocalization.sunsetLabel,
          DateFormat.jm(locale).add_yMMMd().format(sunset)),
    ];

    return WeatherSection(appLocalization.weatherDayHeader, rows);
  }
}

@JsonSerializable(createToJson: false)
class WeatherRain implements ConvertibleToWeatherSection {
  @JsonKey(name: "rain1")
  final double? rainOneHour;

  @JsonKey(name: "rain3")
  final double? rainThreeHours;

  const WeatherRain(this.rainOneHour, this.rainThreeHours);

  factory WeatherRain.fromJson(Map<String, dynamic> json) =>
      _$WeatherRainFromJson(json);

  @override
  WeatherSection toWeatherSection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;

    final rows = [
      if (rainOneHour != null)
        WeatherRow(appLocalization.weatherRainOneHourLabel,
            appLocalization.millimetres(rainOneHour!)),
      if (rainThreeHours != null)
        WeatherRow(appLocalization.weatherRainThreeHoursLabel,
            appLocalization.millimetres(rainThreeHours!)),
    ];

    return WeatherSection(appLocalization.weatherRainHeader, rows);
  }
}

@JsonSerializable(createToJson: false)
class WeatherWind implements ConvertibleToWeatherSection {
  final double? windSpeed;

  @JsonKey(name: "windDegree")
  final int? windDirection;

  const WeatherWind(this.windSpeed, this.windDirection);

  factory WeatherWind.fromJson(Map<String, dynamic> json) =>
      _$WeatherWindFromJson(json);

  @override
  WeatherSection toWeatherSection(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    final rows = <WeatherRow>[
      if (windSpeed != null)
        WeatherRow(
          appLocalization.windSpeedLabel,
          appLocalization.windSpeedDetail(windSpeed!),
        ),
      if (windDirection != null)
        WeatherRow(
          appLocalization.windDirectionLabel,
          appLocalization.windDirectionDetail(windDirection!),
        )
    ];

    return WeatherSection(appLocalization.weatherWindSectionHeader, rows);
  }
}

Future<Weather> fetchWeather(int id, {required double latitude, required double longitude}) async {
  if (id < 0) throw InvalidIdException();

  final weatherUrl = UrlManager.shared.urlForWeather(id);

  try {
    final response = await http.get(weatherUrl, headers: SessionManager.shared.headers);
    final status = response.statusCode;

    if (status == 401) throw FailedAuthenticationException();
    if (status == 404) throw NoWeatherException(id);

    if (status != 200) throw ReadException(status);

    try {
      return Weather.fromJson(jsonDecode(response.body), latitude: latitude, longitude: longitude);
    } catch (err, stacktrace) {
      // print(err);
      // print(stacktrace);
      throw JsonException();
    }
  } on IOException {
    throw NoResponseException();
  }
}

class WeatherRow {
  final String header;
  final String detail;

  const WeatherRow(this.header, this.detail);
}

class WeatherSection {
  final String header;
  final List<WeatherRow> rows;

  const WeatherSection(this.header, this.rows);
}
