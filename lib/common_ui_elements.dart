/*
 * common_ui_elements.dart
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

import 'package:flutter/material.dart';

class HeaderRow extends StatelessWidget {
  const HeaderRow({required this.label, this.headerStyle, Key? key}) : super(key: key);

  final TextStyle? headerStyle;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textStyle = headerStyle ?? Theme.of(context).textTheme.headline6;

    return Column(
      children: [
        const Divider(
          thickness: 1,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: textStyle)),
            ],
          ),
        ),
        const Divider(
          thickness: 1,
        )
      ],
    );
  }
}