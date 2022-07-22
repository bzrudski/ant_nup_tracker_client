/*
 * filtering.dart
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

import 'package:ant_nup_tracker/common_ui_elements.dart';
import 'package:ant_nup_tracker/location_picker.dart';
import 'package:ant_nup_tracker/users.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'flights.dart';

enum ListOrdering {
  flightId,
  dateOfFlight,
  dateRecorded,
  // lastUpdated,
  location
}

final _orderingEnumMap = {
  ListOrdering.flightId: 0,
  ListOrdering.dateOfFlight: 1,
  ListOrdering.dateRecorded: 2,
  ListOrdering.location: 3
};

enum SortingDirection { ascending, descending }

final _sortingDirectionEnumMap = {
  SortingDirection.ascending: 1,
  SortingDirection.descending: -1
};

abstract class ListFilter {
  // String get urlString;
  Map<String, String> get queryParameters;
  Map<String, dynamic> toJson();
}

// class TaxonomyFilter implements ListFilter {
//   const TaxonomyFilter(this._genus, [this._species]);
//
//   final String _genus;
//   final String? _species;
//
//   @override
//   Map<String, String> get queryParameters =>
//       {"genus": _genus, if (_species != null) "species": _species!};
// }

class TaxonomyFilter implements ListFilter {
  TaxonomyFilter(
      {Iterable<Genus> genera = const [],
      Iterable<Species> species = const []}) {
    _genera.addAll(genera);
    _species.addAll(species);
  }

  // TaxonomyFilter.fromStrings(
  //     Iterable<String> genera, Iterable<Tuple2<String, String>> species) {
  //   for (var genus in genera) {
  //     _genera.add(Genus.get(genus));
  //   }
  //
  //   for (var taxonomy in species) {
  //     final genusName = taxonomy.item1;
  //     final speciesName = taxonomy.item2;
  //
  //     final genus = Genus.get(genusName);
  //     final speciesObject = Species.get(genus, speciesName);
  //
  //     _species.add(speciesObject);
  //   }
  // }

  final _genera = <Genus>[];
  final _species = <Species>[];

  List<Genus> get genera => List.unmodifiable(_genera);
  List<Species> get species => List.unmodifiable(_species);

  String _generateTaxonomyString() => _genera
      .map((e) => e.toString())
      .followedBy(_species.map((e) => e.toString()))
      .join(",");

  @override
  Map<String, String> get queryParameters =>
      {"taxonomy": _generateTaxonomyString()};

  @override
  bool operator ==(Object other) {
    if (other is! TaxonomyFilter) return false;
    if (identical(this, other)) return true;

    const genusListEquality = ListEquality<Genus>();
    const speciesListEquality = ListEquality<Species>();

    return genusListEquality.equals(_genera, other._genera) &&
        speciesListEquality.equals(_species, other._species);
  }

  @override
  int get hashCode =>
      genera.fold<int>(
          0, (previousValue, element) => previousValue + element.hashCode) +
      species.fold<int>(
          0, (previousValue, element) => previousValue + element.hashCode);

  @override
  Map<String, dynamic> toJson() {
    return {
      'genera': _genera.map((e) => e.id).toList(growable: false),
      'species': _species.map((e) => e.id).toList(growable: false)
    };
  }

  factory TaxonomyFilter.fromJson(Map<String, dynamic> json) {
    final genusIds = json['genera'] as List<dynamic>;
    final speciesIds = json['species'] as List<dynamic>;

    final genera = genusIds.map((e) => Genus.get(e as int));
    final species = speciesIds.map((e) => Species.get(e as int));

    return TaxonomyFilter(genera: genera, species: species);
  }
}

class DateFilter implements ListFilter {
  DateFilter([this.maxDate, this.minDate]);

  final DateTime? maxDate;
  final DateTime? minDate;

  final _dateFormatter = DateFormat("y-M-d");

  @override
  Map<String, String> get queryParameters => {
        if (maxDate != null) "max_date": _dateFormatter.format(maxDate!),
        if (minDate != null) "min_date": _dateFormatter.format(minDate!),
      };

  @override
  bool operator ==(Object other) {
    if (other is! DateFilter) return false;
    if (identical(this, other)) return true;

    return maxDate == other.maxDate && minDate == other.minDate;
  }

  @override
  int get hashCode => maxDate.hashCode + minDate.hashCode;

  @override
  Map<String, dynamic> toJson() {
    return {
      'maxDate': maxDate?.toIso8601String(),
      'minDate': minDate?.toIso8601String()
    };
  }

  factory DateFilter.fromJson(Map<String, dynamic> json) {
    final maxDateString = json['maxDate'] as String?;
    final minDateString = json['minDate'] as String?;

    final maxDate =
        maxDateString != null ? DateTime.parse(maxDateString) : null;
    final minDate =
        minDateString != null ? DateTime.parse(minDateString) : null;

    return DateFilter(maxDate, minDate);
  }
}

class LocationFilter implements ListFilter {
  const LocationFilter(this.location);

  final LatLng location;

  @override
  Map<String, String> get queryParameters =>
      {"loc": "${location.latitude},${location.longitude}"};

  @override
  bool operator ==(Object other) {
    if (other is! LocationFilter) return false;
    if (identical(this, other)) return true;

    return other.location == location;
  }

  @override
  int get hashCode => location.hashCode;

  @override
  Map<String, dynamic> toJson() {
    return {'location': location.toJson()};
  }

  factory LocationFilter.fromJson(Map<String, dynamic> json) {
    final locationString = json['location'];
    final location = LatLng.fromJson(locationString)!;

    return LocationFilter(location);
  }
}

class ImageFilter implements ListFilter {
  const ImageFilter(this.hasImages);

  final bool hasImages;

  @override
  Map<String, String> get queryParameters =>
      {"has_images": hasImages.toString()};

  @override
  bool operator ==(Object other) {
    if (other is! ImageFilter) return false;
    if (identical(this, other)) return true;

    return other.hasImages == hasImages;
  }

  @override
  int get hashCode => hasImages.hashCode;

  @override
  Map<String, dynamic> toJson() {
    return {'hasImages': hasImages};
  }

  factory ImageFilter.fromJson(Map<String, dynamic> json) {
    final hasImages = json['hasImages'] as bool;

    return ImageFilter(hasImages);
  }
}

class VerificationFilter implements ListFilter {
  const VerificationFilter(this.verified, this.userRole);

  final bool? verified;
  final Role? userRole;

  @override
  Map<String, String> get queryParameters => {
        if (verified != null) "verified": verified!.toString(),
        if (userRole != null)
          "user_role":
              userRole == Role.professional ? "professional" : "enthusiast"
      };

  @override
  bool operator ==(Object other) {
    if (other is! VerificationFilter) return false;
    if (identical(this, other)) return true;

    return (verified == other.verified && userRole == other.userRole);
  }

  static final _roleEnumMap = {
    Role.citizen: 0,
    Role.professional: 1,
    Role.flagged: -1
  };

  @override
  Map<String, dynamic> toJson() {
    return {
      'verified': verified,
      'userRole': userRole != null ? _roleEnumMap[userRole] : null
    };
  }

  factory VerificationFilter.fromJson(Map<String, dynamic> json) {
    final verified = json['verified'] as bool?;
    final userRoleInt = json['userRole'] as int?;

    final Role? userRole = userRoleInt != null
        ? _roleEnumMap.entries
            .firstWhere((entry) => entry.value == userRoleInt)
            .key
        : null;

    return VerificationFilter(verified, userRole);
  }

  @override
  int get hashCode => verified.hashCode + userRole.hashCode;
}

class FilteringManager {
  FilteringManager._();
  static final shared = FilteringManager._();

  DateFilter? dateFilter;
  TaxonomyFilter? taxonomyFilter;
  LocationFilter? locationFilter;
  ImageFilter? imageFilter;
  VerificationFilter? verificationFilter;

  void configureFrom(FilteringManager filteringManager) {
    dateFilter = filteringManager.dateFilter;
    taxonomyFilter = filteringManager.taxonomyFilter;
    locationFilter = filteringManager.locationFilter;
    imageFilter = filteringManager.imageFilter;
    verificationFilter = filteringManager.verificationFilter;
    ordering = filteringManager.ordering;
    direction = filteringManager.direction;
  }

  Future<void> saveFilters() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File("$path/filtering.json");
    // print("Converting to JSON....");
    // print(toJson());
    // print(jsonEncode(toJson()));
    file.writeAsString(jsonEncode(toJson()));
  }

  Map<String, dynamic> toJson() => {
        'dateFilter': dateFilter?.toJson(),
        'taxonomyFilter': taxonomyFilter?.toJson(),
        'locationFilter': locationFilter?.toJson(),
        'imageFilter': imageFilter?.toJson(),
        'verificationFilter': verificationFilter?.toJson(),
        'ordering': _orderingEnumMap[ordering],
        'direction': _sortingDirectionEnumMap[direction],
      };

  Future<bool> get canLoadFilters async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File("$path/filtering.json");

    return await file.exists();
  }

  Future<void> readFilters() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File("$path/filtering.json");

    try {
      final contents = await file.readAsString();
      final json = jsonDecode(contents);
      final loaded = FilteringManager._fromJson(json);
      shared.configureFrom(loaded);
    } catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
    }
  }

  Future<void> loadFilters() async {
    if (await canLoadFilters) await readFilters();
  }

  factory FilteringManager._fromJson(Map<String, dynamic> json) {
    final dateFilter = json['dateFilter'] != null
        ? DateFilter?.fromJson(json['dateFilter'])
        : null;
    final taxonomyFilter = json['taxonomyFilter'] != null
        ? TaxonomyFilter?.fromJson(json['taxonomyFilter'])
        : null;
    final locationFilter = json['locationFilter'] != null
        ? LocationFilter?.fromJson(json['locationFilter'])
        : null;
    final imageFilter = json['imageFilter'] != null
        ? ImageFilter?.fromJson(json['imageFilter'])
        : null;
    final verificationFilter = json['verificationFilter'] != null
        ? VerificationFilter?.fromJson(json['verificationFilter'])
        : null;

    final orderingInt = json['ordering'] as int;

    final ordering = _orderingEnumMap.entries
        .firstWhere((entry) => entry.value == orderingInt)
        .key;

    final directionInt = json['direction'] as int;

    final direction = _sortingDirectionEnumMap.entries
        .firstWhere((entry) => entry.value == directionInt)
        .key;

    final newFilteringManager = FilteringManager._();
    newFilteringManager.dateFilter = dateFilter;
    newFilteringManager.taxonomyFilter = taxonomyFilter;
    newFilteringManager.locationFilter = locationFilter;
    newFilteringManager.imageFilter = imageFilter;
    newFilteringManager.verificationFilter = verificationFilter;
    newFilteringManager.ordering = ordering;
    newFilteringManager.direction = direction;

    return newFilteringManager;
  }

  List<ListFilter> get filters => [
        if (locationFilter != null) locationFilter!,
        if (dateFilter != null) dateFilter!,
        if (taxonomyFilter != null) taxonomyFilter!,
        if (imageFilter != null) imageFilter!,
        if (verificationFilter != null) verificationFilter!,
      ];

  ListOrdering ordering = ListOrdering.flightId;
  SortingDirection direction = SortingDirection.descending;
}

class FilteringScreen extends StatefulWidget {
  // const FilteringScreen({this.currentLocation, Key? key}) : super(key: key);
  const FilteringScreen({Key? key}) : super(key: key);

  // final LatLng? currentLocation;

  @override
  _FilteringScreenState createState() => _FilteringScreenState();
}

class _FilteringScreenState extends State<FilteringScreen>
    with TickerProviderStateMixin {
  late AppLocalizations _appLocalizations;
  late LatLng _currentLocation;

  var _ordering = FilteringManager.shared.ordering;
  var _direction = FilteringManager.shared.direction;
  var _dateFilter = FilteringManager.shared.dateFilter;
  var _taxonomyFilter = FilteringManager.shared.taxonomyFilter;
  var _locationFilter = FilteringManager.shared.locationFilter;
  var _imageFilter = FilteringManager.shared.imageFilter;
  var _verificationFilter = FilteringManager.shared.verificationFilter;

  @override
  void initState() {
    super.initState();
    _currentLocation = _locationFilter?.location ?? const LatLng(0, 0);

    // if (_locationFilter == null) {
    //   getCurrentLocation()
    //       .then((location) => _currentLocation = location ?? _currentLocation);
    // }
  }

  String _localizedOrderingName(ListOrdering listOrdering) {
    switch (listOrdering) {
      case ListOrdering.flightId:
        return _appLocalizations.flightID;
      case ListOrdering.dateOfFlight:
        return _appLocalizations.dateOfFlight;
      case ListOrdering.dateRecorded:
        return _appLocalizations.dateRecordedDetailLabel;
      case ListOrdering.location:
        return _appLocalizations.distance;
    }
  }

  String _localizedSortingDirectionName(SortingDirection direction) {
    switch (direction) {
      case SortingDirection.ascending:
        return _appLocalizations.ascending;
      case SortingDirection.descending:
        return _appLocalizations.descending;
    }
  }

  Widget _buildFilteringForm() {
    return ListView(
      primary: true,
      padding: const EdgeInsets.all(16.0),
      children: [
        HeaderRow(label: _appLocalizations.sorting),
        _buildSortingSection(),
        HeaderRow(label: _appLocalizations.filtering),
        DateFilteringRow(
          onFilteringChanged: (dateFilter) => _dateFilter = dateFilter,
          filter: _dateFilter,
        ),
        TaxonomyFilteringRow(
          onFilteringChanged: (taxonomyFilter) =>
              _taxonomyFilter = taxonomyFilter,
          filter: _taxonomyFilter,
        ),
        ImageFilteringRow(
          onFilteringChanged: (imageFilter) => _imageFilter = imageFilter,
          filter: _imageFilter,
        ),
        VerificationFilteringRow(
          onFilteringChanged: (verificationFilter) =>
              _verificationFilter = verificationFilter,
          filter: _verificationFilter,
        )
      ],
    );
  }

  Widget _buildSortingSection() {
    // return AnimatedSize(
    //   duration: const Duration(milliseconds: 250),
    //   curve: Curves.easeIn,
    //   alignment: Alignment.topCenter,
    //   child: Column(
    //     children: [
    //       _buildSortingRow(),
    //       if (_ordering == ListOrdering.location) _buildLocationSelectRow(),
    //     ],
    //   ),
    // );
    return SortingSection(
      ordering: _ordering,
      direction: _direction,
      locationFilter: _locationFilter,
      onSortingChanged: (ordering, direction, locationFilter) {
        // print("Sorting is now changed...");
        _ordering = ordering;
        _direction = direction;
        if (_ordering == ListOrdering.location) {
          // print(
          //     "We have a filter at this location: ${locationFilter?.location ?? "None"}");
          _locationFilter = locationFilter ?? LocationFilter(_currentLocation);
        } else {
          _locationFilter = null;
        }
        // setState(() => updateFilters());
        // print("Now, at the screen level, we have filter at ${locationFilter?.location ?? "None"}");
      },
    );
  }

  // Widget _buildSortingRow() {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Wrap(
  //       alignment: WrapAlignment.spaceEvenly,
  //       crossAxisAlignment: WrapCrossAlignment.center,
  //       runAlignment: WrapAlignment.start,
  //       spacing: 16,
  //       runSpacing: 16,
  //       children: [
  //         // ConstrainedBox(
  //         //   child: Text(_appLocalizations.sortBy),
  //         //   constraints: const BoxConstraints(maxWidth: 500),
  //         // ),
  //         ConstrainedBox(
  //           constraints: const BoxConstraints(maxWidth: 500),
  //           child: ToggleButtons(
  //             isSelected: [
  //               for (var direction in SortingDirection.values)
  //                 _direction == direction
  //             ],
  //             children: [
  //               for (var direction in SortingDirection.values)
  //                 Padding(
  //                   padding: const EdgeInsets.all(8.0),
  //                   child: Text(_localizedSortingDirectionName(direction)),
  //                 )
  //             ],
  //             onPressed: (index) => setState(
  //               () => _direction = SortingDirection.values[index],
  //             ),
  //           ),
  //         ),
  //         ConstrainedBox(
  //           constraints: const BoxConstraints(maxWidth: 500),
  //           child: DropdownButton<ListOrdering>(
  //             items: ListOrdering.values
  //                 .map((e) => DropdownMenuItem(
  //                     value: e, child: Text(_localizedOrderingName(e))))
  //                 .toList(),
  //             value: _ordering,
  //             icon: const Icon(Icons.sort),
  //             onChanged: (ordering) => setState(() {
  //               _ordering = ordering ?? ListOrdering.flightId;
  //               if (_ordering == ListOrdering.location) {
  //                 _locationFilter =
  //                     _locationFilter ?? LocationFilter(_currentLocation);
  //               } else {
  //                 _locationFilter = null;
  //               }
  //             }),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  bool get didNotChangeFilters =>
      _ordering == FilteringManager.shared.ordering &&
      _direction == FilteringManager.shared.direction &&
      _imageFilter == FilteringManager.shared.imageFilter &&
      _verificationFilter == FilteringManager.shared.verificationFilter &&
      _dateFilter == FilteringManager.shared.dateFilter &&
      _locationFilter == FilteringManager.shared.locationFilter &&
      _taxonomyFilter == FilteringManager.shared.taxonomyFilter;

  void updateFilters() {
    FilteringManager.shared.dateFilter = _dateFilter;
    FilteringManager.shared.taxonomyFilter = _taxonomyFilter;
    FilteringManager.shared.ordering = _ordering;
    FilteringManager.shared.locationFilter = _locationFilter;
    FilteringManager.shared.direction = _direction;
    FilteringManager.shared.imageFilter = _imageFilter;
    FilteringManager.shared.verificationFilter = _verificationFilter;
  }

  // Widget _buildLocationSelectRow() {
  //   return LocationSelectRow(
  //       initialLocation: _locationFilter?.location ?? _currentLocation,
  //       onLocationSelected: (location) {
  //         print("Now, in filtering manager, selected: $location");
  //         updateFilters();
  //         setState(() {
  //           _locationFilter = LocationFilter(location);
  //         });
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_appLocalizations.filteringAndSorting),
        actions: [
          IconButton(
            onPressed: () async {
              final shouldReload = !didNotChangeFilters;
              if (shouldReload) {
                // print("Changed filters!!!");
                updateFilters();
                await FilteringManager.shared.saveFilters();
              } else {
                // print("No filters changed!");
              }
              // print("Printing filters:");
              for (var filter in FilteringManager.shared.filters) {
              // print(filter.queryParameters);
              }
              Navigator.of(context).pop(shouldReload);
            },
            tooltip: _appLocalizations.done,
            icon: const Icon(Icons.done),
          )
        ],
      ),
      body: SafeArea(child: _buildFilteringForm()),
    );
  }
}

class LocationSelectRow extends StatefulWidget {
  const LocationSelectRow(
      {this.initialLocation, required this.onLocationSelected, Key? key})
      : super(key: key);

  final LatLng? initialLocation;
  final void Function(LatLng) onLocationSelected;

  @override
  _LocationSelectRowState createState() => _LocationSelectRowState();
}

class _LocationSelectRowState extends State<LocationSelectRow> {
  late LatLng _selectedLocation;

  // late void Function(LatLng) _onLocationSelected;

  @override
  void initState() {
    super.initState();
    // _getLocationFuture = getCurrentLocation().then((value) => value ?? const LatLng(0.0, 0.0));
    _getLocationFuture = getFilterLocation();
    _selectedLocation = widget.initialLocation ?? const LatLng(0, 0);
    // _onLocationSelected = widget.onLocationSelected;

    // if (widget.initialLocation == null) {
    //   getCurrentLocation().then((location){
    //     if (location != null) {
    //       setState(() => _selectedLocation = location);
    //     }
    //   });
    // }
  }

  Future<LatLng> getFilterLocation() async {
    return widget.initialLocation ??
        await getCurrentLocation() ??
        const LatLng(0.0, 0.0);
  }

  Future<void> _getNewLocation() async {
    final newLocation = await Navigator.push(
      context,
      MaterialPageRoute<LatLng>(
          builder: (context) => LocationPickerView(
                locationPickerMode: LocationPickerMode.locationOnly,
                initialLocation: _selectedLocation,
              ),
          fullscreenDialog: true),
    );

    if (newLocation == null) return;

    setState(() {
      _selectedLocation = newLocation;
      _getLocationFuture = getFilterLocation();
      // print("Selected new location $newLocation");
    });

    widget.onLocationSelected(newLocation);
  }

  late Future<LatLng?> _getLocationFuture;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_pin),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        tooltip: AppLocalizations.of(context)!.edit,
        onPressed: _getNewLocation,
      ),
      title: Text(
        // AppLocalizations.of(context)!.fromLocation(
        stringFromLocation(
          location: _selectedLocation,
        ),
        // ),
      ),
      onTap: _getNewLocation,
    );

    // return FutureBuilder(
    //   future: _getLocationFuture,
    //   builder: (BuildContext context, AsyncSnapshot<LatLng?> snapshot) {
    //     if (snapshot.connectionState == ConnectionState.done &&
    //         snapshot.hasData) {
    //       _selectedLocation = snapshot.data ?? const LatLng(0.0, 0.0);
    //
    //       return ListTile(
    //         leading: const Icon(Icons.location_pin),
    //         trailing: IconButton(
    //           icon: const Icon(Icons.edit),
    //           tooltip: AppLocalizations.of(context)!.edit,
    //           onPressed: _getNewLocation,
    //         ),
    //         title: Text(
    //           // AppLocalizations.of(context)!.fromLocation(
    //           stringFromLocation(
    //             location: _selectedLocation,
    //           ),
    //           // ),
    //         ),
    //         onTap: _getNewLocation,
    //       );
    //     }
    //
    //     // if (snapshot.hasError){
    //     //   print(snapshot.error);
    //     //   print(snapshot.stackTrace);
    //     // }
    //
    //     return const ListTile(
    //       title: Text("Updating Location"),
    //       leading: CircularProgressIndicator(),
    //     );
    //   },
    // );
  }
}

class SortingSection extends StatefulWidget {
  const SortingSection({
    Key? key,
    this.ordering = ListOrdering.flightId,
    this.direction = SortingDirection.descending,
    this.locationFilter,
    required this.onSortingChanged,
  }) : super(key: key);

  final ListOrdering ordering;
  final SortingDirection direction;
  final LocationFilter? locationFilter;
  final void Function(ListOrdering ordering, SortingDirection direction,
      LocationFilter? locationFilter) onSortingChanged;

  @override
  State<SortingSection> createState() => _SortingSectionState();
}

class _SortingSectionState extends State<SortingSection> {
  late AppLocalizations _appLocalizations;
  // late LatLng? _currentLocation;
  late var _ordering = widget.ordering;
  late var _direction = widget.direction;
  late var _locationFilter = widget.locationFilter;
  late final _onSortingChanged = widget.onSortingChanged;

  @override
  void initState() {
    super.initState();
    _getLocationFuture = getFilterLocation();
    // _currentLocation = _locationFilter?.location ?? const LatLng(0, 0);

    // if (_locationFilter == null) {
    //   getCurrentLocation()
    //       .then((location) => _currentLocation = location ?? _currentLocation);
    // }
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeIn,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          _buildSortingRow(),
          if (_ordering == ListOrdering.location) _buildLocationSelectRow(),
        ],
      ),
    );
  }

  Widget _buildSortingRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        crossAxisAlignment: WrapCrossAlignment.center,
        runAlignment: WrapAlignment.start,
        spacing: 16,
        runSpacing: 16,
        children: [
          // ConstrainedBox(
          //   child: Text(_appLocalizations.sortBy),
          //   constraints: const BoxConstraints(maxWidth: 500),
          // ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ToggleButtons(
              isSelected: [
                for (var direction in SortingDirection.values)
                  _direction == direction
              ],
              children: [
                for (var direction in SortingDirection.values)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_localizedSortingDirectionName(direction)),
                  )
              ],
              onPressed: (index) => setState(
                () {
                  _direction = SortingDirection.values[index];
                  _onSortingChanged(_ordering, _direction, _locationFilter);
                },
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: DropdownButton<ListOrdering>(
              items: ListOrdering.values
                  .map((e) => DropdownMenuItem(
                      value: e, child: Text(_localizedOrderingName(e))))
                  .toList(),
              value: _ordering,
              icon: const Icon(Icons.sort),
              onChanged: (ordering) => setState(() {
                _ordering = ordering ?? ListOrdering.flightId;
                // if (_ordering == ListOrdering.location) {
                //   // _locationFilter =
                //   //     _locationFilter ?? LocationFilter(_currentLocation);
                // } else {
                //   _locationFilter = null;
                // }

                if (_ordering != ListOrdering.location) {
                  _locationFilter = null;
                }

                _onSortingChanged(_ordering, _direction, _locationFilter);
              }),
            ),
          ),
        ],
      ),
    );
  }

  late Future<LatLng> _getLocationFuture;

  Future<LatLng> getFilterLocation() async {
    return _locationFilter?.location ??
        await getCurrentLocation() ??
        const LatLng(0.0, 0.0);
  }

  Widget _buildLocationSelectRow() {
    return FutureBuilder(
        future: _getLocationFuture,
        builder: (BuildContext context, AsyncSnapshot<LatLng> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return LocationSelectRow(
                initialLocation: snapshot.data!,
                onLocationSelected: (location) {
                  _locationFilter = LocationFilter(location);
                  // print("Now, in filtering manager, selected: $location");
                  _onSortingChanged(_ordering, _direction, _locationFilter);
                  setState(() {
                    _getLocationFuture = getFilterLocation();
                  });
                });
          } else {
            return ListTile(
              title: Text(_appLocalizations.updatingLocation),
              leading: const CircularProgressIndicator(),
            );
          }
        });
  }

  String _localizedOrderingName(ListOrdering listOrdering) {
    switch (listOrdering) {
      case ListOrdering.flightId:
        return _appLocalizations.flightID;
      case ListOrdering.dateOfFlight:
        return _appLocalizations.dateOfFlight;
      case ListOrdering.dateRecorded:
        return _appLocalizations.dateRecordedDetailLabel;
      case ListOrdering.location:
        return _appLocalizations.distance;
    }
  }

  String _localizedSortingDirectionName(SortingDirection direction) {
    switch (direction) {
      case SortingDirection.ascending:
        return _appLocalizations.ascending;
      case SortingDirection.descending:
        return _appLocalizations.descending;
    }
  }
}

abstract class FilteringRow<T extends ListFilter> extends StatefulWidget {
  const FilteringRow({
    Key? key,
    this.filter,
    required this.onFilteringChanged,
  }) : super(key: key);

  final T? filter;
  final void Function(T?) onFilteringChanged;

  // @override
  // _FilteringRowState createState() => _FilteringRowState();
}

abstract class _FilteringRowState<T extends ListFilter>
    extends State<FilteringRow<T>> with TickerProviderStateMixin {
  @protected
  late bool isFiltering;

  @protected
  void processInitialValue(T? filter);

  @override
  void initState() {
    isFiltering = widget.filter != null;
    processInitialValue(widget.filter);
    super.initState();
  }

  @protected
  T? createFilter();

  @protected
  String get filterLabel;

  @protected
  Widget buildBody(BuildContext context);

  @protected
  Duration get duration => const Duration(milliseconds: 250);

  @protected
  Curve get curve => Curves.easeIn;

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      alignment: Alignment.topCenter,
      curve: curve,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isFiltering = !isFiltering;
                widget.onFilteringChanged(createFilter());
              });
            },
            child: Row(
              children: [
                Text(filterLabel),
                const Spacer(),
                Switch(
                    value: isFiltering,
                    onChanged: (value) {
                      setState(() => isFiltering = value);
                      widget.onFilteringChanged(createFilter());
                    })
              ],
            ),
          ),
          if (isFiltering) buildBody(context),
          const Divider()
        ],
      ),
    );
  }
}

class DateFilteringRow extends FilteringRow<DateFilter> {
  const DateFilteringRow({
    Key? key,
    DateFilter? filter,
    required void Function(DateFilter?) onFilteringChanged,
  }) : super(
          key: key,
          filter: filter,
          onFilteringChanged: onFilteringChanged,
        );

  @override
  State<StatefulWidget> createState() => _DateFilteringRowState();
}

class _DateFilteringRowState extends _FilteringRowState<DateFilter> {
  late bool _hasMinDate;
  late DateTime? _minDate;
  late bool _hasMaxDate;
  late DateTime? _maxDate;

  late AppLocalizations _appLocalizations;

  @override
  void processInitialValue(DateFilter? filter) {
    _hasMinDate = widget.filter?.minDate != null;
    _minDate = widget.filter?.minDate ?? DateTime.now();
    _hasMaxDate = widget.filter?.maxDate != null;
    _maxDate = widget.filter?.maxDate ?? DateTime.now();
  }

  @override
  DateFilter? createFilter() {
    return isFiltering && (_hasMinDate || _hasMaxDate)
        ? DateFilter(
            _hasMaxDate ? _maxDate : null, _hasMinDate ? _minDate : null)
        : null;
  }

  @override
  String get filterLabel => _appLocalizations.filterByDate;

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return super.build(context);
  }

  static final earliestDate = DateTime(1900);

  @override
  Widget buildBody(BuildContext context) {
    // var labelTheme = Theme.of(context).textTheme.bodyText1!;
    final labelTheme = Theme.of(context).textTheme.subtitle1!;
    // var activeColor = labelTheme.color;
    final deactivatedColor = Theme.of(context).disabledColor;
    final deactivatedLabelTheme = labelTheme.apply(color: deactivatedColor);
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() => _hasMinDate = !_hasMinDate);
            widget.onFilteringChanged(createFilter());
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Checkbox(
                value: _hasMinDate,
                onChanged: isFiltering
                    ? (value) {
                        setState(() => _hasMinDate = value ?? false);
                        widget.onFilteringChanged(createFilter());
                      }
                    : null,
              ),
              Text(
                _appLocalizations.minDate,
                style: _hasMinDate ? labelTheme : deactivatedLabelTheme,
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMd(_appLocalizations.localeName)
                    .format(_minDate ?? _maxDate ?? DateTime.now()),
                style: _hasMinDate ? labelTheme : deactivatedLabelTheme,
              ),
              IconButton(
                onPressed: _hasMinDate
                    ? () async {
                        final newMinDate = await showDatePicker(
                            context: context,
                            firstDate: earliestDate,
                            initialDate: _hasMinDate
                                ? _minDate!
                                : _hasMaxDate
                                    ? _maxDate!
                                    : DateTime.now(),
                            lastDate: _hasMaxDate ? _maxDate! : DateTime.now());
                        setState(() => _minDate = newMinDate);
                        widget.onFilteringChanged(createFilter());
                      }
                    : null,
                icon: const Icon(
                  Icons.edit,
                  // color: _hasMinDate ? activeColor : deactivatedColor,
                ),
                tooltip: _appLocalizations.edit,
                disabledColor: deactivatedColor,
              )
            ],
          ),
        ),
        InkWell(
          onTap: () {
            setState(() => _hasMaxDate = !_hasMaxDate);
            widget.onFilteringChanged(createFilter());
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Checkbox(
                value: _hasMaxDate,
                onChanged: isFiltering
                    ? (value) {
                        setState(() => _hasMaxDate = value ?? false);
                        widget.onFilteringChanged(createFilter());
                      }
                    : null,
              ),
              Text(
                _appLocalizations.maxDate,
                style: _hasMaxDate ? labelTheme : deactivatedLabelTheme,
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMd(_appLocalizations.localeName)
                    .format(_maxDate ?? _minDate ?? DateTime.now()),
                style: _hasMaxDate ? labelTheme : deactivatedLabelTheme,
              ),
              IconButton(
                onPressed: _hasMaxDate
                    ? () async {
                        final newMaxDate = await showDatePicker(
                            context: context,
                            firstDate: _hasMinDate ? _minDate! : earliestDate,
                            initialDate: _maxDate ?? _minDate ?? DateTime.now(),
                            lastDate: DateTime.now());
                        setState(() => _maxDate = newMaxDate);
                        widget.onFilteringChanged(createFilter());
                      }
                    : null,
                icon: const Icon(
                  Icons.edit,
                  // color: _hasMaxDate ? activeColor : deactivatedColor,
                ),
                tooltip: _appLocalizations.edit,
                disabledColor: deactivatedColor,
              )
            ],
          ),
        )
      ],
    );
  }
}

class TaxonomyFilteringRow extends FilteringRow<TaxonomyFilter> {
  const TaxonomyFilteringRow({
    Key? key,
    TaxonomyFilter? filter,
    required void Function(TaxonomyFilter?) onFilteringChanged,
  }) : super(
          key: key,
          filter: filter,
          onFilteringChanged: onFilteringChanged,
        );

  @override
  _TaxonomyFilteringRowState createState() => _TaxonomyFilteringRowState();
}

class _TaxonomyFilteringRowState extends _FilteringRowState<TaxonomyFilter> {
  late List<Genus> _genera;
  late List<Species> _species;

  late AppLocalizations _appLocalizations;

  @override
  TaxonomyFilter? createFilter() =>
      isFiltering ? TaxonomyFilter(genera: _genera, species: _species) : null;

  @override
  void processInitialValue(TaxonomyFilter? filter) {
    _genera = List.of(widget.filter?.genera ?? const []);
    _species = List.of(widget.filter?.species ?? const []);
  }

  @override
  Widget buildBody(BuildContext context) {
    // var labelTheme = Theme.of(context).textTheme.bodyText1!;
    var labelTheme = Theme.of(context).textTheme.subtitle1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _appLocalizations.filteringByGenera(_genera.length),
                style: labelTheme,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _appLocalizations.filteringBySpecies(_species.length),
                style: labelTheme,
              ),
            )
          ],
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: _appLocalizations.edit,
          onPressed: () async {
            // final newFilter = await Navigator.of(context)
            //     .push<TaxonomyFilter>(MaterialPageRoute(
            //   builder: (context) => TaxonomyFilteringScreen(
            //     selectedGenera: _genera,
            //     selectedSpecies: _species,
            //   ),
            // ));

            final newFilter = await Navigator.of(context)
                .push<TaxonomyFilter>(MaterialPageRoute(
                    builder: (context) => TaxonomyFilteringScreen(
                          selectedGenera: List.of(_genera),
                          selectedSpecies: List.of(_species),
                          taxonomySelectionScreenType: TaxonomySelectionScreenType.filtering,
                          // filteringScreenHeader:
                          //     _appLocalizations.filterByTaxonomy,
                        ),
                    fullscreenDialog: true));

            if (newFilter == null) {
              return;
            }

            setState(() {
              _genera = newFilter.genera;
              _species = newFilter.species;
            });

            widget.onFilteringChanged(createFilter());

            // if (newFilter != null) {
            //   setState(() {
            //     _genera = newFilter.genera;
            //     _species = newFilter.species;
            //   });
            // }
          },
        )
      ],
    );
  }

  @override
  String get filterLabel => _appLocalizations.filterByTaxonomy;

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return super.build(context);
  }
}

class NameableSearchDelegate extends SearchDelegate<Nameable?> {
  NameableSearchDelegate({
    required this.universe,
    // required this.onResultSelected,
    // this.initiallySelected = const <String>[],
    String? searchFieldLabel,
    TextStyle? searchFieldStyle,
    InputDecorationTheme? searchFieldDecorationTheme,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.search,
  }) : super(
          searchFieldLabel: searchFieldLabel,
          searchFieldStyle: searchFieldStyle,
          searchFieldDecorationTheme: searchFieldDecorationTheme,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
        );

  final List<Nameable> universe;
  // final List<String> initiallySelected;
  // final void Function(String result) onResultSelected;

  // late final List<String> selectedResults;

  List<Nameable> _getResults(String query) {
    if (query.trim().isEmpty) return universe;

    final results = universe
        .where((element) =>
            element.name.toLowerCase().contains(query.toLowerCase()))
        .toList(growable: false);

    results.sort((s1, s2) {
      final positionBasedOrdering = s1.name
          .toLowerCase()
          .indexOf(query.toLowerCase())
          .compareTo(s2.name.toLowerCase().indexOf(query.toLowerCase()));
      return positionBasedOrdering != 0
          ? positionBasedOrdering
          : s1.name.compareTo(s2.name);
    });

    // print("There are ${results.length} results");

    return results;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
          showSuggestions(context);
        },
        icon: const Icon(Icons.clear),
        tooltip: AppLocalizations.of(context)!.clear,
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () => close(context, null), icon: const BackButtonIcon());
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _getResults(query);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => ListTile(
          title: Text(results[index].name),
          onTap: () => close(context, results[index])),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _getResults(query);
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(suggestions[index].name),
        onTap: () {
          query = suggestions[index].name;
          // buildResults(context);
          showResults(context);
        },
      ),
    );
  }
}

enum TaxonomySelectionScreenType {
  filtering,
  notifications
}

extension GetLabels on TaxonomySelectionScreenType {
  String getScreenTitle(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    switch (this) {
      case TaxonomySelectionScreenType.filtering:
        return appLocalizations.filterByTaxonomy;
      case TaxonomySelectionScreenType.notifications:
        return appLocalizations.notifications;
    }
  }
  
  String getGeneraHeader(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    
    switch (this) {
      case TaxonomySelectionScreenType.filtering:
        return appLocalizations.filteringGenera;
      case TaxonomySelectionScreenType.notifications:
        return appLocalizations.notifyingGenera;
    }
  }

  String getSpeciesHeader(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    switch (this) {
      case TaxonomySelectionScreenType.filtering:
        return appLocalizations.filteringSpecies;
      case TaxonomySelectionScreenType.notifications:
        return appLocalizations.notifyingSpecies;
    }
  }
}

class TaxonomyFilteringScreen extends StatefulWidget {
  const TaxonomyFilteringScreen(
      {this.selectedGenera = const <Genus>[],
      this.selectedSpecies = const <Species>[],
      this.onFilteringSaved,
      // required this.filteringScreenHeader,
      this.taxonomySelectionScreenType = TaxonomySelectionScreenType.filtering,
      Key? key})
      : super(key: key);

  final List<Genus> selectedGenera;
  final List<Species> selectedSpecies;
  // final String filteringScreenHeader;
  final TaxonomySelectionScreenType taxonomySelectionScreenType;

  final Future<void> Function(TaxonomyFilter?)? onFilteringSaved;

  @override
  _TaxonomyFilteringScreenState createState() =>
      _TaxonomyFilteringScreenState();
}

class _TaxonomyFilteringScreenState extends State<TaxonomyFilteringScreen> {
  late AppLocalizations _appLocalizations;
  late List<Genus> _selectedGenera;
  late List<Species> _selectedSpecies;

  late List<Widget> _genusListEntries;
  late List<Widget> _speciesListEntries;

  @override
  void initState() {
    // _selectedGenera = List.of(widget.selectedGenera);
    // _selectedSpecies = List.of(widget.selectedSpecies);
    _selectedGenera = widget.selectedGenera;
    _selectedSpecies = widget.selectedSpecies;
    super.initState();

    _genusListEntries = _selectedGenera.map((e) => Text(e.toString())).toList();
    _speciesListEntries =
        _selectedSpecies.map((e) => Text(e.toString())).toList();
  }

  TaxonomyFilter? _generateFlightFilter() {
    if (_selectedSpecies.isEmpty && _selectedGenera.isEmpty) return null;

    return TaxonomyFilter(genera: _selectedGenera, species: _selectedSpecies);
  }

  Future<void> doneFiltering() async {
    final newFilter = _generateFlightFilter();
    if (widget.onFilteringSaved != null) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(_appLocalizations.updatingSettings),
                content: const LinearProgressIndicator(),
              ),
          barrierDismissible: false);
      await widget.onFilteringSaved!(newFilter);
    }
    Navigator.of(context).pop(newFilter);
    if (widget.onFilteringSaved != null) {
      Navigator.of(context).pop(newFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taxonomySelectionScreenType.getScreenTitle(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: _appLocalizations.clear,
            onPressed: () => setState(
              () {
                _selectedGenera.clear();
                _selectedSpecies.clear();
              },
            ),
          ),
          IconButton(
            onPressed: doneFiltering,
            icon: const Icon(Icons.done),
            tooltip: _appLocalizations.done,
          )
        ],
      ),
      floatingActionButton: _buildAddFilteringButton(),
      body: SafeArea(
        child: ListView(
          primary: true,
          padding: const EdgeInsets.all(8.0),
          children: [
            // HeaderRow(label: _appLocalizations.filteringGenera),
            HeaderRow(label: widget.taxonomySelectionScreenType.getGeneraHeader(context)),
            for (var genus in _selectedGenera)
              Dismissible(
                key: ValueKey(genus),
                child: ListTile(title: Text(genus.toString())),
                onDismissed: (_) =>
                    setState(() => _selectedGenera.remove(genus)),
                background: Container(
                  color: Colors.red,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_appLocalizations.delete),
                      const Icon(Icons.delete)
                    ],
                  ),
                ),
              ),
            // HeaderRow(label: _appLocalizations.filteringSpecies),
            HeaderRow(label: widget.taxonomySelectionScreenType.getSpeciesHeader(context)),
            if (_selectedSpecies.isNotEmpty)
              for (var species in _selectedSpecies)
                Dismissible(
                  key: ValueKey(species),
                  child: ListTile(title: Text(species.toString())),
                  onDismissed: (_) =>
                      setState(() => _selectedSpecies.remove(species)),
                  background: Container(
                    color: Colors.red,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(_appLocalizations.delete),
                        const Icon(Icons.delete)
                      ],
                    ),
                  ),
                )
          ],
        ),
      ),
    );
  }

  FloatingActionButton _buildAddFilteringButton() {
    return FloatingActionButton(
      onPressed: () async {
        // final newFilter =
        await Navigator.of(context).push(MaterialPageRoute<TaxonomyFilter>(
            builder: (context) => TaxonomyFilteringGeneraScreen(
                  selectedGenera: _selectedGenera,
                  selectedSpecies: _selectedSpecies,
                )));
        // if (newFilter != null) {
        //   setState(() {
        //     _selectedGenera = newFilter.genera;
        //     _selectedSpecies = newFilter.species;
        //   });
        // }
        setState(() {});
      },
      child: const Icon(Icons.add),
    );
  }
}

class TaxonomyFilteringGeneraScreen extends StatelessWidget {
  TaxonomyFilteringGeneraScreen({
    Key? key,
    this.selectedGenera = const [],
    this.selectedSpecies = const [],
  }) : super(key: key);

  final List<Genus> selectedGenera;
  final List<Species> selectedSpecies;

  final _listScrollController = ItemScrollController();

  // final genera = List<String>.unmodifiable(TaxonomyManager.shared.genera);
  final genera = Genus.getAll();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.selectGenus),
        actions: [
          IconButton(
              onPressed: () async {
                final genus = await showSearch<Nameable?>(
                    context: context,
                    delegate: NameableSearchDelegate(universe: genera));

                // print("Got genus $genus");

                if (genus == null || genus is! Genus) {
                  return;
                }

                // final index = genera.indexWhere((element) => element.name == genus);
                final index = genera.indexOf(genus);

                // print("Item is at index $index");
                _listScrollController.scrollTo(
                    index: index,
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeIn);
              },
              icon: const Icon(Icons.search))
        ],
      ),
      body: SafeArea(
        child: ScrollablePositionedList.separated(
          itemScrollController: _listScrollController,
          itemCount: genera.length,
          itemBuilder: (context, index) => ListTile(
              title: Text(genera[index].name),
              trailing: const Icon(Icons.more_horiz),
              onTap: () {
                // print(genera[index]);
                final genus = genera[index];
                // final genus = Genus.get(genera[index]);

                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => TaxonomyFilteringSpeciesScreen(
                          genus: genus,
                          selectedGenera: selectedGenera,
                          selectedSpecies: selectedSpecies,
                        )));
              }),
          separatorBuilder: (context, index) => const Divider(),
        ),
      ),
    );
  }
}

class TaxonomyFilteringSpeciesScreen extends StatefulWidget {
  const TaxonomyFilteringSpeciesScreen({
    Key? key,
    required this.genus,
    this.selectedGenera = const [],
    this.selectedSpecies = const [],
  }) : super(key: key);

  final Genus genus;
  final List<Genus> selectedGenera;
  final List<Species> selectedSpecies;

  @override
  _TaxonomyFilteringSpeciesScreenState createState() =>
      _TaxonomyFilteringSpeciesScreenState();
}

class _TaxonomyFilteringSpeciesScreenState
    extends State<TaxonomyFilteringSpeciesScreen> {
  late final List<Species> _species;
  late final Genus _genus;

  late final List<Genus> _selectedGenera;
  late final List<Species> _selectedSpecies;

  final _listScrollController = ItemScrollController();

  @override
  void initState() {
    _genus = widget.genus;
    _selectedGenera = widget.selectedGenera;
    _selectedSpecies = widget.selectedSpecies;
    _species =
        _genus.species; //TaxonomyManager.shared.speciesForGenus(_genus.name);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.selectSpecies),
        actions: [
          IconButton(
              onPressed: () async {
                final foundSpecies = await showSearch<Nameable?>(
                    context: context,
                    delegate: NameableSearchDelegate(universe: _species));

                // print("Got species $foundSpecies");

                if (foundSpecies == null || foundSpecies is! Species) {
                  return;
                }

                final index = _species.indexOf(foundSpecies);

                final adjustedIndex = index + 3;

                // print("Item is at index $index");
                _listScrollController.scrollTo(
                    index: adjustedIndex,
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeIn);
              },
              icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () => setState(() {
              _selectedSpecies
                  .removeWhere((element) => element.genus == _genus);
              if (_selectedGenera.contains(_genus)) {
                _selectedGenera.remove(_genus);
              }
            }),
            icon: const Icon(Icons.delete_sweep),
            tooltip: appLocalizations.clear,
          ),
          // IconButton(onPressed: (){}, icon: const Icon(Icons.done))
        ],
      ),
      body: SafeArea(
          child: ScrollablePositionedList.separated(
        itemScrollController: _listScrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: _species.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return HeaderRow(label: appLocalizations.entireGenus);
          } else if (index == 1) {
            return ListTile(
              title: Text(_genus.name),
              onTap: () {
                if (_selectedGenera.contains(_genus)) {
                  setState(() => _selectedGenera.remove(_genus));
                } else {
                  setState(() => _selectedGenera.add(_genus));
                }
              },
              trailing: _selectedGenera.contains(_genus)
                  ? const Icon(Icons.check)
                  : null,
            );
          } else if (index == 2) {
            return HeaderRow(
              label: appLocalizations.species,
            );
          } else {
            final adjustedIndex = index - 3;
            // final _speciesName =
            final _rowSpecies = _species[adjustedIndex];
            var _speciesName = _species[adjustedIndex].name;
            return ListTile(
              title: Text(_rowSpecies.toString()),
              trailing: _selectedSpecies.any((element) =>
                      element.genus == _genus && element.name == _speciesName)
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                // final relevantSpecies = Species.get(_genus, _speciesName);
                final relevantSpecies = _species[adjustedIndex];
                if (_selectedSpecies.contains(relevantSpecies)) {
                  setState(() {
                    _selectedSpecies.remove(relevantSpecies);
                  });
                } else {
                  setState(() {
                    _selectedSpecies.add(relevantSpecies);
                  });
                }
              },
            );
          }
        },
        separatorBuilder: (context, index) =>
            index >= 3 ? const Divider() : const SizedBox.shrink(),
      )),
    );
  }
}

class ImageFilteringRow extends FilteringRow<ImageFilter> {
  const ImageFilteringRow({
    Key? key,
    ImageFilter? filter,
    required void Function(ImageFilter?) onFilteringChanged,
  }) : super(
          key: key,
          filter: filter,
          onFilteringChanged: onFilteringChanged,
        );

  @override
  State<StatefulWidget> createState() => _ImageFilteringRowState();
}

class _ImageFilteringRowState extends _FilteringRowState<ImageFilter> {
  bool _hasImages = false;
  late AppLocalizations _appLocalizations;

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        RadioListTile<bool>(
          groupValue: _hasImages,
          value: false,
          onChanged: (value) {
            setState(() {
              _hasImages = value!;
            });
            widget.onFilteringChanged(createFilter());
          },
          title: Text(_appLocalizations.noImages),
        ),
        RadioListTile<bool>(
          groupValue: _hasImages,
          value: true,
          onChanged: (value) {
            setState(() {
              _hasImages = value!;
            });
            widget.onFilteringChanged(createFilter());
          },
          title: Text(_appLocalizations.hasImages),
        ),
      ],
    );
  }

  @override
  ImageFilter? createFilter() => isFiltering ? ImageFilter(_hasImages) : null;

  @override
  String get filterLabel => _appLocalizations.filterByImages;

  @override
  void processInitialValue(ImageFilter? filter) {
    _hasImages = filter?.hasImages ?? false;
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return super.build(context);
  }
}

class VerificationFilteringRow extends FilteringRow<VerificationFilter> {
  const VerificationFilteringRow({
    Key? key,
    VerificationFilter? filter,
    required void Function(VerificationFilter?) onFilteringChanged,
  }) : super(
          key: key,
          filter: filter,
          onFilteringChanged: onFilteringChanged,
        );

  @override
  State<StatefulWidget> createState() => _VerificationFilteringRowState();
}

class _VerificationFilteringRowState
    extends _FilteringRowState<VerificationFilter> {
  var _isFilteringUserRole = false;
  late Role _userRole;
  var _isFilteringVerification = false;
  late bool _verified;

  late AppLocalizations _appLocalizations;

  @override
  Widget buildBody(BuildContext context) {
    final labelTheme = Theme.of(context).textTheme.subtitle1!;
    final deactivatedColor = Theme.of(context).disabledColor;
    final deactivatedLabelTheme = labelTheme.apply(color: deactivatedColor);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isFilteringUserRole = !_isFilteringUserRole;
            });
            widget.onFilteringChanged(createFilter());
          },
          child: Row(
            children: [
              Checkbox(
                value: _isFilteringUserRole,
                onChanged: (value) {
                  setState(() => _isFilteringUserRole = value!);
                  widget.onFilteringChanged(createFilter());
                },
              ),
              Text(
                _appLocalizations.filteringByUserRole,
                style:
                    _isFilteringUserRole ? labelTheme : deactivatedLabelTheme,
              ),
              const Spacer(),
              DropdownButton<Role>(
                items: [
                  DropdownMenuItem(
                    value: Role.professional,
                    child: Text(_appLocalizations.professionalUser),
                  ),
                  DropdownMenuItem(
                    value: Role.citizen,
                    child: Text(_appLocalizations.citizenUser),
                  )
                ],
                value: _userRole,
                onChanged: _isFilteringUserRole
                    ? (value) {
                        setState(() {
                          _userRole = value!;
                        });
                        widget.onFilteringChanged(createFilter());
                      }
                    : null,
              )
            ],
          ),
        ),
        InkWell(
          onTap: () {
            setState(() {
              _isFilteringVerification = !_isFilteringVerification;
            });
            widget.onFilteringChanged(createFilter());
          },
          child: Row(
            children: [
              Checkbox(
                value: _isFilteringVerification,
                onChanged: (value) {
                  setState(() => _isFilteringVerification = value!);
                  widget.onFilteringChanged(createFilter());
                },
              ),
              Text(
                _appLocalizations.filteringByVerification,
                style: _isFilteringVerification
                    ? labelTheme
                    : deactivatedLabelTheme,
              ),
              const Spacer(),
              DropdownButton<bool>(
                items: [
                  DropdownMenuItem(
                    value: true,
                    child: Text(_appLocalizations.verified),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text(_appLocalizations.notVerified),
                  )
                ],
                value: _verified,
                onChanged: _isFilteringVerification
                    ? (value) {
                        setState(() {
                          _verified = value!;
                        });
                        widget.onFilteringChanged(createFilter());
                      }
                    : null,
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  VerificationFilter? createFilter() {
    return (isFiltering && (_isFilteringUserRole || _isFilteringVerification))
        ? VerificationFilter(_isFilteringVerification ? _verified : null,
            _isFilteringUserRole ? _userRole : null)
        : null;
  }

  @override
  String get filterLabel => _appLocalizations.filterByVerification;

  @override
  void processInitialValue(VerificationFilter? filter) {
    _isFilteringUserRole = filter?.userRole != null;
    _userRole = filter?.userRole ?? Role.professional;
    _isFilteringVerification = filter?.verified != null;
    _verified = filter?.verified ?? true;
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return super.build(context);
  }
}
