/*
 * flight_detail.dart
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

import 'package:ant_nup_tracker/flight_form.dart';
import 'package:ant_nup_tracker/flights.dart';
import 'package:ant_nup_tracker/images.dart';
import 'package:ant_nup_tracker/sessions.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'exceptions.dart';

abstract class FlightDetailObserver {
  void fetchedFlightDetail(Flight flight);
  void fetchedFlightDetailWithError(LocalisableException error);
}

class FlightDetailFetcher {
  FlightDetailFetcher._();

  static final shared = FlightDetailFetcher._();

  FlightDetailObserver? _observer;
  set observer(FlightDetailObserver? o) => _observer = o;

  void fetchFlightDetailForId(int id) {
    final url = UrlManager.shared.urlForFlight(id);

    http.get(url).then((res) {
      final status = res.statusCode;

      if (status == 401) throw FailedAuthenticationException();
      if (status == 404) throw NoFlightException(id);
      if (status != 200) throw GetException(status);

      Flight flight;

      try {
        final json = jsonDecode(res.body);
        flight = Flight.fromJson(json);
      } catch (err) {
        throw JsonException();
      }

      _observer?.fetchedFlightDetail(flight);
    }).catchError((error) {
      _observer?.fetchedFlightDetailWithError(error);
    }, test: (error) => error is LocalisableException).catchError(
        (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      _observer?.fetchedFlightDetailWithError(NoResponseException());
    });
  }
}

Future<Flight> fetchFlight(int id) async {
  final url = UrlManager.shared.urlForFlight(id);

  try {
    final String? authorization;

    if (SessionManager.shared.isLoggedIn) {
      // print("SessionManager is logged in.");
      authorization = "Token ${SessionManager.shared.session!.token}";
    } else {
      // print("SessionManager is not logged in.");
      authorization = null;
    }

    final response = await http.get(url,
        headers: {if (authorization != null) "Authorization": authorization});

    final status = response.statusCode;

    if (status == 401) throw FailedAuthenticationException();
    if (status == 404) throw NoFlightException(id);
    if (status != 200) throw GetException(status);

    try {
      final json = jsonDecode(response.body);
      final flight = Flight.fromJson(json);
      // await flight.loadImages();
      return flight;
    } catch (err, stacktrace) {
      // print(err);
      // print(stacktrace);
      throw JsonException();
    }
  } on IOException catch (err) {
    // print(err);
    throw NoResponseException();
  }
}

// Future<void> addNewFlight(FlightFormData flightFormData) async {
//   final data = flightFormData.toJson();
//   final url = UrlManager.shared.listUrl;
//
//   print("Sending request: ${jsonEncode(data)}");
//
//   final response = await http.post(url, body: jsonEncode(data), headers: {
//     "Content-Type": "application/json",
//     "Authorization": "Token ${SessionManager.shared.session!.token}"
//   });
//
//   var statusCode = response.statusCode;
//
//   print(statusCode);
//   print(response.body);
//
//   if (statusCode == 401) throw FailedAuthenticationException();
//   if (statusCode != 201) throw AddFlightException(statusCode);
//
//   // if (statusCode == 201) {}
// }

Future<void> addNewFlight(
    FlightFormData flightFormData, Iterable<XFile> images) async {
  final data = flightFormData.toJson();
  final url = UrlManager.shared.filteredListUrl;

  // print("Sending request: ${jsonEncode(data)}");
  //
  final response = await http.post(url, body: jsonEncode(data), headers: {
    "Content-Type": "application/json",
    "Authorization": "Token ${SessionManager.shared.session!.token}"
  });

  var statusCode = response.statusCode;

  // print(statusCode);
  // print(response.body);

  if (statusCode == 401) throw FailedAuthenticationException();
  if (statusCode != 201) throw AddFlightException(statusCode);

  final newFlight = Flight.fromJson(jsonDecode(response.body));

  final id = newFlight.flightID;

  for (var image in images) {
    await addImageToFlight(id, image);
  }

  // if (statusCode == 201) {}
}

enum FlightUpdateMethod { content, images, all, none }

Future<void> updateFlight(int id, FlightFormData flightFormData,
    Iterable<XFile> newImages, Iterable<int> removedImages,
    [FlightUpdateMethod updateMethod = FlightUpdateMethod.all]) async {
  if (updateMethod == FlightUpdateMethod.none) {
    return;
  }

  final data = flightFormData.toJson();
  final url = UrlManager.shared.urlForFlight(id);

  if (updateMethod == FlightUpdateMethod.content ||
      updateMethod == FlightUpdateMethod.all) {
    final response = await http.put(url, body: jsonEncode(data), headers: {
      "Content-Type": "application/json",
      "Authorization": "Token ${SessionManager.shared.session!.token}"
    });

    // print(response.statusCode);
    // print(response.body);

    final statusCode = response.statusCode;

    if (statusCode == 401) throw FailedAuthenticationException();
    if (statusCode != 200) throw EditFlightException(statusCode);
  }

  if (updateMethod == FlightUpdateMethod.images ||
      updateMethod == FlightUpdateMethod.all) {
    for (var image in newImages) {
      await addImageToFlight(id, image);
    }

    for (var imageId in removedImages) {
      await deleteImage(id, imageId);
    }
  }
}

Future<void> validateFlight(int id, {required bool isValidated}) async {
  final shouldValidate = !isValidated;
  final url = UrlManager.shared.urlForValidate(id);

  var data = {
    // "flightID"  : id,
    "validate": shouldValidate,
  };

  final response = await http.post(url, body: jsonEncode(data), headers: {
    "Content-Type": "application/json",
    "Authorization": "Token ${SessionManager.shared.session!.token}"
  });

  final statusCode = response.statusCode;

  // print(statusCode);
  // print(response.body);

  if (statusCode == 404) throw NoFlightException(id);
  if (statusCode == 401) throw FailedAuthenticationException();
  if (statusCode == 403) throw InsufficientPrivilegesException();

  if (statusCode != 200) throw FlightVerificationException(statusCode);
}

Future<void> unValidateFlight(int id) async {}

Future<Iterable<Species>> loadSpeciesForGenus(Genus g) async {
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

      final species = Species.loadSpeciesFromJson(results);
      // print("Loaded species $species");
      return species;
    } catch (err, stacktrace) {
      // print(err);
      // print(stacktrace);
      throw JsonException();
    }
  } on IOException {
    throw NoResponseException();
  }
}

Future<Iterable<Genus>> loadGenera() async {
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

      return genera;
    } catch (err, stacktrace) {
      // print(err);
      // print(stacktrace);
      throw JsonException();
    }
  } on IOException {
    throw NoResponseException();
  }
}

class TaxonomyDetails {
  TaxonomyDetails({
    required this.version,
    required this.genusCount,
    required this.speciesCount,
  });

  final int version;
  final int genusCount;
  final int speciesCount;
}

Future<TaxonomyDetails> loadTaxonomyDetails() async {
  final taxonomyVersionUrl = UrlManager.shared.taxonomyVersionUrl;

  try {
    final response = await http.get(taxonomyVersionUrl);
    final status = response.statusCode;

    if (status != 200) throw ReadException(status);

    try {
      final content = jsonDecode(response.body);
      final version = content["version"] as int;
      final genusCount = content["genus_count"] as int;
      final speciesCount = content["species_count"] as int;

      return TaxonomyDetails(
        version: version,
        genusCount: genusCount,
        speciesCount: speciesCount,
      );

    } catch (err, stacktrace) {
      // print(err);
      // print(stacktrace);
      throw JsonException();
    }
  } on IOException {
    throw NoResponseException();
  }
}
