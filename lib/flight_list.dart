/*
 * flight_list.dart
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

import 'package:ant_nup_tracker/flight_detail.dart';
import 'package:ant_nup_tracker/flights.dart';
import 'package:ant_nup_tracker/sessions.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import 'exceptions.dart';
import 'flight_database.dart';
part 'flight_list.g.dart';

// @JsonSerializable(explicitToJson: true)
// class Frame<T> {
//   final int count;
//   final Uri? next;
//   final Uri? previous;
//   @_Converter()
//   final List<T> results;
//
//   Frame(this.count, this.next, this.previous, this.results);
//
//   factory Frame.fromJson(Map<String, dynamic> json) => _$FrameFromJson(json);
//
//   Map<String, dynamic> toJson() => _$FrameToJson(this);
// }
//
// class _Converter<T> implements JsonConverter<T, Object?> {
//   const _Converter();
//
//   @override
//   T fromJson(Object? json) {
//     // print("Now decoding: $json");
//     if (json is Map<String, dynamic>) {
//       if (json.keys.toSet().difference(BaseFlight.flightKeys).isEmpty) {
//         return BaseFlight.fromJson(json) as T;
//       }
//     }
//     return json! as T;
//   }
//
//   @override
//   Object? toJson(T object) {
//     return object;
//   }
// }

class FlightEntry {
  final int flightID;
  final DateTime lastUpdated;

  const FlightEntry(this.flightID, this.lastUpdated);

  factory FlightEntry.fromJson(Map<String, dynamic> json) {
    final flightID = json["flightID"] as int;
    final lastUpdated = DateTime.parse(json["lastUpdated"] as String);

    return FlightEntry(flightID, lastUpdated);
  }
}

class FlightStore {
  var _flightEntries = <FlightEntry>[];
  final _flights = <int, Tuple2<Flight, DateTime>>{};

  final _mainFlightList = <Flight>[];

  FlightStore._();

  static final shared = FlightStore._();

  // int _loadedFromTop = 0;
  //
  // int get loadedFromTop => _loadedFromTop;
  int get totalCount => _flightEntries.length;
  int get loadedFlightCount => _mainFlightList.length;

  bool _isReading = false;
  bool get isReading => _isReading;

  // bool get canRead => _loadedFromTop < _flightEntries.length;

  // bool canRead(int numberRead) => numberRead < _flightEntries.length;

  bool get canRead => _mainFlightList.length < _flightEntries.length;

  Future<int> load({int n = 15, bool useDatabase = true}) async {
    _flightEntries = await fetchFlightEntries();
    // print("Loaded ${_flightEntries.length} flight entries");
    if (useDatabase) {

      if (!FlightDatabase.shared.isInitialized) {
        await FlightDatabase.shared.initializeDatabase();
      }

      _flights.addAll(await FlightDatabase.shared.readFlights());
    }
    final newFlightCount = await getTopFlights(n);

    // _loadedFromTop += newFlights.length;

    return newFlightCount;
  }

  bool flightIsLoaded(int id) {
    return _flights.containsKey(id);
  }

  bool flightIsOutdated(int id) {
    if (!flightIsLoaded(id)) return true;

    final timeLastRead = _flights[id]!.item2;
    final timeLastUpdated = _flightEntries
        .firstWhere((element) => element.flightID == id)
        .lastUpdated;

    return timeLastRead.isBefore(timeLastUpdated);
  }

  Future<void> _readFlight({required int id, required bool updatingFlight}) async {
    final flight = await fetchFlight(id);

    // print("Reading flight $id from web!");

    var lastUpdated = DateTime.now().toUtc();
    _flights[id] = Tuple2(flight, lastUpdated);

    if (updatingFlight) {
      await FlightDatabase.shared.updateFlight(flight, lastUpdated);
    } else {
      await FlightDatabase.shared.addFlight(flight, lastUpdated);
    }
  }

  Future<Flight> getFlight(int id, {bool forceReload = false}) async {
    var isFlightLoaded = flightIsLoaded(id);
    if (forceReload || !isFlightLoaded || flightIsOutdated(id)) {
      await _readFlight(id: id, updatingFlight: isFlightLoaded);
    }

    return _flights[id]!.item1;
  }

  Future<void> loadFlightList() async {
    _flightEntries = await fetchFlightEntries();
  }

  int getIdForIndex(int i) => _flightEntries[i].flightID;

  Future<int> getTopFlights([int n = 15]) async {
    _isReading = true;
    // final flights = <Flight>[];

    _mainFlightList.clear();

    final flightIds =
        _flightEntries.take(n).map((e) => e.flightID).toList(growable: false);

    for (var id in flightIds) {
      var flight = await getFlight(id);
      // await flight.loadImages();
      _mainFlightList.add(flight);
    }

    _isReading = false;

    // print(
    //     "Top flights have the indices ${_mainFlightList.map((e) => e.flightID)}");

    // return flights;

    return _mainFlightList.length;
  }

  Future<int> getNextFlights({
    // required int startingId,
    int count = 15,
  }) async {
    _isReading = true;

    final lastFlightId = _mainFlightList.last.flightID;

    // final flights = <Flight>[];

    final flightIds = List.of(_flightEntries)
        .skipWhile((e) => e.flightID != lastFlightId)
        .skip(1)
        .take(count)
        .map((e) => e.flightID);

    // print("Loaded new ids: $flightIds");

    for (var id in flightIds) {
      _mainFlightList.add(await getFlight(id));
    }

    // _loadedFromTop += flights.length;

    _isReading = false;

    // return flights;
    var flightCount = flightIds.length;
    // print("Loaded $flightCount more flights with ids $flightIds");
    return flightCount;
  }

  // Future<Flight> getFlightForIndex(int i) async {
  //   final id = getIdForIndex(i);
  //   return await getFlight(id);
  // }

  Flight getFlightAtIndex(int i) => _mainFlightList[i];

  Future<List<int>> updateFlights({int? n}) async {
    // final newFlights = LinkedHashMap<int, FlightChange>();
    final newFlights = <int>[];
    // final downloadLimitPosition = n ?? loadedFlightCount;//loadedFromTop;

    final newFlightEntries = await fetchFlightEntries();

    final newIds = newFlightEntries.toList();
    newIds.retainWhere((element) =>
        !_flightEntries.any((entry) => entry.flightID == element.flightID));

    final updatedIds = newFlightEntries.toList();
    updatedIds
      ..retainWhere((element) =>
          _flightEntries.any((entry) => entry.flightID == element.flightID))
      ..retainWhere((element) => element.lastUpdated.isAfter(_flightEntries
          .firstWhere((entry) => entry.flightID == element.flightID)
          .lastUpdated));

    final updatedIdsIndexed = updatedIds
        .map((e) => Tuple2(
            newFlightEntries
                .indexWhere((element) => element.flightID == e.flightID),
            e.flightID))
        .toList(growable: false);

    updatedIdsIndexed.sort((e1, e2) => e1.item1.compareTo(e2.item1));

    final newIdIndexed = newIds
        .map((e) => Tuple2(
            newFlightEntries
                .indexWhere((element) => element.flightID == e.flightID),
            e.flightID))
        .toList(growable: false);

    newIdIndexed.sort((e1, e2) => e1.item1.compareTo(e2.item1));

    for (var entry in updatedIdsIndexed) {
      final id = entry.item2;
      if (flightIsLoaded(id)) {
        // _flights[id] = await fetchFlight(id);
        final newFlight = await getFlight(id);

        final index = entry.item1;
        _mainFlightList[index] = newFlight;
        // newFlights[index] = FlightChange.update;
      }
    }

    for (var pair in newIdIndexed) {
      final index = pair.item1;

      // if (index > downloadLimitPosition) {
      //   break;
      // }

      final id = pair.item2;

      final newFlight = await getFlight(id);

      _mainFlightList.insert(index, newFlight);

      newFlights.add(index);

      // newFlights[index] = FlightChange.inserted;
    }

    _flightEntries = newFlightEntries;

    return newFlights;
  }
}

enum FlightChange { update, inserted }

Future<List<FlightEntry>> fetchFlightEntries() async {
  final url = UrlManager.shared.filteredListUrl;

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

  final statusCode = response.statusCode;

  if (statusCode == 401) throw FailedAuthenticationException();
  if (statusCode != 200) throw ReadException(statusCode);

  try {
    final List<dynamic> results = jsonDecode(response.body) as List<dynamic>;

    final List<FlightEntry> flightEntries =
        results.map((e) => FlightEntry.fromJson(e)).toList();

    return flightEntries;
  } catch (exception, stacktrace) {
    // print(exception);
    // print(stacktrace);
    throw JsonException();
  }
}

// void main() {
  // final dummy = DummyObserver();
  // FlightList.shared.setReadObserver(dummy);
  // FlightList.shared.read();
  // FlightList.shared.readNext();
  // FlightList.shared.printFlights();
  // var url = Uri.parse("url_goes_here");
  // var response = await http.get(url);
  // print("Received response: ${response.body}");
  // print("Response has code: ${response.statusCode}");
  //
  // var responseJson = jsonDecode(response.body);
  //
  // print("Response as JSON: $responseJson");
  //
  // Frame<BaseFlight> frame = Frame<BaseFlight>.fromJson(responseJson);
  // var flights = frame.results;
  //
  // // var flightsRaw = responseJson["results"] as List<dynamic>;
  // // var flights = flightsRaw.map((f) => BaseFlight.fromJson(f));
  //
  // for (final flight in flights) {
  //   print("We have a flight: $flight");
  //   print(jsonEncode(flight));
  // }
  //
  // print("Previous url: ${frame.previous}");
  // print("Next url: ${frame.next}");
  // print("Total count: ${frame.count}");
  //
  // print("Running on ${Platform.operatingSystem}");
// }
