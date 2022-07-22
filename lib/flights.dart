/*
 * flights.dart
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

import 'dart:core';
import 'package:ant_nup_tracker/flight_detail.dart';
import 'package:ant_nup_tracker/images.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

import 'exceptions.dart';
import 'flight_database.dart';
import 'users.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:timezone/timezone.dart';

part 'flights.g.dart';

abstract class Nameable {
  String get name;
}

class Genus implements Nameable {
  @override
  final String name;
  final int id;

  final Set<Species> _species = {};

  List<Species> get species => List.unmodifiable(_species);

  static List<Genus> getAll() => List.unmodifiable(_genusStore.values);

  /// Private constructor for the Genus class.
  Genus._(this.id, this.name);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    if (identical(this, other)) return true;

    return other is Genus && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  /// Flyweight store.
  static final _genusStore = <int, Genus>{};

  /// Retrieval function for genus objects.
  // static Genus get(String name) =>
  //     _genusStore.firstWhere((g) => g.name == name,
  //     orElse: (){
  //       var g = Genus._(name);
  //       _genusStore.add(g);
  //       return g;
  //     });
  // static Genus get(String name) =>
  //     _genusStore.putIfAbsent(name, () => Genus._(name));

  static Genus get(int id) => _genusStore[id]!;
  // _genusStore.putIfAbsent(id, () => Genus._(name));

  static Genus? getByName(String name) {
    if (_genusStore.values.any((element) => element.name == name)) {
      return _genusStore.values.firstWhere((element) => element.name == name);
    }

    return null;
  }

  static Iterable<Genus> loadGeneraFromJson(
          Iterable<dynamic> jsonList) =>
      jsonList.map((e) => Genus.fromJson(e));

  factory Genus.fromJson(Map<String, dynamic> json) {
    try {
      var name = json["name"] as String;
      var id = json["id"] as int;

      return Genus._(id, name);

      // return _genusStore.putIfAbsent(id, () => Genus._(id, name));

      // return get(name);
    } catch (err) {
      throw 'Invalid JSON keys.';
    }
  }

  Map<String, dynamic> toJson() => {"name": name};

  @override
  String toString() => name;
}

class Species implements Nameable {
  final int id;
  final Genus genus;
  @override
  final String name;

  Species._(this.id, this.genus, this.name) {
    genus._species.add(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    if (identical(this, other)) return true;

    return other is Species && other.genus == genus && other.name == name;
  }

  @override
  int get hashCode => genus.hashCode + name.hashCode;

  @override
  String toString() => "$genus $name";

  /// Flyweight store.
  // static final _speciesStore = <Genus, Map<String, Species>>{};

  static final _speciesStore = <int, Species>{};

  /// Retrieval function for genus objects.
  // static Species get(Genus genus, String name) => _speciesStore
  //     .putIfAbsent(genus, () => <String, Species>{})
  //     .putIfAbsent(name, () => Species._(genus, name));

  static Species get(int id) {
    // print("Species store: $_speciesStore");
    return _speciesStore[id]!;
  }
  // _speciesStore.putIfAbsent(id, () => Species._(id, genus, name));

  static Species? getByGenusAndName(Genus genus, String name) {
    final speciesList = genus.species;
    if (speciesList.any((element) => element.name == name)) {
      return speciesList.firstWhere((element) => element.name == name);
    }

    return null;
  }

  static Iterable<Species> loadSpeciesFromJson(
          Iterable<dynamic> jsonList) =>
      jsonList.map((e) => Species.fromJson(e));

  factory Species.fromJson(Map<String, dynamic> json) {
    try {
      // var rawGenus = json["genus"] as Map<String, dynamic>;
      // var genus = Genus.fromJson(rawGenus);
      final genusId = json["genus"] as int;
      final genus = Genus.get(genusId);
      final name = json["name"] as String;
      final id = json["id"] as int;
      return Species._(id, genus, name);
      // return _speciesStore.putIfAbsent(id, () => Species._(id, genus, name));
    } catch (err, stacktrace) {
      // print("Error creating species from JSON!!!!");
      // print(stacktrace);
      throw JsonException();
    }
  }

  Map<String, dynamic> toJson() => {"genus": genus.toJson(), "name": name};
}

class TaxonomyProgress {

  TaxonomyProgress._();

  static final shared = TaxonomyProgress._();

  int _totalNumberOfGenera = 0;
  int _totalNumberOfSpecies = 0;

  int get totalNumberOfGenera => _totalNumberOfGenera;
  int get totalNumberOfSpecies => _totalNumberOfSpecies;

  double? get genusProgress => _totalNumberOfGenera > 0 ? Genus._genusStore.length / _totalNumberOfGenera : null;
  double? get speciesProgress => _totalNumberOfSpecies > 0 ? Species._speciesStore.length / _totalNumberOfSpecies : null;

}

enum LoadingStage {
  initial, credentials, taxonomy, filtering, flights, done
}

class InitialLoadingProgress {

  LoadingStage loadingStage = LoadingStage.initial;

  // LoadingStage get loadingStage => _loadingStage;

  double? getProgress() {
    switch (loadingStage) {
      case LoadingStage.initial:
        return null;
      case LoadingStage.credentials:
        return null;
      case LoadingStage.taxonomy:
        return null;
        // return TaxonomyProgress.shared.speciesProgress;
      case LoadingStage.flights:
        return null;
      case LoadingStage.done:
        return null;
      case LoadingStage.filtering:
        return null;
    }
  }

  String getProgressCaption(BuildContext context) {
    switch (loadingStage){
      case LoadingStage.initial:
        return AppLocalizations.of(context)!.initialLoadingStage;
      case LoadingStage.credentials:
        return AppLocalizations.of(context)!.credentialLoadingStage;
      case LoadingStage.taxonomy:
        return AppLocalizations.of(context)!.taxonomyLoadingStage;
      case LoadingStage.flights:
        return AppLocalizations.of(context)!.flightLoadingStage;
      case LoadingStage.done:
        return AppLocalizations.of(context)!.doneLoadingStage;
      case LoadingStage.filtering:
        return AppLocalizations.of(context)!.filteringLoadingStage;
    }
  }
}

Future<Tuple2<bool, int>> isNewTaxonomyAvailable() async {
  final prefs = await SharedPreferences.getInstance();

  final version = prefs.getInt("taxonomyVersion");

  final taxonomyDetails = await loadTaxonomyDetails();

  final latestVersion = taxonomyDetails.version;

  TaxonomyProgress.shared._totalNumberOfGenera = taxonomyDetails.genusCount;
  TaxonomyProgress.shared._totalNumberOfSpecies = taxonomyDetails.speciesCount;

  if (version == null) return Tuple2(true, latestVersion);

  // print("Current taxonomy version: $version, Latest version $latestVersion");

  return Tuple2(latestVersion > version, latestVersion);
}

Future<void> loadTaxonomy() async {
  final newTaxonomyTuple = await isNewTaxonomyAvailable();
  final newTaxonomyAvailable = newTaxonomyTuple.item1;

  if (!newTaxonomyAvailable) {
    // print("No new taxonomy available...");
    if (!FlightDatabase.shared.isInitialized) {
      await FlightDatabase.shared.initializeDatabase();
    }
    await loadTaxonomyFromDatabase();

    if (Genus._genusStore.isNotEmpty && Species._speciesStore.isNotEmpty) return;
  }

  // print("Updated Taxonomy Available!");

  await FlightDatabase.shared.initializeDatabase(clear: true);
  await loadTaxonomyFromServer();
  await FlightDatabase.shared.addGenera(Genus._genusStore.values);
  await FlightDatabase.shared.addManySpecies(Species._speciesStore.values);

  final prefs = await SharedPreferences.getInstance();
  prefs.setInt("taxonomyVersion", newTaxonomyTuple.item2);
}

Future<void> loadTaxonomyFromServer() async {
  final allGenera = await loadGenera();

  final entries = allGenera.map((e) => MapEntry(e.id, e));
  Genus._genusStore.clear();
  Genus._genusStore.addEntries(entries);

  final allSpecies = <Species>[];
  for (var genus in allGenera) {
    allSpecies.addAll(await loadSpeciesForGenus(genus));
  }

  final speciesEntries = allSpecies.map((e) => MapEntry(e.id, e));
  Species._speciesStore.clear();
  Species._speciesStore.addEntries(speciesEntries);
}

Future<void> loadTaxonomyFromDatabase() async {
  Genus._genusStore.clear();
  Species._speciesStore.clear();

  final allGenera = await FlightDatabase.shared.readGenera();
  TaxonomyProgress.shared._totalNumberOfGenera = allGenera.length;
  Genus._genusStore.addAll(allGenera);

  final allSpecies = await FlightDatabase.shared.readSpecies();
  TaxonomyProgress.shared._totalNumberOfSpecies = allSpecies.length;
  Species._speciesStore.addAll(allSpecies);

}

// @JsonSerializable(explicitToJson: true)
// class BaseFlight {
//   int flightID;
//   Species taxonomy;
//   DateTime dateOfFlight;
//   double latitude;
//   double longitude;
//   DateTime lastUpdated;
//   String owner;
//   Role ownerRole;
//   bool validated;
//
//   Role get validationLevel {
//     if (ownerRole == Role.flagged) {
//       return Role.flagged;
//     } else {
//       return validated ? Role.professional : Role.citizen;
//     }
//   }
//
//   BaseFlight(
//       this.flightID,
//       this.taxonomy,
//       this.dateOfFlight,
//       this.latitude,
//       this.longitude,
//       this.lastUpdated,
//       this.owner,
//       this.ownerRole,
//       this.validated);
//
//   factory BaseFlight.fromJson(Map<String, dynamic> json) =>
//       _$BaseFlightFromJson(json);
//
//   Map<String, dynamic> toJson() => _$BaseFlightToJson(this);
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     if (other is! BaseFlight) return false;
//
//     return flightID == other.flightID &&
//         taxonomy == other.taxonomy &&
//         dateOfFlight == other.dateOfFlight &&
//         latitude == other.latitude &&
//         longitude == other.longitude &&
//         lastUpdated == other.lastUpdated &&
//         owner == other.owner &&
//         ownerRole == other.ownerRole &&
//         validated == other.validated;
//   }
//
//   @override
//   int get hashCode =>
//       flightID.hashCode +
//       taxonomy.hashCode +
//       dateOfFlight.hashCode +
//       latitude.hashCode +
//       longitude.hashCode +
//       lastUpdated.hashCode +
//       owner.hashCode +
//       ownerRole.hashCode +
//       validated.hashCode;
//
//   static const flightKeys = {
//     'flightID',
//     'taxonomy',
//     'dateOfFlight',
//     'latitude',
//     'longitude',
//     'lastUpdated',
//     'owner',
//     'ownerRole',
//     'validated'
//   };
//
//   @override
//   String toString() {
//     return "$flightID: $taxonomy flight, occurred at $dateOfFlight at location ($latitude, $longitude); recorded by $owner";
//   }
// }

enum ConfidenceLevels {
  @JsonValue(0)
  low,

  @JsonValue(1)
  high
}

// extension ConfidenceNames on ConfidenceLevels {
//
//   String confidenceName(BuildContext context) {
//     switch (this) {
//       case ConfidenceLevels.low:
//         return AppLocalizations.of(context)!.lowConfidence;
//       case ConfidenceLevels.high:
//         return AppLocalizations.of(context)!.highConfidence;
//     }
//   }
// }

enum FlightSize {
  @JsonValue(0)
  manyQueens,

  @JsonValue(1)
  singleQueen
}

@JsonSerializable(explicitToJson: true)
class Flight {
  final int flightID;
  final Species taxonomy;
  final ConfidenceLevels confidence;
  // final DateTime dateOfFlight;
  final TZDateTime dateOfFlight;

  final double latitude;
  final double longitude;

  final String owner;
  final Role ownerRole;
  final bool validated;

  Role get validationLevel {
    if (ownerRole == Role.flagged) {
      return Role.flagged;
    } else {
      return validated ? Role.professional : Role.citizen;
    }
  }

  final double radius;
  final DateTime dateRecorded;

  @JsonKey(name: "weather")
  final bool hasWeather;

  // @JsonKey(name: "image")
  // Uri? imageUrl;

  @JsonKey(ignore: true)
  late final List<FlightImage> images;

  // bool get hasImage => imageUrl != null;
  bool get hasImage => images.isNotEmpty;

  final FlightSize size;

  final String? validatedBy;
  final DateTime? validatedAt;
  // final List<Comment> comments;

  factory Flight.fromJson(Map<String, dynamic> json) {
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
  }
  // Map<String, dynamic> toJson() => _$FlightToJson(this);

  Flight(
      this.flightID,
      this.taxonomy,
      this.confidence,
      this.dateOfFlight,
      this.size,
      this.latitude,
      this.longitude,
      this.radius,
      this.dateRecorded,
      this.owner,
      this.ownerRole,
      this.hasWeather,
      // this.imageUrl,
      this.validated,
      // this.comments,
      [this.validatedBy,
      this.validatedAt]){
    loadImages();
  }

  @JsonKey(ignore: true)
  late Future<List<FlightImage>> loadImagesFuture;

  Future<void> loadImages() async {
    loadImagesFuture = fetchImagesForFlight(flightID);
    images = await loadImagesFuture;
  }
}

String stringFromCoordinates(
    {required double latitude, required double longitude, int precision = 3}) {
  final truncatedLat = latitude.abs().toStringAsFixed(precision);
  final truncatedLong = longitude.abs().toStringAsFixed(precision);

  final directionLat = latitude >= 0 ? "N" : "S";
  final directionLong = longitude >= 0 ? "E" : "W";

  return "($truncatedLat\u{00b0}$directionLat, $truncatedLong\u{00b0}$directionLong)";
}

String stringFromLocation({required LatLng location, int precision = 3}) =>
    stringFromCoordinates(
      latitude: location.latitude,
      longitude: location.longitude,
      precision: precision,
    );

// String getConfidenceString(ConfidenceLevels level, BuildContext context) {
//   switch (level) {
//     case ConfidenceLevels.low:
//       return AppLocalizations.of(context)!.lowConfidence;
//     case ConfidenceLevels.high:
//       return AppLocalizations.of(context)!.highConfidence;
//   }
// }
//
// String getSizeString(FlightSize size, BuildContext context) {
//   switch (size) {
//     case FlightSize.manyQueens:
//       return AppLocalizations.of(context)!.manyQueens;
//     case FlightSize.singleQueen:
//       return AppLocalizations.of(context)!.singleQueen;
//   }
// }

// void main(){
//   const jsonRaw = """
// {
//     "flightID": 19,
//     "taxonomy": {
//         "genus": {
//             "name": "Pheidole"
//         },
//         "name": "dentata"
//     },
//     "latitude": 37.33233141,
//     "longitude": -122.0312186,
//     "radius": 0.0,
//     "dateOfFlight": "2020-06-10T16:18:43",
//     "owner": "messor_rogers",
//     "ownerRole": 0,
//     "ownerProfessional": false,
//     "ownerFlagged": false,
//     "dateRecorded": "2020-06-10T16:18:43",
//     "weather": true,
//     "comments": [
//         {
//             "flight": 19,
//             "author": "dentata408",
//             "role": 1,
//             "text": "Test comment",
//             "time": "2020-06-10T21:26:07"
//         },
//         {
//             "flight": 19,
//             "author": "dentata408",
//             "role": 1,
//             "text": "Comment goes here...",
//             "time": "2020-06-10T21:27:35"
//         },
//         {
//             "flight": 19,
//             "author": "dentata408",
//             "role": 1,
//             "text": "Another comment here",
//             "time": "2020-06-10T21:32:09"
//         },
//         {
//             "flight": 19,
//             "author": "dentata408",
//             "role": 1,
//             "text": "Another comment",
//             "time": "2020-06-10T21:37:37"
//         },
//         {
//             "flight": 19,
//             "author": "dentata408",
//             "role": 1,
//             "text": "More comments",
//             "time": "2020-06-10T21:38:36"
//         },
//         {
//             "flight": 19,
//             "author": "dentata408",
//             "role": 1,
//             "text": "Commenty comments",
//             "time": "2020-06-10T21:39:03"
//         }
//     ],
//     "image": null,
//     "confidence": 0,
//     "size": 0,
//     "validated": true,
//     "validatedBy": "dentata408",
//     "validatedAt": "2020-06-10T21:25:48"
// }""";
//      final json = jsonDecode(jsonRaw);
//      var f = Flight.fromJson(json);
//      print("We have created flight $f");
//      print("This flight has species: ${f.taxonomy}");
//      print("This flight has ${f.comments.length} comments, which read:");
//      f.comments.forEach((comment) => print(comment.text));
// }

class SpeciesManager {

  final Map<int, Genus> _genera = {};
  final Map<int, Species> _species = {};

  Map<int, Genus> get genera => Map.unmodifiable(_genera);
  Map<int, Species> get species => Map.unmodifiable(_species);

  Future<void> loadTaxonomy() async {
    final allGenera = await loadGenera();

    final entries = allGenera.map((e) => MapEntry(e.id, e));
    _genera.clear();
    _genera.addEntries(entries);

    final allSpecies = <Species>[];
    for (var genus in allGenera) {
      allSpecies.addAll(await loadSpeciesForGenus(genus));
    }

    final speciesEntries = allSpecies.map((e) => MapEntry(e.id, e));
    _species.clear();
    _species.addEntries(speciesEntries);
  }

}
