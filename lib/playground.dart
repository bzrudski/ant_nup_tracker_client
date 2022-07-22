/*
 * playground.dart
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

// import 'dart:convert';
// import 'flights.dart';
// import 'users.dart';
//
// void testTaxonomy(){
//   print("Hello, World!");
//
//   var x = Genus.get("Pheidole");
//   var xJson = jsonEncode(x);
//
//   print(xJson);
//
//   var y = Species.get(x, "dentata");
//   var yJson = jsonEncode(y);
//
//   print(yJson);
//
//   var jParse = jsonDecode(xJson);
//   var kParse = jsonDecode(yJson);
//
//   var j = Genus.fromJson(jParse);
//   var k = Species.fromJson(kParse);
//
//   print(j);
//   print(k);
//
//   var future = DateTime(2021, 5, 14, 15, 23, 00, 00, 00);
//   var now = DateTime.now();
//
//   var f = BaseFlight(12, y, now, -35.1, 13.4, future, "dentata408", Role.flagged, true);
//
//   var fJson = jsonEncode(f);
//   print(fJson);
//   print("Flight is valid: ${f.validationLevel}");
// }

import 'package:flutter/foundation.dart';

var a = 0;

Future<int> futureTest() async {
  return Future.delayed(const Duration(seconds: 2), (){
    a++;

    if ((a-1).isOdd) {
      throw 'a was odd!';
    } else {
      return a;
    }
  });
}

Future<void> numberPrinter() async {
  int b = await futureTest();
  if (kDebugMode) {
    print(b);
  }
}

Future<void> main() async {
  for (var i=0; i<10; i++) {
    try {
      await numberPrinter();
      if (kDebugMode) {
        print("No exception occurred! 🎉🎉🎉🎉🎉");
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}