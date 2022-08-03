/*
 * weather_detail_screen.dart
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

import 'package:ant_nup_tracker/dark_mode_theme_ext.dart';
import 'package:ant_nup_tracker/detail_screen.dart';
import 'package:ant_nup_tracker/launch_url.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'common_ui_elements.dart';
import 'flights.dart';
import 'weather.dart';

class WeatherDetailScreen extends DetailScreen<int, Weather> {
  const WeatherDetailScreen(int id,
      {required this.flight, Weather? initialValue, Key? key})
      : super(id, initialValue: initialValue, key: key);

  final Flight flight;

  @override
  _WeatherDetailScreenState createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends DetailScreenState<int, Weather> {
  _WeatherDetailScreenState() : super();

  late TextStyle _labelStyle;
  late TextStyle _headerStyle;
  late TextStyle _textStyle;
  final _widgets = <Widget>[];

  @override
  Widget buildDetailScreen(Weather weather) {
    // final appLocalization = AppLocalizations.of(context)!;
    final weatherSections = weather.toWeatherSectionList(context);
    final weatherWidgets = weatherSections.map((section) {
      final rowsForSection = <Widget>[];
      rowsForSection.add(HeaderRow(label: section.header));
      rowsForSection.addAll(section.rows.map((row) =>
          _buildTextLabelDetailRow(label: row.header, detail: row.detail)));
      return rowsForSection;
    });

    _widgets.clear();

    for (final section in weatherWidgets) {
      _widgets.addAll(section);
    }

    _widgets.add(_buildCreditRow(
        label: AppLocalizations.of(context)!.creditsToOpenWeatherMap));

    // return Text(
    //   "Weather Goes Here",
    //   style: Theme.of(context).textTheme.headline2,
    // );
    return ListView.builder(
      itemBuilder: (_, i) => _widgets[i],
      itemCount: _widgets.length,
      padding: const EdgeInsets.all(8.0),
    );
  }

  @override
  String get appBarHeader {
    final appLocalization = AppLocalizations.of(context)!;
    return appLocalization.flightWeatherAppBarHeader(id);
  }

  @override
  void loadDetailFuture(int id, {bool forceReload = false}) {
    setState(() {
      detailFuture = fetchWeather(
        id,
        latitude: (widget as WeatherDetailScreen).flight.latitude,
        longitude: (widget as WeatherDetailScreen).flight.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);
    _headerStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontWeightDelta: 2);
    _textStyle = _labelStyle.apply(fontWeightDelta: 2);
    return super.build(context);
  }

  // Widget _buildHeaderRow({required String label}) {
  //   return Column(
  //     children: [
  //       const Divider(
  //         thickness: 2,
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.only(top: 8.0),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(child: Text(label, style: _headerStyle)),
  //           ],
  //         ),
  //       ),
  //       const Divider(
  //         thickness: 2,
  //       )
  //     ],
  //   );
  // }

  Widget _buildTextLabelDetailRow({
    required String label,
    required String detail,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: _labelStyle)),
          Expanded(
              child: Text(
            detail,
            style: _textStyle,
            textAlign: TextAlign.end,
          )),
        ],
      ),
    );
  }

  Widget _buildCreditRow({required String label}) {
    return Column(
      children: [
        const Divider(
          thickness: 2,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 2,
        ),
        const Image(
          image: AssetImage("assets/proprietary/openweather/openweather.png"),
          color: Colors.black87,
          colorBlendMode: BlendMode.screen,
          height: 200,
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.moreAboutOpenWeather),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => launchUrl(UrlManager.shared.openWeatherUrl),
        )
      ],
    );
  }
}
