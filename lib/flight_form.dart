/*
 * flight_form.dart
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
import 'dart:typed_data';

import 'package:ant_nup_tracker/exceptions.dart';
import 'package:ant_nup_tracker/flight_detail.dart';
import 'package:ant_nup_tracker/flights.dart';
import 'package:ant_nup_tracker/location_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:gallery_saver/gallery_saver.dart';
// import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tuple/tuple.dart';

import 'common_ui_elements.dart';
import 'dark_mode_theme_ext.dart';

// part 'flight_form.g.dart';

class FlightImagesRowWidget extends StatefulWidget {
  const FlightImagesRowWidget(
      {Key? key,
      this.images = const [],
      required this.onImageAdded,
      required this.onImageRemoved})
      : super(key: key);

  final Iterable<FlightFormImage> images;
  final void Function(NewImage, int) onImageAdded;
  final void Function(FlightFormImage, int) onImageRemoved;

  @override
  _FlightImagesRowWidgetState createState() => _FlightImagesRowWidgetState();
}

class _FlightImagesRowWidgetState extends State<FlightImagesRowWidget> {
  final List<FlightFormImage> images = [];
  late AppLocalizations _appLocalizations;

  final _animatedListKey = GlobalKey<AnimatedListState>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    images.clear();
    images.addAll(widget.images);
    // print("There are ${images.length} images...");
    super.initState();
  }

  Future<ImageSource?> _getImageSource() async {
    // if (kIsWeb) return OptionalImageSource.gallery;

    final useCamera = await ph.Permission.camera.isGranted;

    var isAndroid = false;
    // var isIOS = false;

    if (!kIsWeb) {
      isAndroid = Platform.isAndroid;
      // isIOS = Platform.isIOS;
    }

    final usePhotos = isAndroid
        ? await ph.Permission.storage.isGranted
        : await ph.Permission.photos.isGranted;

    // print("Will use camera: $useCamera");
    // print("Will use photos: $usePhotos");

    if (!usePhotos && !useCamera) {
      final choiceDialog = AlertDialog(
        title: Text(_appLocalizations.noImageSourcesHeader),
        content: Text(_appLocalizations.noImageSourcesContent),
        actions: [
          TextButton(
            child: Text(_appLocalizations.ok),
            onPressed: () => Navigator.of(context).pop(null),
          )
        ],
      );
      return await showDialog<ImageSource?>(
          context: context, builder: (context) => choiceDialog);
    }

    final choiceDialog = SimpleDialog(
      title: Text(_appLocalizations.chooseImageSource),
      children: [
        if (!kIsWeb && useCamera)
          SimpleDialogOption(
            child: Text(_appLocalizations.camera),
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        if (usePhotos)
          SimpleDialogOption(
            child: Text(_appLocalizations.gallery),
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        // SimpleDialogOption(
        //   child: Text(_appLocalizations.noImage),
        //   onPressed: () => Navigator.of(context).pop(OptionalImageSource.none),
        // ),
        SimpleDialogOption(
          child: Text(_appLocalizations.cancel),
          onPressed: () => Navigator.of(context).pop(null),
        )
      ],
    );

    return await showDialog<ImageSource?>(
        context: context, builder: (context) => choiceDialog);
  }

  Future<int?> addNewImage() async {
    final imageSource = await _getImageSource();
    final imagePicker = ImagePicker();
    final XFile? pickedImage;
    switch (imageSource) {
      case null: // Pressed cancel
        return null;
      case ImageSource.camera: // Get picture from the camera
        pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
        if (pickedImage == null) return null;

        // pickedImage.saveTo(pickedImage.path);
        await GallerySaver.saveImage(pickedImage.path);
        // print("Saved picture... $didSave");

        break;
      case ImageSource.gallery: // Get picture from user photos
        pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
        if (pickedImage == null) return null;
        break;
    }

    var imageBytes = await pickedImage.readAsBytes();

    var compressedImage =
        await FlutterImageCompress.compressWithList(imageBytes, quality: 90);

    final newImage = NewImage(pickedImage, compressedImage);

    // final newIndex = _intermediateData.addNewImage(newImage);

    final newIndex = images.length;

    images.insert(newIndex, newImage);

    _animatedListKey.currentState!.insertItem(newIndex);
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOutCirc);

    return newIndex;
  }

  Widget _loadImage(FlightFormImage image) {
    if (image is NewImage) {
      return Image.memory(
        image.imageBytes,
        fit: BoxFit.cover,
      );
    } else if (image is ExistingImage) {
      return CachedNetworkImage(
        imageUrl: image.image.toString(),
        progressIndicatorBuilder: (context, url, progress) =>
            CircularProgressIndicator(
          value: progress.progress,
        ),
        fit: BoxFit.cover,
      );
    } else {
      return Image(
        fit: BoxFit.cover,
        image: Theme.of(context).isDarkMode
            ? const AssetImage("assets/cartoon_ant/dark/cartoon_ant.png")
            : const AssetImage("assets/cartoon_ant/cartoon_ant.png"),
      );
    }
  }

  Widget _buildImageRow(int index, FlightFormImage image) {
    // print("Building row for image at index $index...");
    return SizedBox(
      // width: 480,
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Dismissible(
          direction: DismissDirection.vertical,
          key: ValueKey<int>(image.hashCode),
          onDismissed: (direction) {
            // final image = images[index];
            images.removeAt(index);
            _animatedListKey.currentState!.removeItem(
              index,
              (context, animation) =>
                  Container(), //_loadImage(image)//_buildImageRow(index, image),
            );
            widget.onImageRemoved(image, index);
          },
          background: Container(
            color: Colors.red,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_appLocalizations.delete),
                  const Icon(Icons.delete)
                ],
              ),
            ),
          ),
          child: _loadImage(image),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 180,
      height: 320,
      child: InkWell(
        onTap: () async {
          final index = await addNewImage();

          if (index != null) {
            widget.onImageAdded(images[index] as NewImage, index);
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [const Icon(Icons.add), Text(_appLocalizations.addImage)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    return SizedBox(
      height: 340,
      child: AnimatedList(
        key: _animatedListKey,
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        initialItemCount: images.length + 1,
        shrinkWrap: true,
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) =>
                index < images.length
                    ? _buildImageRow(index, images[index])
                    : _buildAddButton(),
      ),
    );
  }
}

class FlightFormScreen extends StatefulWidget {
  const FlightFormScreen({this.flight, this.currentLocation, Key? key})
      : super(key: key);

  final Flight? flight;
  final LatLng? currentLocation;

  @override
  _FlightFormScreenState createState() => _FlightFormScreenState();
}

class _FlightFormScreenState extends State<FlightFormScreen> {
  @override
  void initState() {
    super.initState();
    _flight = widget.flight;
    if (_flight != null) {
      _intermediateData = FlightFormIntermediateData.from(_flight!);
    } else {
      _intermediateData = FlightFormIntermediateData.blank(
        currentLocation: widget.currentLocation,
      );
      // getCurrentLocation().then((location) {
      //   if (location != null) {
      //     print(
      //         "Got current location ${stringFromLocation(location: location)}!");
      //     _intermediateData.location = location;
      //     print("Selected Location is ${_intermediateData.location}");
      //     // setState(() {});
      //   }
      // });
    }
    _genusController =
        TextEditingController(text: _intermediateData.genus?.name);
    _speciesController =
        TextEditingController(text: _intermediateData.species?.name);
    _speciesSuggestions = _intermediateData.genus?.species ?? [];
    // print(_flight);
  }

  late final Flight? _flight;
  // late final _FlightFormData _flightFormData;

  late TextStyle _labelStyle;
  // late TextStyle _headerStyle;
  late AppLocalizations _appLocalizations;

  final _animatedListKey = GlobalKey<AnimatedListState>();

  final _scrollController = ScrollController();

  TextStyle get _detailStyle => _labelStyle.apply(fontWeightDelta: 2);

  bool get isEditing => _flight != null;

  String get appBarTitle => isEditing
      ? AppLocalizations.of(context)!.editingFlightAppBar(_flight!.flightID)
      : AppLocalizations.of(context)!.newFlightAppBar;

  Future<void> Function() get doneAction => isEditing ? update : save;

  String get doneTooltip =>
      isEditing ? _appLocalizations.update : _appLocalizations.save;

  late FlightFormIntermediateData _intermediateData;

  // String _genus = "";
  // String _species = "";

  late TextEditingController _genusController;
  final _genusFocusNode = FocusNode();

  late TextEditingController _speciesController;
  final _speciesFocusNode = FocusNode();

  Iterable<Species> _speciesSuggestions = [];

  // ConfidenceLevels _confidenceLevel = ConfidenceLevels.low;
  // FlightSize _flightSize = FlightSize.manyQueens;
  // DateTime _date = DateTime.now();
  // TimeOfDay _time = TimeOfDay.now();
  // LatLng _location = LatLng(0.0, 0.0);
  // double _radius = 0.0;
  // bool _hasImage = false;
  // Uint8List? _image;

  // final _locationService = Location();

  // Future<LatLng?> _getCurrentLocation() async {
  //   var serviceEnabled = await _locationService.serviceEnabled();
  //
  //   if (!serviceEnabled) {
  //     // serviceEnabled = await
  //   }
  // }

  // Widget _buildTextLabelDetailRow({
  //   required String label,
  //   String? detail,
  //   TextStyle? detailStyle,
  // }) {
  //   var textStyle = detailStyle ?? _labelStyle.apply(fontWeightDelta: 2);
  //
  //   return Container(
  //     margin: EdgeInsets.symmetric(vertical: 12.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(child: Text(label, style: _labelStyle)),
  //         if (detail != null)
  //           Expanded(
  //               child: Text(
  //             detail,
  //             style: textStyle,
  //             textAlign: TextAlign.end,
  //           )),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildHeaderRow({required String label, TextStyle? headerStyle}) {
  //   var textStyle = headerStyle ?? _headerStyle;
  //
  //   return Column(
  //     children: [
  //       const Divider(
  //         thickness: 1,
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.only(top: 8.0),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(child: Text(label, style: textStyle)),
  //           ],
  //         ),
  //       ),
  //       const Divider(
  //         thickness: 1,
  //       )
  //     ],
  //   );
  // }

  Widget _buildTaxonomyRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        double widgetWidth = screenWidth;

        if (screenWidth >= 800) widgetWidth = screenWidth / 2 - 8;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          // runAlignment: WrapAlignment.spaceBetween,
          // alignment: WrapAlignment.spaceBetween,
          children: [
            SizedBox(
              width: widgetWidth,
              // margin: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 80,
                child: RawAutocomplete<Genus>(
                  textEditingController: _genusController,
                  focusNode: _genusFocusNode,
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 2.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) => InkWell(
                            onTap: () => onSelected(options.elementAt(index)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 16.0,
                              ),
                              child: Text(
                                options.elementAt(index).name,
                                style: Theme.of(context).textTheme.bodyText2!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  optionsBuilder: (value) {
                    // var genera = TaxonomyManager.shared.genera;

                    final genera = Genus.getAll();

                    // print("Building options.");

                    if (value.text.trim().isEmpty) return genera;

                    final results = genera
                        .where((element) => element.name
                            .toLowerCase()
                            .contains(value.text.toLowerCase()))
                        .toList(growable: false);

                    results.sort((s1, s2) {
                      final positionBasedOrdering = s1.name
                          .toLowerCase()
                          .indexOf(value.text.toLowerCase())
                          .compareTo(s2.name
                              .toLowerCase()
                              .indexOf(value.text.toLowerCase()));
                      return positionBasedOrdering != 0
                          ? positionBasedOrdering
                          : s1.name.compareTo(s2.name);
                    });

                    // print("There are ${results.length} results");

                    return results;
                  },
                  onSelected: (option) {
                    // print("Selected $option");

                    // setState(() {
                    // assert(TaxonomyManager.shared.genera.contains(option));
                    _intermediateData.genus = option;
                    _speciesSuggestions = option.species;
                    // print(_speciesSuggestions);
                    setState(() {});
                    // setState(() => _genus = option);
                    // setState(() => _flightFormData.updateGenus(option));

                    // print("Flight form genus is now ${_flightFormData.genus}");
                    // });
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    // print("building the form field for genus");

                    // textEditingController.text = _genus;

                    // textEditingController.text = _genus;
                    //
                    // _globalKey.currentState!.save();

                    // print("Assigned the default value");

                    return TextFormField(
                      // initialValue: _genus,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        labelText: _appLocalizations.genus,
                        filled: true,
                      ),
                      focusNode: focusNode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _appLocalizations.emptyGenus;
                        }

                        if (Genus.getByName(value) == null) {
                          return _appLocalizations.invalidGenus;
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onSaved: (value) {
                        // print("Genus field callback: saved $value");
                        if (value == null || value.isEmpty) return;

                        final newGenus = Genus.getByName(value);
                        _intermediateData.genus = newGenus;

                        if (newGenus != null) {
                          _speciesSuggestions = newGenus.species;
                        }
                      },
                      textCapitalization: TextCapitalization.words,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: widgetWidth,
              // margin: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 80,
                child: RawAutocomplete<Species>(
                  textEditingController: _speciesController,
                  focusNode: _speciesFocusNode,
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 2.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) => InkWell(
                            onTap: () => onSelected(options.elementAt(index)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 16.0,
                              ),
                              child: Text(
                                options.elementAt(index).name,
                                style: Theme.of(context).textTheme.bodyText2!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  displayStringForOption: (option) => option.name,
                  optionsBuilder: (value) {
                    final suggestions =
                        _speciesSuggestions.toList(growable: true);

                    if (value.text.isEmpty) return suggestions;

                    suggestions
                      ..retainWhere((element) => element.name
                          .toLowerCase()
                          .contains(value.text.toLowerCase()))
                      ..sort((s1, s2) {
                        final comparisonResult = s1.name
                            .toLowerCase()
                            .indexOf(value.text.toLowerCase())
                            .compareTo(s2.name
                                .toLowerCase()
                                .indexOf(value.text.toLowerCase()));

                        return comparisonResult != 0
                            ? comparisonResult
                            : s1.name.compareTo(s2.name);
                      });

                    return suggestions;
                  },
                  onSelected: (option) {
                    _intermediateData.species = option;
                    // print("Option is now $option, having name: ${option.name}");
                    setState(() {});
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    // print("Controller has value ${textEditingController.text}");
                    return TextFormField(
                      // initialValue: _genus,
                      enabled: _intermediateData.genus != null,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        labelText: _appLocalizations.species,
                        filled: true,
                      ),
                      focusNode: focusNode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _appLocalizations.emptySpecies;
                        }

                        if (_intermediateData.genus == null) {
                          return _appLocalizations.emptyGenus;
                        }

                        if (!_intermediateData.genus!.species
                            .map((e) => e.name)
                            .contains(value)) {
                          return _appLocalizations.invalidSpecies;
                        }

                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onSaved: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            _intermediateData.genus == null) return;

                        _intermediateData.species = Species.getByGenusAndName(
                            _intermediateData.genus!, value);
                      },
                      textCapitalization: TextCapitalization.none,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String getConfidenceString(ConfidenceLevels level) {
    switch (level) {
      case ConfidenceLevels.low:
        return _appLocalizations.lowConfidence;
      case ConfidenceLevels.high:
        return _appLocalizations.highConfidence;
    }
  }

  String getSizeString(FlightSize size) {
    switch (size) {
      case FlightSize.manyQueens:
        return _appLocalizations.manyQueens;
      case FlightSize.singleQueen:
        return _appLocalizations.singleQueen;
    }
  }

  Widget _buildFlightSizeRow() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: FormField<FlightSize>(
          onSaved: (flightSize) => _intermediateData.flightSize = flightSize!,
          initialValue: _intermediateData.flightSize,
          builder: (state) => LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final screenWidth = constraints.maxWidth;

              double widgetWidth = screenWidth;

              if (screenWidth >= 800) widgetWidth = screenWidth / 2 - 8;

              return Wrap(
                runAlignment: WrapAlignment.spaceBetween,
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: widgetWidth,
                    child: Text(
                      _appLocalizations.flightSize,
                      style: _labelStyle,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: ToggleButtons(
                      constraints:
                          BoxConstraints.expand(width: widgetWidth / 2 - 16),
                      isSelected: [
                        for (final s in FlightSize.values) state.value == s
                      ],
                      children: [
                        for (final s in FlightSize.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(getSizeString(s)),
                          )
                      ],
                      onPressed: (int selectedIndex) {
                        state.didChange(FlightSize.values[selectedIndex]);
                        // setState(() {
                        //   // _flightFormData.flightSize =
                        //   //     FlightSize.values[selectedIndex];
                        //   // _flightSize = FlightSize.values[selectedIndex];
                        // });
                        // print("Now selected size: ${state.value}");
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ));
  }

  Widget _buildSpeciesConfidenceRow() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final screenWidth = constraints.maxWidth;

            double widgetWidth = screenWidth;

            if (screenWidth >= 800) widgetWidth = screenWidth / 2 - 8;

            return Wrap(
              runAlignment: WrapAlignment.spaceBetween,
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: widgetWidth,
                  child: Text(
                    _appLocalizations.speciesConfidence,
                    style: _labelStyle,
                    textAlign: TextAlign.start,
                  ),
                ),
                FormField<ConfidenceLevels>(
                  onSaved: (confidenceValue) =>
                      _intermediateData.confidenceLevel = confidenceValue!,
                  initialValue: _intermediateData.confidenceLevel,
                  builder: (state) => Container(
                    alignment: Alignment.center,
                    child: ToggleButtons(
                      constraints:
                          BoxConstraints.expand(width: widgetWidth / 2 - 16),
                      isSelected: [
                        for (final c in ConfidenceLevels.values)
                          // _flightFormData.confidenceLevel == c
                          state.value == c
                      ],
                      children: [
                        for (final c in ConfidenceLevels.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(getConfidenceString(c)),
                          )
                      ],
                      onPressed: (int selectedIndex) {
                        // setState(() {
                        //   _flightFormData.confidenceLevel =
                        //       ConfidenceLevels.values[selectedIndex];
                        // });
                        state.didChange(ConfidenceLevels.values[selectedIndex]);
                        // print("Now selected confidence: ${state.value}");
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ));
  }

  final _earliestDate = DateTime.now().subtract(const Duration(days: 365 * 25));
  final _latestDate = DateTime.now();

  Widget _buildDateAndTimeRow() {
    final currentLocale = _appLocalizations.localeName;
    // final textStyle = _labelStyle.apply(fontWeightDelta: 2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FormField<TimeOfDay>(
          onSaved: (value) => _intermediateData.time = value!,
          initialValue: _intermediateData.time,
          builder: (state) => Row(
            children: [
              Text(
                // DateFormat.jm(currentLocale).format(state.value!),
                // formatTimeOfDay(state.value!),
                state.value!.format(context),
                style: _detailStyle,
                // textAlign: TextAlign.end,
              ),
              IconButton(
                onPressed: () async {
                  final newTime = await showTimePicker(
                      context: context,
                      initialTime: state.value ?? TimeOfDay.now());

                  if (newTime != null) state.didChange(newTime);
                  setState(() {
                    // _flightFormData.updateTime(newTime);
                  });
                },
                icon: const Icon(Icons.edit),
                tooltip: _appLocalizations.edit,
              )
            ],
          ),
        ),
        FormField<DateTime>(
          initialValue: _intermediateData.date,
          onSaved: (date) => _intermediateData.date = date!,
          builder: (state) => Row(
            children: [
              Text(
                DateFormat.yMMMd(currentLocale).format(state.value!),
                style: _detailStyle,
                // textAlign: TextAlign.end,
              ),
              IconButton(
                onPressed: () async {
                  final newDate = await showDatePicker(
                      context: context,
                      initialDate: state.value!,
                      firstDate: _earliestDate,
                      lastDate: _latestDate);

                  if (newDate != null) {
                    setState(() {
                      state.didChange(newDate);
                      // _flightFormData.updateDate(newDate);
                    });
                  }
                },
                icon: const Icon(Icons.edit),
                tooltip: _appLocalizations.edit,
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFullLocationRow() {
    // var locationString = _buildLocationString(
    //     latitude: _location.latitude,
    //     longitude: _location.longitude,
    //     radius: _radius);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: FormField<Tuple2<LatLng, double>>(
        onSaved: (resultTuple) {
          final newLocation = resultTuple!.item1;
          final newRadius = resultTuple.item2;

          _intermediateData.location = newLocation;
          _intermediateData.radius = newRadius;
        },
        initialValue:
            Tuple2(_intermediateData.location, _intermediateData.radius),
        builder: (state) => Row(
          children: [
            Expanded(
                child: Text(
              _buildLocationString(
                latitude: state.value!.item1.latitude,
                longitude: state.value!.item1.longitude,
                radius: state.value!.item2,
              ),
              style: _detailStyle,
            )),
            IconButton(
              onPressed: () async {
                final currentLocation = await getCurrentLocation();

                if (currentLocation != null) {
                  _intermediateData.location = currentLocation;
                  state.didChange(Tuple2(currentLocation, 0));
                }
              },
              icon: const Icon(Icons.my_location),
              tooltip: _appLocalizations.getCurrentLocation,
            ),
            IconButton(
              onPressed: () async {
                final newLocationAndRadius = await Navigator.of(context)
                    .push<Tuple2<LatLng, double>>(MaterialPageRoute(
                        builder: (context) => LocationPickerView(
                              locationPickerMode:
                                  LocationPickerMode.locationAndRadius,
                              initialLocation: state.value!.item1,
                              initialRadius: state.value!.item2,
                            ),
                        fullscreenDialog: true));

                if (newLocationAndRadius == null) return;

                // final newLocation = newLocationAndRadius.item1;
                // final newRadius = newLocationAndRadius.item2;

                state.didChange(newLocationAndRadius);

                _intermediateData.location = newLocationAndRadius.item1;
                _intermediateData.radius = newLocationAndRadius.item2;

                setState(() {
                  // _flightFormData.updateLocation(newLocation);
                  // _flightFormData.radius = newRadius;
                });
              },
              icon: const Icon(Icons.edit),
              tooltip: _appLocalizations.edit,
            )
          ],
        ),
      ),
    );
  }

  String _buildLocationString(
      {required double latitude,
      required double longitude,
      required double radius}) {
    final locationStringBuffer = StringBuffer();
    locationStringBuffer.write(stringFromCoordinates(
        latitude: latitude, longitude: longitude, precision: 2));
    locationStringBuffer.write(" \u00b1 ");
    locationStringBuffer.write(_appLocalizations.radiusDistanceDetail(radius));
    return locationStringBuffer.toString();
  }

  // Widget _buildImageToggleRow() {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 12),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(child: Text(_appLocalizations.uploadImage)),
  //         FormField<bool>(
  //           onSaved: (hasImage) => _hasImage = hasImage!,
  //           initialValue: _hasImage,
  //           builder: (state) => Switch(
  //             value: state.value!,
  //             onChanged: (value) async {
  //               // final scrollExtent = _scrollController.position.maxScrollExtent;
  //               state.didChange(value);
  //
  //               setState(() {
  //                 _hasImage = value;
  //               });
  //
  //               // print("Scrolling...");
  //               // print("Max scroll extent was $scrollExtent");
  //               print(
  //                   "Max extent is now ${_scrollController.position.maxScrollExtent}");
  //               // print("Min extent is now ${_scrollController.position.minScrollExtent}");
  //               // // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  //               _scrollController.animateTo(
  //                   _scrollController.position.maxScrollExtent,
  //                   duration: const Duration(milliseconds: 500),
  //                   curve: Curves.easeOutCirc);
  //               //
  //               // _lastScrollPosition = scrollExtent;
  //             },
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  // Widget _loadImage(FlightFormImage image) {
  //   if (image is NewImage) {
  //     return Image.memory(image.imageBytes);
  //   } else if (image is ExistingImage) {
  //     return CachedNetworkImage(
  //       imageUrl: image.image.toString(),
  //       progressIndicatorBuilder: (context, url, progress) =>
  //           CircularProgressIndicator(
  //         value: progress.progress,
  //       ),
  //     );
  //   } else {
  //     return Image(
  //       image: Theme.of(context).isDarkMode
  //           ? const AssetImage("assets/cartoon_ant/dark/cartoon_ant.png")
  //           : const AssetImage("assets/cartoon_ant/cartoon_ant.png"),
  //     );
  //   }
  // }

  // Widget _buildImageRow(int index, FlightFormImage image) {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Dismissible(
  //       key: ValueKey<int>(index),
  //       onDismissed: (direction) {
  //         _intermediateData.removeImage(image, index);
  //         _animatedListKey.currentState!.removeItem(
  //             index, (context, animation) => _buildImageRow(index, image));
  //       },
  //       background: Container(
  //         color: Colors.red,
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.end,
  //           children: [
  //             Text(_appLocalizations.delete),
  //             const Icon(Icons.delete)
  //           ],
  //         ),
  //       ),
  //       child: _loadImage(image),
  //     ),
  //   );
  // }
  //
  // Widget _buildAddImageRow() {
  //   return Center(
  //     child: IconButton(
  //       icon: const Icon(Icons.add),
  //       tooltip: _appLocalizations.addImage,
  //       onPressed: addNewImage,
  //     ),
  //   );
  // }

  Future<void> addNewImage() async {
    final imageSource = await _getImageSource();
    final imagePicker = ImagePicker();
    final XFile? pickedImage;
    switch (imageSource) {
      case null: // Pressed cancel
        return;
      case ImageSource.camera: // Get picture from the camera
        pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
        if (pickedImage == null) return;
        break;
      case ImageSource.gallery: // Get picture from user photos
        pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
        if (pickedImage == null) return;
        break;
    }

    var imageBytes = await pickedImage.readAsBytes();

    var compressedImage =
        await FlutterImageCompress.compressWithList(imageBytes, quality: 90);

    final newImage = NewImage(pickedImage, compressedImage);

    final newIndex = _intermediateData.addNewImage(newImage);

    _animatedListKey.currentState!.insertItem(newIndex);
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOutCirc);

//     state.didChange(imageBytes);
// // state.
//     print("State has been updated");
//     print("State now has length: ${state.value?.length ?? 0}");
//     _image = imageBytes;
// await _flightFormData.updateImage(pickedImage);
//     setState(() {});
  }

  // Widget _buildImageRow(int index, FlightFormImage? image) {
  //   return FormField<FlightFormImage>(
  //     initialValue: image,
  //     validator: (value) {
  //       // if (_hasImage &&
  //       //     (_flight != null && _flight!.imageUrl == null || _flight == null) &&
  //       //     value == null) return _appLocalizations.pleaseSelectImage;
  //       if (value == null) return _appLocalizations.pleaseSelectImage;
  //     },
  //     autovalidateMode: AutovalidateMode.always,
  //     // onSaved: (value) => _image = value,
  //     onSaved: (value) {
  //       if (value is NewImage) {
  //         _intermediateData.addNewImage(value);
  //       }
  //     },
  //     builder: (state) => Column(
  //       children: [
  //         Dismissible(
  //           key: ValueKey<int>(index),
  //           background: Container(
  //             color: Colors.red,
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.end,
  //               children: [
  //                 Text(_appLocalizations.delete),
  //                 const Icon(Icons.delete)
  //               ],
  //             ),
  //           ),
  //           onDismissed: (direction) => _intermediateData.removeImage(index),
  //           child: InkWell(
  //             child: _getImageContent(state),
  //         //     onTap: image is ExistingImage
  //         //         ? null
  //         //         : () async {
  //         //             final imageSource = await _getImageSource();
  //         //             final imagePicker = ImagePicker();
  //         //             final XFile? pickedImage;
  //         //
  //         //             switch (imageSource) {
  //         //               case null: // Pressed cancel
  //         //                 return;
  //         //               case ImageSource.camera: // Get picture from the camera
  //         //                 pickedImage = await imagePicker.pickImage(
  //         //                     source: ImageSource.camera);
  //         //                 if (pickedImage == null) return;
  //         //                 break;
  //         //               case ImageSource
  //         //                   .gallery: // Get picture from user photos
  //         //                 pickedImage = await imagePicker.pickImage(
  //         //                     source: ImageSource.gallery);
  //         //                 if (pickedImage == null) return;
  //         //                 break;
  //         //               // case ImageSource.none:
  //         //               //   pickedImage = null;
  //         //               //   break;
  //         //             }
  //         //
  //         //             var imageBytes = await pickedImage.readAsBytes();
  //         //             state.didChange(imageBytes);
  //         //
  //         //             // state.
  //         //
  //         //             print("State has been updated");
  //         //
  //         //             print(
  //         //                 "State now has length: ${state.value?.length ?? 0}");
  //         //
  //         //             _image = imageBytes;
  //         //
  //         //             // await _flightFormData.updateImage(pickedImage);
  //         //
  //         //             setState(() {});
  //         //           },
  //           ),
  //         ),
  //         if (state.hasError)
  //           Text(
  //             state.errorText!,
  //             style: Theme.of(context)
  //                 .textTheme
  //                 .bodyText1!
  //                 .apply(color: Colors.red),
  //             textAlign: TextAlign.start,
  //           )
  //       ],
  //     ),
  //   );
  // }

  Future<ImageSource?> _getImageSource() async {
    // if (kIsWeb) return OptionalImageSource.gallery;

    final useCamera = await ph.Permission.camera.status;
    final usePhotos = await ph.Permission.storage.status;

    // print("Will use camera: $useCamera");
    // print("Will use photos: $usePhotos");

    final choiceDialog = SimpleDialog(
      title: Text(_appLocalizations.chooseImageSource),
      children: [
        if (!kIsWeb && useCamera == ph.PermissionStatus.granted)
          SimpleDialogOption(
            child: Text(_appLocalizations.camera),
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        if (usePhotos == ph.PermissionStatus.granted)
          SimpleDialogOption(
            child: Text(_appLocalizations.gallery),
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        // SimpleDialogOption(
        //   child: Text(_appLocalizations.noImage),
        //   onPressed: () => Navigator.of(context).pop(OptionalImageSource.none),
        // ),
        SimpleDialogOption(
          child: Text(_appLocalizations.cancel),
          onPressed: () => Navigator.of(context).pop(null),
        )
      ],
    );

    return await showDialog<ImageSource?>(
        context: context, builder: (context) => choiceDialog);
  }

  // Image _getImageContent(FormFieldState<Uint8List> state) {
  //   print("State value for image has length: ${state.value?.length ?? 0}");
  //   if (_hasImage && state.value == null && _flight?.imageUrl != null) {
  //     return Image.network(_flight!.imageUrl!.toString());
  //   } else if (state.value != null) {
  //     // return Image.memory(_flightFormData.image!);
  //     return Image.memory(state.value!);
  //   } else {
  //     return const Image(
  //         image: AssetImage("assets/cartoon_ant/cartoon_ant.png"));
  //   }
  // }

  final _globalKey = GlobalKey<FormState>();

  // Widget _buildFormBody() {
  //   _appLocalizations = AppLocalizations.of(context)!;
  //   // var italicStyle =
  //   //     _labelStyle.apply(fontStyle: FontStyle.italic, fontWeightDelta: 2);
  //
  //   return Form(
  //     key: _globalKey,
  //     child: ListView(
  //       children: [
  //         _buildHeaderRow(label: _appLocalizations.taxonomy),
  //         _buildTaxonomyRow(),
  //         _buildSpeciesConfidenceRow(),
  //         _buildHeaderRow(label: _appLocalizations.flightSizeHeader),
  //         _buildFlightSizeRow(),
  //         _buildHeaderRow(label: _appLocalizations.dateAndTimeOfFlight),
  //         _buildDateAndTimeRow(),
  //         _buildHeaderRow(label: _appLocalizations.flightLocationHeader),
  //         _buildFullLocationRow(),
  //         _buildHeaderRow(label: _appLocalizations.uploadImage),
  //         _buildImageToggleRow(),
  //         if (_hasImage) _buildImageRow()
  //       ],
  //       controller: _scrollController,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);
    // _headerStyle =
    //     Theme.of(context).textTheme.bodyText2!.apply(fontWeightDelta: 2);
    _appLocalizations = AppLocalizations.of(context)!;

    return Form(
      key: _globalKey,
      child: GestureDetector(
        onTap: () {
          _globalKey.currentState!.save();
          FocusManager.instance.primaryFocus?.unfocus();
          // setState(() {});
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: [
              IconButton(
                onPressed: doneAction,
                icon: const Icon(Icons.done),
                tooltip: doneTooltip,
              )
            ],
          ),
          body: SafeArea(
            child: AnimatedList(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              key: _animatedListKey,
              itemBuilder: (context, index, animation) {
                final row = _intermediateData.getRowForIndex(index);
                return SizeTransition(
                    sizeFactor:
                        animation.drive(CurveTween(curve: Curves.easeIn)),
                    child: _buildRow(row: row, index: index));
              },
              initialItemCount: _intermediateData.rowCount,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> save() async {
    if (_globalKey.currentState!.validate()) {
      _globalKey.currentState!.save();
    } else {
      return;
    }
    // print("Sending... eventually");

    final timezone = latLngToTimezoneString(_intermediateData.location.latitude,
        _intermediateData.location.longitude);
    final timeZoneLocation = tz.getLocation(timezone);

    final dateOfFlight = tz.TZDateTime(
      timeZoneLocation,
      _intermediateData.date.year,
      _intermediateData.date.month,
      _intermediateData.date.day,
      _intermediateData.time.hour,
      _intermediateData.time.minute,
    );

    // if ()

    // final dateOfFlight = DateTime(
    //     _intermediateData.date.year,
    //     _intermediateData.date.month,
    //     _intermediateData.date.day,
    //     _intermediateData.time.hour,
    //     _intermediateData.time.minute);

    // final genus = Genus.get(_intermediateData.genus!);
    // final taxonomy = Species.get(genus, _intermediateData.species!);

    final taxonomy = _intermediateData.species!;

    final flightFormData = FlightFormData(
      taxonomy: taxonomy,
      confidenceLevel: _intermediateData.confidenceLevel,
      flightSize: _intermediateData.flightSize,
      dateOfFlight: dateOfFlight,
      location: _intermediateData.location,
      radius: _intermediateData.radius,
      // hasImage: _hasImage,
      // image: _image,
    );

    try {
      showDialog(
          context: context,
          builder: (context) => _buildLoadingDialog(),
          barrierDismissible: false);
      await addNewFlight(
          flightFormData, _intermediateData.newImages.map((e) => e.imageFile));
      Navigator.of(context).pop();
      Navigator.of(context).pop(true);
    } on LocalisableException catch (exception) {
      Navigator.of(context).pop();
      showDialog(
          context: context,
          builder: (context) => _buildExceptionDialog(exception));
    }
  }

  Future<void> update() async {
    if (_globalKey.currentState!.validate()) {
      _globalKey.currentState!.save();
    } else {
      return;
    }
    // print("Sending... eventually");

    // if ()
    final timezone = latLngToTimezoneString(_intermediateData.location.latitude,
        _intermediateData.location.longitude);
    final timeZoneLocation = tz.getLocation(timezone);

    final dateOfFlight = tz.TZDateTime(
      timeZoneLocation,
      _intermediateData.date.year,
      _intermediateData.date.month,
      _intermediateData.date.day,
      _intermediateData.time.hour,
      _intermediateData.time.minute,
    );

    // final dateOfFlight = DateTime(
    //     _intermediateData.date.year,
    //     _intermediateData.date.month,
    //     _intermediateData.date.day,
    //     _intermediateData.time.hour,
    //     _intermediateData.time.minute);

    // final genus = Genus.get(_intermediateData.genus);
    // final taxonomy = Species.get(genus, _intermediateData.species);

    final taxonomy = _intermediateData.species!;

    final flightFormData = FlightFormData(
      taxonomy: taxonomy,
      confidenceLevel: _intermediateData.confidenceLevel,
      flightSize: _intermediateData.flightSize,
      dateOfFlight: dateOfFlight,
      location: _intermediateData.location,
      radius: _intermediateData.radius,
      // hasImage: _hasImage,
      // image: _image,
    );

    final originalFlightData = FlightFormIntermediateData.from(_flight!);
    final updatedFlightData = _intermediateData;
    try {
      showDialog(
        context: context,
        builder: (context) => _buildLoadingDialog(),
        barrierDismissible: false,
      );

      var shouldReload = false;

      final updateMethod = FlightFormIntermediateData.getUpdateMethod(
          originalFlightData, updatedFlightData);

      if (updateMethod != FlightUpdateMethod.none) {
        // print("Not equal! Printing each field...");
        // print(
        //     "Genus: ${originalFlightData.genus} vs. ${updatedFlightData.genus}");
        // print(
        //     "Species: ${originalFlightData.species} vs. ${updatedFlightData.species}");
        // print(
        //     "Confidence: ${originalFlightData.confidenceLevel} vs. ${updatedFlightData.confidenceLevel}");
        // print(
        //     "Size: ${originalFlightData.flightSize} vs. ${updatedFlightData.flightSize}");
        // print("Date: ${originalFlightData.date} vs. ${updatedFlightData.date}");
        // print("Time: ${originalFlightData.time} vs. ${updatedFlightData.time}");
        // print(
        //     "Location: ${originalFlightData.location} vs. ${updatedFlightData.location}");
        // print(
        //     "Radius: ${originalFlightData.radius} vs. ${updatedFlightData.radius}");
        // print(
        //     "Images: ${originalFlightData.images} vs. ${updatedFlightData.images}");
        await updateFlight(
            _flight!.flightID,
            flightFormData,
            _intermediateData.newImages.map((image) => image.imageFile),
            _intermediateData.removedImages,
            updateMethod);
        shouldReload = true;
      }
      Navigator.of(context).pop(shouldReload);
      Navigator.of(context).pop(shouldReload);
    } on LocalisableException catch (exception) {
      Navigator.of(context).pop();
      showDialog(
          context: context,
          builder: (context) => _buildExceptionDialog(exception));
    }
  }

  AlertDialog _buildLoadingDialog() => AlertDialog(
        title: Text(_appLocalizations.uploadingFlight),
        content: const LinearProgressIndicator(),
      );

  AlertDialog _buildExceptionDialog(LocalisableException exception) {
    return AlertDialog(
      title: Text(exception.getLocalisedName(context)),
      content: Text(exception.getLocalisedDescription(context)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_appLocalizations.ok),
        )
      ],
    );
  }

  String getStringForHeader(_FlightFormHeaders header) {
    switch (header) {
      case _FlightFormHeaders.taxonomy:
        return _appLocalizations.taxonomy;
      case _FlightFormHeaders.flightSize:
        return _appLocalizations.flightSizeHeader;
      case _FlightFormHeaders.dateAndTimeOfFlight:
        return _appLocalizations.dateAndTimeOfFlight;
      case _FlightFormHeaders.flightLocation:
        return _appLocalizations.flightLocationHeader;
      case _FlightFormHeaders.images:
        return _appLocalizations.imagesHeader;
    }
  }

  Widget _buildRow({required _FlightFormRow row, required int index}) {
    if (row is _HeaderRow) {
      final text = getStringForHeader(row.content);
      return HeaderRow(label: text);
    }

    if (row is _TaxonomyRow) {
      return _buildTaxonomyRow();
    }

    if (row is _DateAndTimeRow) {
      return _buildDateAndTimeRow();
    }

    if (row is _FlightSizeRow) {
      return _buildFlightSizeRow();
    }

    if (row is _ConfidenceRow) {
      return _buildSpeciesConfidenceRow();
    }

    if (row is _LocationRow) {
      return _buildFullLocationRow();
    }

    // if (row is _ImageRow) {
    //   return _buildImageRow(index, row.content);
    // }

    if (row is _ImagesRow) {
      return FlightImagesRowWidget(
          images: row.content,
          onImageAdded: (image, index) {
            _intermediateData.addNewImage(image);
          },
          onImageRemoved: (image, index) {
            _intermediateData.removeImage(image, index);
          });
    }

    // if (row is _IconDataRow) {
    //   return _buildAddImageRow();
    // }

    return Container();
  }
}

enum _FlightFormHeaders {
  taxonomy,
  flightSize,
  dateAndTimeOfFlight,
  flightLocation,
  images
}

// enum _FlightFormRowTypes {
//   taxonomyHeader,
//   taxonomyRow,
//   confidenceRow,
//   flightSizeHeader,
//   flightSizeRow,
//   dateAndTimeRow,
//   locationRowHeader,
//   locationRow,
//   imagesHeader,
//   addImageRow,
//   imageRow
// }

abstract class _FlightFormRow<T> {
  T get content;

  // set content(T newContent);
}

class _HeaderRow implements _FlightFormRow<_FlightFormHeaders> {
  const _HeaderRow(this._content);

  final _FlightFormHeaders _content;

  @override
  _FlightFormHeaders get content => _content;
}

class _TaxonomyRow implements _FlightFormRow<Tuple2<Genus?, Species?>> {
  _TaxonomyRow(this._genus, this._species);

  Genus? _genus;
  Species? _species;

  void setGenus(Genus? newGenus) => _genus = newGenus;
  void setSpecies(Species? newSpecies) => _species = newSpecies;

  @override
  Tuple2<Genus?, Species?> get content => Tuple2(_genus, _species);
}

class _ConfidenceRow implements _FlightFormRow<ConfidenceLevels> {
  _ConfidenceRow(this.content);

  // ConfidenceLevels _confidenceLevel;

  @override
  ConfidenceLevels content;
}

class _FlightSizeRow implements _FlightFormRow<FlightSize> {
  // _FlightSizeRow(this._flightSize);
  //
  // FlightSize _flightSize;
  //
  // @override
  // FlightSize get content => _flightSize;

  _FlightSizeRow(this.content);

  @override
  FlightSize content;
}

class _DateAndTimeRow implements _FlightFormRow<Tuple2<DateTime, TimeOfDay>> {
  _DateAndTimeRow(this._date, this._time);

  DateTime _date;
  TimeOfDay _time;

  void setDate(DateTime newDate) => _date = newDate;
  void setTime(TimeOfDay newTime) => _time = newTime;

  @override
  Tuple2<DateTime, TimeOfDay> get content => Tuple2(_date, _time);
}

class _LocationRow implements _FlightFormRow<Tuple2<LatLng, double>> {
  _LocationRow(this._location, this._radius);

  LatLng _location;
  double _radius;

  void setLocation(LatLng newLocation) => _location = newLocation;
  void setRadius(double newRadius) => _radius = newRadius;

  @override
  Tuple2<LatLng, double> get content => Tuple2(_location, _radius);
}

// class _ImageRow implements _FlightFormRow<Tuple2<int, FlightFormImage>> {
//   _ImageRow(this._imageIndex, this._image);
//
//   FlightFormImage _image;
//   int _imageIndex;
//
//   @override
//   Tuple2<int, FlightFormImage> get content => Tuple2(_imageIndex, _image);
// }

class _ImagesRow implements _FlightFormRow<Iterable<FlightFormImage>> {
  _ImagesRow(this.content);

  @override
  Iterable<FlightFormImage> content;
}

// class _ImageRow implements _FlightFormRow<FlightFormImage> {
//   _ImageRow(this.content);
//
//   @override
//   FlightFormImage content;
// }

class _IconDataRow implements _FlightFormRow<IconData> {
  const _IconDataRow(this._content);

  final IconData _content;

  @override
  IconData get content => _content;
}

extension Base64EncodeJson on PickedFile {
  Future<String> toBase64Encoded() async => base64Encode(await readAsBytes());
}

Future<String?> base64EncodeImage(PickedFile? image) async =>
    image != null ? base64Encode(await image.readAsBytes()) : null;

String? base64EncodeImageBytes(Uint8List? imageBytes) =>
    imageBytes != null ? base64Encode(imageBytes) : null;

abstract class FlightFormImage {}

class ExistingImage implements FlightFormImage {
  final Uri image;
  final int imageId;

  const ExistingImage(this.imageId, this.image);

  @override
  bool operator ==(Object other) {
    return other is ExistingImage &&
        image == other.image &&
        imageId == other.imageId;
  }

  @override
  int get hashCode => image.hashCode + imageId.hashCode;
}

class NewImage implements FlightFormImage {
  final XFile imageFile;
  final Uint8List imageBytes;

  const NewImage(this.imageFile, this.imageBytes);

  @override
  bool operator ==(Object other) {
    return other is NewImage &&
        other.imageFile == imageFile &&
        other.imageBytes == imageBytes;
  }

  @override
  int get hashCode => imageFile.hashCode + imageBytes.hashCode;
}

class FlightFormIntermediateData {
  Genus? get genus => _taxonomyRow.content.item1;
  Species? get species => _taxonomyRow.content.item2;
  ConfidenceLevels get confidenceLevel => _confidenceRow.content;
  FlightSize get flightSize => _flightSizeRow.content;
  DateTime get date => _dateAndTimeRow.content.item1;
  TimeOfDay get time => _dateAndTimeRow.content.item2;
  LatLng get location => _locationRow.content.item1;
  double get radius => _locationRow.content.item2;

  tz.TZDateTime get dateAndTimeOfFlight {
    final timezone =
        latLngToTimezoneString(location.latitude, location.longitude);
    final timeZoneLocation = tz.getLocation(timezone);

    return tz.TZDateTime(
      timeZoneLocation,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  get rowCount => _flightFormSkeleton.length;

  set genus(Genus? newGenus) => _taxonomyRow.setGenus(newGenus);
  set species(Species? newSpecies) => _taxonomyRow.setSpecies(newSpecies);
  set confidenceLevel(ConfidenceLevels newConfidence) =>
      _confidenceRow.content = newConfidence;
  set flightSize(FlightSize newFlightSize) =>
      _flightSizeRow.content = newFlightSize;
  set date(DateTime newDate) => _dateAndTimeRow.setDate(newDate);
  set time(TimeOfDay newTime) => _dateAndTimeRow.setTime(newTime);
  set location(LatLng newLocation) => _locationRow.setLocation(newLocation);
  set radius(double newRadius) => _locationRow.setRadius(newRadius);

  final _TaxonomyRow _taxonomyRow;
  final _ConfidenceRow _confidenceRow;
  final _FlightSizeRow _flightSizeRow;
  final _DateAndTimeRow _dateAndTimeRow;
  final _LocationRow _locationRow;

  final _addRow = const _IconDataRow(Icons.add);

  late final List<FlightFormImage> images;
  final _removedImages = <int>[];

  // List<NewImage> get newImages => List.unmodifiable(_flightFormSkeleton
  //     .whereType<_ImageRow>()
  //     .map((imageRow) => imageRow.content)
  //     .whereType<NewImage>());

  List<NewImage> get newImages =>
      List.unmodifiable(images.whereType<NewImage>());

  List<int> get removedImages => List.unmodifiable(_removedImages);

  late final List<_FlightFormRow> _flightFormSkeleton;

  List<_FlightFormRow> _generateFlightFormSkeleton() {
    return [
      const _HeaderRow(_FlightFormHeaders.taxonomy),
      _taxonomyRow,
      _confidenceRow,
      const _HeaderRow(_FlightFormHeaders.flightSize),
      _flightSizeRow,
      const _HeaderRow(_FlightFormHeaders.dateAndTimeOfFlight),
      _dateAndTimeRow,
      const _HeaderRow(_FlightFormHeaders.flightLocation),
      _locationRow,
      const _HeaderRow(_FlightFormHeaders.images),
      _ImagesRow(images),
      _addRow,
    ];
  }

  FlightFormIntermediateData.blank({LatLng? currentLocation})
      : _taxonomyRow = _TaxonomyRow(null, null),
        _confidenceRow = _ConfidenceRow(ConfidenceLevels.low),
        _flightSizeRow = _FlightSizeRow(FlightSize.manyQueens),
        _dateAndTimeRow = _DateAndTimeRow(DateTime.now(), TimeOfDay.now()),
        _locationRow = _LocationRow(currentLocation ?? const LatLng(0, 0), 0) {
    images = <FlightFormImage>[];
    _flightFormSkeleton = _generateFlightFormSkeleton();
  }

  FlightFormIntermediateData.from(Flight flight)
      : _taxonomyRow = _TaxonomyRow(flight.taxonomy.genus, flight.taxonomy),
        _confidenceRow = _ConfidenceRow(flight.confidence),
        _flightSizeRow = _FlightSizeRow(flight.size),
        _dateAndTimeRow = _DateAndTimeRow(
          flight.dateOfFlight,
          TimeOfDay.fromDateTime(flight.dateOfFlight),
        ),
        _locationRow = _LocationRow(
            LatLng(flight.latitude, flight.longitude), flight.radius) {
    // if (flight.hasImage) {
    images = List<FlightFormImage>.from(
        flight.images.map((e) => ExistingImage(e.id, e.image)));
    _flightFormSkeleton = _generateFlightFormSkeleton();
    // }
  }

  int addNewImage(NewImage image) {
    // final index = _flightFormSkeleton.length - 1;
    // _flightFormSkeleton.insert(index, _ImageRow(image));
    // return index;
    images.insert(images.length, image);
    return images.length - 1;
  }

  void removeImage(FlightFormImage image, int index) {
    // final row = _flightFormSkeleton[index];
    //
    // if (row is! _ImageRow) {
    //   throw NotImageRowException();
    // }

    // final image = row.content;
    // final image = images[index];

    if (image is ExistingImage) {
      _removedImages.add(image.imageId);
    }

    // print("The list images has length ${images.length}");

    // print(images);

    images.removeAt(index);
    // _flightFormSkeleton.removeAt(index);
  }

  _FlightFormRow getRowForIndex(int i) {
    return _flightFormSkeleton[i];
  }

  @override
  bool operator ==(Object other) {
    return other is FlightFormIntermediateData &&
        genus == other.genus &&
        species == other.species &&
        confidenceLevel == other.confidenceLevel &&
        flightSize == other.flightSize &&
        date == other.date &&
        time == other.time &&
        location == other.location &&
        radius == other.radius &&
        const ListEquality<FlightFormImage>().equals(images, other.images) &&
        const ListEquality<FlightFormImage>()
            .equals(newImages, other.newImages);
  }

  @override
  int get hashCode =>
      genus.hashCode +
      species.hashCode +
      location.hashCode +
      date.hashCode +
      time.hashCode;

  static FlightUpdateMethod getUpdateMethod(
      FlightFormIntermediateData original, FlightFormIntermediateData updated) {
    final changedContent = original.genus != updated.genus ||
        original.species != updated.species ||
        original.confidenceLevel != updated.confidenceLevel ||
        original.flightSize != updated.flightSize ||
        original.date != updated.date ||
        original.time != updated.time ||
        original.location != updated.location ||
        original.radius != updated.radius;

    final changedImages =
        updated.removedImages.isNotEmpty || updated.newImages.isNotEmpty;

    if (changedImages && changedContent) {
      return FlightUpdateMethod.all;
    }

    if (changedImages) {
      return FlightUpdateMethod.images;
    }

    if (changedContent) {
      return FlightUpdateMethod.content;
    }

    return FlightUpdateMethod.none;
  }
}

class FlightFormData {
  final Species taxonomy;
  final ConfidenceLevels confidenceLevel;

  final FlightSize flightSize;
  final tz.TZDateTime dateOfFlight;
  final LatLng location;
  final double radius;

  // final bool hasImage;
  // final Uint8List? image;

  const FlightFormData({
    required this.taxonomy,
    required this.confidenceLevel,
    required this.flightSize,
    required this.dateOfFlight,
    required this.location,
    required this.radius,
    // required this.hasImage,
    // this.image,
  });

  FlightFormData.from(FlightFormIntermediateData intermediateData)
      : taxonomy = intermediateData.species!,
        confidenceLevel = intermediateData.confidenceLevel,
        flightSize = intermediateData.flightSize,
        // dateOfFlight = DateTime(
        //   intermediateData.date.year,
        //   intermediateData.date.month,
        //   intermediateData.date.day,
        //   intermediateData.time.hour,
        //   intermediateData.time.minute,
        // ),
        dateOfFlight = intermediateData.dateAndTimeOfFlight,
        location = intermediateData.location,
        radius = intermediateData.radius;

  Map<String, dynamic> toJson() {
    // print("Flight occurred at ${dateOfFlight.toIso8601String()}");
    return <String, dynamic>{
      'taxonomy': taxonomy.id,
      'confidence': _$ConfidenceLevelsEnumMap[confidenceLevel],
      'size': _$FlightSizeEnumMap[flightSize],
      'dateOfFlight': dateOfFlight.toIso8601String(),
      'latitude': location.latitude,
      'longitude': location.longitude,
      'radius': radius,
      // 'hasImage': hasImage,
      // if (image != null) 'image': base64EncodeImageBytes(image),
    };
  }
}

const _$ConfidenceLevelsEnumMap = {
  ConfidenceLevels.low: 0,
  ConfidenceLevels.high: 1,
};

const _$FlightSizeEnumMap = {
  FlightSize.manyQueens: 0,
  FlightSize.singleQueen: 1,
};
