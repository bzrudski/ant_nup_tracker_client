/*
 * flight_database.dart
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

import 'package:ant_nup_tracker/flight_list.dart';
import 'package:ant_nup_tracker/users.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart';
import 'package:tuple/tuple.dart';
import 'flights.dart';

const dbName = "flights.db";

class FlightDatabase {
  FlightDatabase._();

  static const flightTableName = "flights";
  static const flightIdColumn = "flightId";
  static const genusColumn = "genus";
  static const speciesColumn = "species";
  static const confidenceColumn = "confidence";
  static const dateOfFlightColumn = "dateOfFlight";
  static const sizeColumn = "sizeOfFlight";
  static const latitudeColumn = "latitude";
  static const longitudeColumn = "longitude";
  static const radiusColumn = "radius";
  static const dateRecordedColumn = "dateRecorded";
  static const ownerColumn = "owner";
  static const ownerRoleColumn = "ownerRole";
  static const hasWeatherColumn = "hasWeather";
  static const validatedColumn = "validated";
  static const validatedByColumn = "validatedBy";
  static const validatedAtColumn = "validatedAt";
  static const lastUpdatedColumn = "lastUpdated";

  static const createFlightsTable = """
create table if not exists $flightTableName (
  $flightIdColumn int primary key,
  $speciesColumn int not null,
  $confidenceColumn int not null CHECK($confidenceColumn = 0 OR $confidenceColumn = 1),
  $dateOfFlightColumn text not null,
  $sizeColumn int not null CHECK($sizeColumn = 0 OR $sizeColumn = 1),
  $latitudeColumn real not null,
  $longitudeColumn real not null,
  $radiusColumn real not null CHECK($radiusColumn >= 0),
  $dateRecordedColumn text not null,
  $ownerColumn text not null,
  $ownerRoleColumn int not null CHECK($ownerRoleColumn >= -1 AND $ownerRoleColumn <= 1),
  $hasWeatherColumn int not null CHECK($hasWeatherColumn = 0 OR $hasWeatherColumn = 1),
  $validatedColumn int not null CHECK($validatedColumn = 0 OR $validatedColumn = 1),
  $validatedAtColumn text,
  $validatedByColumn text,
  $lastUpdatedColumn date not null
)""";

  static const dropFlightsTable = """
  drop table $flightTableName
  """;

  static const genusTableName = "genera";
  static const genusIdColumn = "id";
  static const genusNameColumn = "name";

  static const speciesTableName = "species";
  static const speciesIdColumn = "id";
  static const speciesGenusColumn = "genus";
  static const speciesNameColumn = "name";

  static const createGenusTable = """
create table if not exists $genusTableName (
 $genusIdColumn int primary key,
 $genusNameColumn text not null
)""";

  static const createSpeciesTable = """
create table if not exists $speciesTableName (
  $speciesIdColumn int primary key,
  $speciesNameColumn text not null,
  $speciesGenusColumn int not null,
  foreign key($speciesGenusColumn) REFERENCES $genusTableName($genusIdColumn)
)""";

  static const dropGeneraTable = """
  drop table $genusTableName
  """;

  static const dropSpeciesTable = """
  drop table $speciesTableName
  """;

  static const enableForeignKey = """
PRAGMA foreign_keys = ON
""";

  static final shared = FlightDatabase._();

  Database? _db;

  bool get isInitialized => _db != null;

  Future<bool> initializeDatabase({bool clear = false}) async {
    final dbExists = await databaseExists(dbName);

    if (dbExists && clear) {
      await deleteDatabase(dbName);
    }

    _db = await openDatabase(
      dbName,
      version: 1,
      onCreate: (db, version) {
        db.execute(enableForeignKey);
        db.execute(createGenusTable);
        db.execute(createSpeciesTable);
        db.execute(createFlightsTable);
      },
    );
    //
    // if (clear){
    //   // _db!.execute(dropFlightsTable);
    //   // _db!.execute(createFlightsTable);
    // }

    return dbExists;
  }

  // Future<void> clearDatabase() async {
  //   final dbExists = await databaseExists(dbName);
  //
  //   if (!dbExists) {
  //     return;
  //   }
  //
  //   _db = await openDatabase(
  //     dbName,
  //     version: 1,
  //     onOpen: (db) {
  //
  //     }
  //   );
  //
  //   _db!.close();
  //   _db = null;
  // }

  Future<Map<int, Tuple2<Flight, DateTime>>> readFlights() async {
    final db = _db;

    if (db == null) return {};

    final flights = <int, Tuple2<Flight, DateTime>>{};

    final records = await db.query(flightTableName);

    // print("Database contains ${records.length} records");

    for (var record in records) {
      final flightId = record[flightIdColumn] as int;
      // print("Reading record $flightId from database.");
      final taxonomyId = record[speciesColumn] as int;
      final taxonomy = Species.get(taxonomyId);
      // final genusName = record[genusColumn] as String;
      // final speciesName = record[speciesColumn] as String;
      //
      // final genus = Genus.get(genusName);
      // final taxonomy = Species.get(genus, speciesName);

      final confidence = _confidenceMap.keys.firstWhere(
        (element) => _confidenceMap[element] == record[confidenceColumn] as int,
      );
      // final dateOfFlight = DateTime.parse(record[dateOfFlightColumn] as String);
      final size = _flightSizeMap.keys.firstWhere(
        (element) => _flightSizeMap[element] == record[sizeColumn] as int,
      );
      final latitude = record[latitudeColumn] as double;
      final longitude = record[longitudeColumn] as double;

      final timezone = latLngToTimezoneString(latitude, longitude);

      final location = getLocation(timezone);

      final dateOfFlight = TZDateTime.parse(location, record[dateOfFlightColumn] as String);

      final radius = record[radiusColumn] as double;
      final dateRecorded = DateTime.parse(record[dateRecordedColumn] as String);
      final owner = record[ownerColumn] as String;
      final ownerRole = _ownerRoleMap.keys.firstWhere(
        (element) => _ownerRoleMap[element] == record[ownerRoleColumn] as int,
      );
      final hasWeather = (record[hasWeatherColumn] == 1) || false;
      final validated = (record[validatedColumn] == 1) || false;
      final validatedBy = record[validatedByColumn] as String?;
      final validatedAt = record[validatedAtColumn] != null
          ? DateTime.parse(record[validatedAtColumn] as String)
          : null;

      final lastUpdated = DateTime.parse(record[lastUpdatedColumn] as String);

      flights[flightId] = Tuple2(
          Flight(
              flightId,
              taxonomy,
              confidence,
              dateOfFlight,
              size,
              latitude,
              longitude,
              radius,
              dateRecorded,
              owner,
              ownerRole,
              hasWeather,
              validated,
              // [],
              validatedBy,
              validatedAt),
          lastUpdated);
    }

    return flights;
  }

  Future<void> addFlight(Flight flight, DateTime lastUpdated) async {
    final db = _db;

    if (db == null) return;

    // print("Inserting new flight ${flight.flightID} into DB.");

    await db.insert(flightTableName, flight.toMap(lastUpdated));
  }

  Future<void> addFlights(Iterable<Tuple2<Flight, DateTime>> flights) async {
    final db = _db;

    if (db == null) return;

    final batch = db.batch();

    for (var flightRow in flights) {
      final flight = flightRow.item1;
      final lastUpdated = flightRow.item2;
      batch.insert(flightTableName, flight.toMap(lastUpdated));
    }

    await batch.commit(noResult: true);
  }

  Future<void> updateFlight(Flight flight, DateTime lastUpdated) async {
    final db = _db;
    if (db == null) return;

    await db.update(flightTableName, flight.toMap(lastUpdated),
        where: "$flightIdColumn = ?", whereArgs: [flight.flightID]);
  }

  Future<Map<int, Genus>> readGenera() async {
    final db = _db;

    if (db == null) return {};

    // final genera = <int, Genus>{};

    final genusRecords = await db.query(genusTableName);

    // final recordsAsJson = genusRecords.map((e) => jsonEncode(e));

    final generaList = Genus.loadGeneraFromJson(genusRecords);
    
    final generaEntries = generaList.map((e) => MapEntry(e.id, e));
    
    // genera.addEntries(generaEntries);

    return Map.fromEntries(generaEntries);
  }

  Future<Map<int, Species>> readSpecies() async {
    final db = _db;

    if (db == null) return {};

    // final species = <int, Species>{};

    final speciesRecords = await db.query(speciesTableName);

    // final recordsAsJson = speciesRecords.map((e) => jsonEncode(e));

    final speciesList = Species.loadSpeciesFromJson(speciesRecords);

    final speciesEntries = speciesList.map((e) => MapEntry(e.id, e));

    return Map.fromEntries(speciesEntries);

  }

  Future<void> addGenus(Genus genus) async {
    final db = _db;

    if (db == null) return;

    await db.insert(genusTableName, genus.toMap());
  }

  Future<void> addGenera(Iterable<Genus> genera) async {
    final db = _db;

    if (db == null) return;

    final batch = db.batch();

    for (var genus in genera) {
      batch.insert(genusTableName, genus.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<void> addSpecies(Species species) async {
    final db = _db;

    if (db == null) return;

    await db.insert(speciesTableName, species.toMap());
  }

  Future<void> addManySpecies(Iterable<Species> speciesList) async {
    final db = _db;

    if (db == null) return;

    final batch = db.batch();

    for (var species in speciesList) {
      batch.insert(speciesTableName, species.toMap());
    }

    await batch.commit(noResult: true);
  }
}

final _confidenceMap = {
  ConfidenceLevels.low: 0,
  ConfidenceLevels.high: 1,
};

final _flightSizeMap = {
  FlightSize.manyQueens: 0,
  FlightSize.singleQueen: 1,
};

final _ownerRoleMap = {
  Role.flagged: -1,
  Role.citizen: 0,
  Role.professional: 1,
};

extension DatabaseStorage on Flight {
  Map<String, Object?> toMap(DateTime lastUpdated) => {
        FlightDatabase.flightIdColumn: flightID,
        // FlightDatabase.genusColumn: taxonomy.genus.name,
        FlightDatabase.speciesColumn: taxonomy.id,
        FlightDatabase.confidenceColumn: _confidenceMap[confidence],
        FlightDatabase.dateOfFlightColumn: dateOfFlight.toIso8601String(),
        FlightDatabase.sizeColumn: _flightSizeMap[size],
        FlightDatabase.latitudeColumn: latitude,
        FlightDatabase.longitudeColumn: longitude,
        FlightDatabase.radiusColumn: radius,
        FlightDatabase.dateRecordedColumn: dateRecorded.toIso8601String(),
        FlightDatabase.ownerColumn: owner,
        FlightDatabase.ownerRoleColumn: _ownerRoleMap[ownerRole],
        FlightDatabase.hasWeatherColumn: hasWeather ? 1 : 0,
        FlightDatabase.validatedColumn: validated ? 1 : 0,
        FlightDatabase.validatedByColumn: validatedBy,
        FlightDatabase.validatedAtColumn: validatedAt?.toIso8601String(),
        FlightDatabase.lastUpdatedColumn: lastUpdated.toIso8601String()
      };
}

class FlightDatabaseReadResults {
  final Map<int, Flight> flights;
  final List<FlightEntry> entries;

  const FlightDatabaseReadResults(this.flights, this.entries);
}

extension DatabaseStorageGenus on Genus {
  Map<String, Object?> toMap() => {
        FlightDatabase.genusIdColumn: id,
        FlightDatabase.genusNameColumn: name,
      };
}

extension DatabaseStorageSpecies on Species {
  Map<String, Object?> toMap() => {
        FlightDatabase.speciesIdColumn: id,
        FlightDatabase.speciesNameColumn: name,
        FlightDatabase.speciesGenusColumn: genus.id,
      };
}
