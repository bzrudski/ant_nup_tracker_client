/*
 * location_picker.dart
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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:tuple/tuple.dart';

enum LocationPickerMode { locationAndRadius, locationOnly }

class LocationPickerView extends StatefulWidget {
  const LocationPickerView(
      {required this.locationPickerMode,
      this.initialLocation,
      this.initialRadius,
      Key? key})
      : super(key: key);

  final LocationPickerMode locationPickerMode;
  final LatLng? initialLocation;
  final double? initialRadius;

  @override
  _LocationPickerViewState createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  var _location = const LatLng(0, 0);
  var _radius = 0.0;
  late LocationPickerMode _locationPickerMode;
  late AppLocalizations _appLocalizations;
  late CameraPosition _cameraPosition;

  final zoomLevel = 10.0;

  // Camera movement from: https://stackoverflow.com/questions/62722671/google-maps-camera-position-updating-issues-in-flutter
  final _completer = Completer<GoogleMapController>();

  // final _mapController = MapController();

  final _globalKey = GlobalKey<FormState>();

  bool _mapFocused = true;

  @override
  void initState() {
    if (widget.initialLocation != null) _location = widget.initialLocation!;
    if (widget.initialRadius != null) _radius = widget.initialRadius!;

    _locationPickerMode = widget.locationPickerMode;
    _cameraPosition = CameraPosition(target: _location, zoom: zoomLevel);
    super.initState();
  }

  _LocationPickerViewState() {
    // if (initialLocation != null) _location = initialLocation;
    // if (initialRadius != null) _radius = initialRadius;
  }

  // void _placeLocationMarker(GoogleMapController mapController) {}

  void _updateLocation(LatLng newLoc) async {
    setState(() {
      _location = newLoc;
    });

    final controller = await _completer.future;
    // controller.animateCamera(CameraUpdate.newCameraPosition(
    //     CameraPosition(target: _location, zoom: zoomLevel)));
    controller.animateCamera(CameraUpdate.newLatLng(_location));
  }

  Widget _buildMap() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Focus(
          onFocusChange: (value) => _mapFocused = value,
          child: GoogleMap(
            // onMapCreated: _placeLocationMarker,
            initialCameraPosition: _cameraPosition,
            onMapCreated: (controller) {
              _completer.complete(controller);
            },
            gestureRecognizers: {
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer())
            },
            markers: {
              Marker(
                markerId: const MarkerId("location"),
                position: _location,
              ),
            },
            circles: {
              if (_locationPickerMode == LocationPickerMode.locationAndRadius)
                Circle(
                  circleId: const CircleId("locationCircle"),
                  center: _location,
                  radius: _radius * 1000,
                  strokeWidth: 2,
                  strokeColor: Colors.red,
                )
            },
            // onLongPress: _mapFocused ? null : _updateLocation,
            // onTap: (newLocation) {
            //   if (_mapFocused) {
            //     _updateLocation(newLocation);
            //   }
            //   else {
            //     _updateLocationFromFields();
            //     FocusManager.instance.primaryFocus?.unfocus();
            //   }
            // },
              onTap: _updateLocation,
              onLongPress: (_) {
                  _updateLocationFromFields();
                  FocusManager.instance.primaryFocus?.unfocus();
              },
            // mapType: MapType.terrain,
          ),
        ),
      ),
    );
  }

  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _longitudeFocusNode = FocusNode();
  final _latitudeFocusNode = FocusNode();

  Widget _buildLatitudeLongitudeRadiusFields() {
    _latitudeController.text = _location.latitude.toString();
    _longitudeController.text = _location.longitude.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        double widgetWidth = constraints.maxWidth;
        var widthFactor = 1.0;

        if (widgetWidth > 300) {
          widgetWidth = widgetWidth / 2 - 8;
          widthFactor = 0.45;
        }

        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            FractionallySizedBox(
              widthFactor: widthFactor,
              child: SizedBox(
                height: 80,
                // margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextFormField(
                  textInputAction: TextInputAction.next,
                  focusNode: _latitudeFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  decoration: InputDecoration(
                      labelText: _appLocalizations.latitude, filled: true),
                  inputFormatters: [
                    FilteringTextInputFormatter(RegExp("[\\-\\d\\.]"),
                        allow: true)
                  ],
                  controller: _latitudeController,
                  onEditingComplete: () async {
                    final newLatitude =
                        double.tryParse(_latitudeController.text);

                    if (newLatitude == null) return;

                    _latitudeFocusNode.nextFocus();

                    // setState(() => _setLatitude(newLatitude));
                    setState(_updateLocationFromFields);

                    final controller = await _completer.future;
                    // controller.animateCamera(CameraUpdate.newCameraPosition(
                    //     CameraPosition(target: _location, zoom: zoomLevel)));
                    controller.animateCamera(CameraUpdate.newLatLng(_location));
                  },
                  validator: (value) {
                    if (value == null) return null;

                    return double.tryParse(value) == null
                        ? _appLocalizations.invalidCoordinate
                        : null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: widthFactor,
              child: SizedBox(
                height: 80,
                // margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextFormField(
                  focusNode: _longitudeFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  decoration: InputDecoration(
                      labelText: _appLocalizations.longitude, filled: true),
                  inputFormatters: [
                    FilteringTextInputFormatter(RegExp("[\\-\\d\\.]"),
                        allow: true)
                  ],
                  controller: _longitudeController,
                  onEditingComplete: () async {
                    final newLongitude =
                        double.tryParse(_longitudeController.text);

                    if (newLongitude == null) return;

                    // setState(() => _setLongitude(newLongitude));
                    setState(_updateLocationFromFields);

                    _longitudeFocusNode.unfocus();

                    final controller = await _completer.future;
                    // controller.moveCamera(CameraUpdate.newLatLng(_location));
                    // controller.animateCamera(CameraUpdate.newCameraPosition(
                    //     CameraPosition(target: _location, zoom: zoomLevel)));
                    controller.animateCamera(CameraUpdate.newLatLng(_location));
                  },
                  validator: (value) {
                    if (value == null) return null;

                    return double.tryParse(value) == null
                        ? _appLocalizations.invalidCoordinate
                        : null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildRadiusStepper() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_appLocalizations.radiusDistanceDetail(_radius)),
          ToggleButtons(
            children: const [
              Icon(Icons.remove),
              Icon(Icons.add),
            ],
            isSelected: const [false, false],
            onPressed: (int selectedIndex) {
              setState(() {
                if (selectedIndex == 0 && _radius > 0) {
                  _radius -= 0.5;
                } else if (selectedIndex == 1) {
                  _radius += 0.5;
                }
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildCurrentLocationRow() {
    return ElevatedButton(
      onPressed: () async {
        final currentLocation = await getCurrentLocation();

        if (currentLocation != null) {
          _updateLocation(currentLocation);
        } else {
          final messageDialog = AlertDialog(
            title: Text(_appLocalizations.locationServicesDisabledHeader),
            content: Text(_appLocalizations.locationServicesDisabledContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_appLocalizations.ok),
              )
            ],
          );

          showDialog(context: context, builder: (_) => messageDialog);
        }
      },
      child: Text(_appLocalizations.getCurrentLocation),
    );
  }

  void _setCoordinates({double? latitude, double? longitude}) {
    final newLatitude = latitude ?? _location.latitude;
    final newLongitude = longitude ?? _location.longitude;

    _updateLocation(LatLng(newLatitude, newLongitude));
  }

  void _updateLocationFromFields() {
    final latitude = double.parse(_latitudeController.text);
    final longitude = double.parse(_longitudeController.text);

    setState(() => _setCoordinates(latitude: latitude, longitude: longitude));
  }

  // void _setLatitude(double newLatitude) {
  //   _location = LatLng(newLatitude, _location.longitude);
  // }
  //
  // void _setLongitude(double newLongitude) {
  //   _location = LatLng(_location.latitude, newLongitude);
  // }

  void _returnLocationAndRadius() {
    final resultTuple = Tuple2(_location, _radius);

    Navigator.of(context).pop(resultTuple);
  }

  void _returnLocation() {
    Navigator.of(context).pop(_location);
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        _updateLocationFromFields();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appLocalizations.changeLocationOnMap),
          actions: [
            IconButton(
                onPressed:
                    _locationPickerMode == LocationPickerMode.locationAndRadius
                        ? _returnLocationAndRadius
                        : _returnLocation,
                icon: const Icon(Icons.done))
          ],
        ),
        body: SafeArea(
          // top: false,
          // left: false,
          // right: false,
          child: Form(
            key: _globalKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildMap(),
                _buildLatitudeLongitudeRadiusFields(),
                if (_locationPickerMode == LocationPickerMode.locationAndRadius)
                  _buildRadiusStepper(),
                _buildCurrentLocationRow()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<LatLng?> getCurrentLocation() async {
  final _locationService = Location();
  var serviceEnabled = await _locationService.serviceEnabled();

  if (!serviceEnabled) {
    serviceEnabled = await _locationService.requestService();

    if (!serviceEnabled) return null;
  }

  var hasPermission = await _locationService.hasPermission();

  if (hasPermission == PermissionStatus.denied) {
    // hasPermission = await _locationService.requestPermission();
    //
    // if (hasPermission != PermissionStatus.granted) return null;
    return null;
  }

  final currentLocation = await _locationService.getLocation();

  return LatLng(currentLocation.latitude!, currentLocation.longitude!);
}
