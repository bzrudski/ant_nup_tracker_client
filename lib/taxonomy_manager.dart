/*
 * taxonomy_manager.dart
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

import 'package:ant_nup_tracker/sessions.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'exceptions.dart';
import 'package:http/http.dart' as http;

import 'flights.dart';

class TaxonomyManager {
  TaxonomyManager._();

  static final shared = TaxonomyManager._();

  Map<String, List<String>> _speciesStore = {};

  bool get _isLoaded => _speciesStore.isNotEmpty;

  List<String> get genera {
    assert (_isLoaded);
    return List<String>.unmodifiable(_speciesStore.keys);
  }

  List<String> speciesForGenus(String genus) {
    assert (_isLoaded);
    assert (_speciesStore.keys.contains(genus));
    return List<String>.unmodifiable(_speciesStore[genus]!);
  }

  Future<void> loadSpeciesForGenus(Genus g) async {
    final speciesUrl = UrlManager.shared.urlForSpeciesList(g);
    final headers = SessionManager.shared.headers;

    try {
      final response = await http.get(speciesUrl, headers: headers);
      final status = response.statusCode;

      if (status == 401) throw FailedAuthenticationException();
      if (status == 404) throw GenusNotFoundException(g.id);
      if (status != 200) throw ReadException(status);

      try {
        final results = jsonDecode(response.body) as List<dynamic>;

        final species =
        Species.loadSpeciesFromJson(results);
        // print("Loaded species $species");
        return;
      } catch (err, stacktrace) {
        // print(err);
        // print(stacktrace);
        throw JsonException();
      }

    } on IOException {
      throw NoResponseException();
    }
  }

  Future<void> loadTaxonomy() async {
    final generaUrl = UrlManager.shared.generaUrl;
    final headers = SessionManager.shared.headers;

    try {
      final response = await http.get(generaUrl, headers: headers);
      final status = response.statusCode;

      if (status == 401) throw FailedAuthenticationException();
      if (status != 200) throw ReadException(status);

      try {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        final genera = Genus.loadGeneraFromJson(jsonList);

        // print("Loaded genera $genera");

        for (var genus in genera) {
          await loadSpeciesForGenus(genus);
        }
      } catch (err, stacktrace) {
        // print(err);
        // print(stacktrace);
        throw JsonException();
      }
    } on IOException {
      throw NoResponseException();
    }
  }

  Future<void> loadSpecies() async {
    final url = UrlManager.shared.loadTaxonomyUrl;

    try {
      final response = await http.get(url);
      final status = response.statusCode;

      if (status == 401) throw FailedAuthenticationException();
      if (status != 200) throw ReadException(status);

      try {
        final Map<String, dynamic> decodedDict = jsonDecode(response.body);

        final casted = decodedDict
            .map((key, value) => MapEntry(key, List<String>.from(value)));

        _speciesStore = casted;

        // print("Species store now has ${_speciesStore.keys.length} genera");
        // print(
        //     "Species store now has ${_speciesStore.values.fold(0, (int previousValue, element) => previousValue + element.length)} species");
      } catch (err, stacktrace) {
        // print(err);
        // print(stacktrace);
        throw JsonException();
      }
    } on IOException catch (err, stacktrace) {
      // print(err);
      // print(stacktrace);
      throw NoResponseException();
    }
  }

  // List<String> getGenera()
}

Future<void> main() async {
  await TaxonomyManager.shared.loadSpecies();
}
