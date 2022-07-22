/*
 * flight_detail_screen.dart
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

import 'package:ant_nup_tracker/changelog_screen.dart';
import 'package:ant_nup_tracker/comments.dart';
import 'package:ant_nup_tracker/flight_detail.dart';
import 'package:ant_nup_tracker/flight_form.dart';
import 'package:ant_nup_tracker/flight_list.dart';
import 'package:ant_nup_tracker/flights.dart';
import 'package:ant_nup_tracker/images.dart';
import 'package:ant_nup_tracker/sessions.dart';
import 'package:ant_nup_tracker/user_detail_screen.dart';
import 'package:ant_nup_tracker/users.dart';
import 'package:ant_nup_tracker/weather_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'common_ui_elements.dart';
import 'detail_screen.dart';
import 'exceptions.dart';

class FlightDetailScreen extends DetailScreen<int, Flight> {
  // final int _flightID;
  // final Flight _flight;

  const FlightDetailScreen(int id, {Flight? initialValue, Key? key})
      : super(id, initialValue: initialValue, key: key);

  @override
  _FlightDetailScreenState createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends DetailScreenState<int, Flight> {
  // implements FlightDetailObserver {

  // final int _id;
  // late Future<Flight> fetchFlightFuture;
  Flight? flight;

  late AppLocalizations _appLocalizations;

  _FlightDetailScreenState() : super();

  late TextStyle _labelStyle;

  Widget _buildTextLabelDetailRow({
    required String label,
    String? detail,
    TextStyle? detailStyle,
  }) {
    var textStyle = detailStyle ?? _labelStyle.apply(fontWeightDelta: 2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: _labelStyle)),
          if (detail != null)
            Expanded(
                child: Text(
              detail,
              style: textStyle,
              textAlign: TextAlign.end,
            )),
        ],
      ),
    );
  }

  Widget _buildUserRow(
      {required String label,
      required String username,
      Role userRole = Role.citizen}) {
    var textStyle = _labelStyle.apply(fontWeightDelta: 2);
    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => UserDetailScreen(username))),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: _labelStyle)),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width / 2),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                    username,
                    style: textStyle,
                    textAlign: TextAlign.end,
                  )),
                  if (userRole == Role.flagged)
                    // const Icon(Icons.warning, color: Colors.red),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: const Image(
                        image: AssetImage("assets/ant_circles/red_ant.png"),
                        width: 16.0,
                      ),
                    ),
                  if (userRole == Role.professional)
                    // const Icon(Icons.verified, color: Colors.green),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: const Image(
                        image: AssetImage("assets/ant_circles/green_ant.png"),
                        width: 16.0,
                      ),
                    ),
                  const Icon(Icons.more_horiz),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherRows() {
    return Column(
      children: [
        HeaderRow(label: _appLocalizations.weatherHeader),
        ListTile(
          contentPadding: const EdgeInsets.all(8.0),
          title: Text(_appLocalizations.weatherLabel, style: _labelStyle,),
          trailing: const Icon(Icons.more_horiz),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => WeatherDetailScreen(
                    id,
                    flight: flight!,
                  ))),
        ),
        // InkWell(
        //   onTap: () => Navigator.of(context)
        //       .push(MaterialPageRoute(builder: (_) => WeatherDetailScreen(id))),
        //   child: Container(
        //     margin: const EdgeInsets.symmetric(vertical: 12.0),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Expanded(
        //             child: Text(_appLocalizations.weatherLabel,
        //                 style: _labelStyle)),
        //         const Icon(Icons.more_horiz)
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // Widget _buildImageRow(Uri imageUrl) {
  //   return Column(
  //     children: [
  //       _buildHeaderRow(label: _appLocalizations.imageHeaderDetail),
  //       GestureDetector(
  //         child: Image.network(imageUrl.toString()),
  //         onTap: () {
  //           Navigator.of(context).push(
  //             MaterialPageRoute<void>(
  //               builder: (BuildContext context) {
  //                 return Stack(
  //                   children: [
  //                     Scaffold(
  //                       appBar: AppBar(
  //                         backgroundColor: Colors.transparent,
  //                         elevation: 0.0,
  //                         // actions: [
  //                         //   IconButton(
  //                         //     onPressed: () {
  //                         //       Navigator.of(context).push(
  //                         //         MaterialPageRoute(
  //                         //           builder: (context) => FlightFormScreen(
  //                         //             flight: flight,
  //                         //           ),
  //                         //         ),
  //                         //       );
  //                         //     },
  //                         //     icon: Icon(Icons.edit),
  //                         //     tooltip: appLocalization.edit,
  //                         //   )
  //                         // ],
  //                       ),
  //                       body: Container(
  //                         child: InteractiveViewer(
  //                           child: Image.network(imageUrl.toString()),
  //                         ),
  //                         width: MediaQuery.of(context).size.width,
  //                         height: MediaQuery.of(context).size.height,
  //                         color: Colors.black,
  //                       ),
  //                       extendBody: true,
  //                       extendBodyBehindAppBar: true,
  //                     ),
  //                   ],
  //                 );
  //               },
  //               fullscreenDialog: true,
  //             ),
  //           );
  //         },
  //       )
  //     ],
  //   );
  // }

  Widget _buildImagesRow() {

    return FutureBuilder(future: flight!.loadImagesFuture,
        builder: (BuildContext context, AsyncSnapshot<List<FlightImage>> snapshot){

      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData){
        final images = snapshot.data!;

        if (images.isEmpty) {
          // return Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Text(_appLocalizations.noImages, style: _labelStyle,),
          // );
          return ListTile(contentPadding: const EdgeInsets.all(8.0), title: Text(_appLocalizations.noImages, style: _labelStyle,));
        }

        final imageWidgets = images.map((image) {
          final imageUrl = image.image;
          var heroTag = "image_${image.id}";
          return GestureDetector(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                // child: Image.network(imageUrl.toString()),
                child: Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width < 280 ? MediaQuery.of(context).size.width : 280,
                    imageUrl: imageUrl.toString(),
                    httpHeaders: SessionManager.shared.headers,
                    progressIndicatorBuilder: (context, url, progress) => Center(
                        child: SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(
                                value: progress.progress))),
                  ),
                )),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return ImageViewer(
                      imageUrl: imageUrl,
                      heroTag: heroTag,
                    );
                  },
                  fullscreenDialog: true,
                ),
              );
            },
          );
        }).toList(growable: false);

        return SizedBox(
          height: 480,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: imageWidgets,
          ),
        );
      }

      else {
        return SizedBox(
          height: 480,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                Text(_appLocalizations.loadingImages)
              ],
            ),
          ),
        );
      }

        });
  }

  Widget _buildRecordHistoryRow(int id) {
    return ListTile(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ChangelogScreen(id))),
      contentPadding: const EdgeInsets.all(8.0),
      title: Text(_appLocalizations.recordHistoryLabel, style: _labelStyle,),
      trailing: const Icon(Icons.more_horiz),
    );
  }

  Widget _buildLocationRow(LatLng location, double radius) {
    return Container(
      width: MediaQuery.of(context).size.width,
      // height: MediaQuery.of(context).size.width < 400
      //     ? 400
      //     : MediaQuery.of(context).size.width,
      height: 400,
      padding: const EdgeInsets.all(8.0),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: location, zoom: 10),
        gestureRecognizers: {
          Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
          Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
        },
        markers: {
          Marker(
            markerId: const MarkerId("flightLocation"),
            position: location,
          )
        },
        circles: {
          Circle(
              circleId: const CircleId("flightRadius"),
              center: location,
              radius: 1000 * radius,
              strokeColor: Colors.red,
              strokeWidth: 2)
        },
      ),
    );
  }

  Widget _buildVerifiedRows(
      {required String verifiedBy, required DateTime verifiedAt}) {
    final currentLocale = _appLocalizations.localeName;
    return Column(
      children: [
        HeaderRow(label: _appLocalizations.verificationInformationHeader),
        _buildUserRow(
            label: _appLocalizations.verifiedByLabel,
            username: verifiedBy,
            userRole: Role.professional),
        _buildTextLabelDetailRow(
            label: _appLocalizations.dateVerifiedDetailLabel,
            detail: DateFormat.yMMMd(currentLocale).format(verifiedAt)),
        _buildTextLabelDetailRow(
            label: _appLocalizations.timeVerifiedDetailLabel,
            detail: DateFormat.jm(currentLocale).format(verifiedAt)),
      ],
    );
  }

  String getConfidenceString(ConfidenceLevels level) {
    switch (level) {
      case ConfidenceLevels.low:
        return AppLocalizations.of(context)!.lowConfidence;
      case ConfidenceLevels.high:
        return AppLocalizations.of(context)!.highConfidence;
    }
  }

  String getSizeString(FlightSize size) {
    switch (size) {
      case FlightSize.manyQueens:
        return AppLocalizations.of(context)!.manyQueens;
      case FlightSize.singleQueen:
        return AppLocalizations.of(context)!.singleQueen;
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _loadFlight(_id);
  //   fetchFlightFuture = fetchFlight(_id);
  //   // FlightDetailFetcher.shared.observer = this;
  //   // FlightDetailFetcher.shared.fetchFlightDetailForId(_flightID);
  // }

  @override
  void loadDetailFuture(int id, {bool forceReload = false}) {
    setState(() {
      detailFuture = FlightStore.shared.getFlight(id, forceReload: forceReload);
    });
  }

  AlertDialog _buildLoadingDialog(String title) => AlertDialog(
        title: Text(title),
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

  Future<void> _createNewComment(TextEditingController commentTextController,
      GlobalKey<FormState> commentFormKey) async {
    if (!commentFormKey.currentState!.validate()) {
      return;
    }

    final commentText = commentTextController.text;

    // final newComment = Comment(
    //   0,
    //   flight!.flightID,
    //   SessionManager.shared.session!.username,
    //   SessionManager.shared.session!.role,
    //   commentText,
    //   DateTime.now(),
    // );
    Navigator.of(context).pop();
    showDialog(
        context: context,
        builder: (context) =>
            _buildLoadingDialog(_appLocalizations.uploadingComment),
        barrierDismissible: false);
    try {
      await addNewComment(id, commentText);
      commentTextController.dispose();
      Navigator.of(context).pop();
      setState(() {});
      // loadDetailFuture(id, forceReload: true);
    } on LocalisableException catch (exception) {
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (context) => _buildExceptionDialog(exception),
      );
      commentTextController.dispose();

      showDialog(
        context: context,
        builder: (context) => _buildCommentDialog(commentText: commentText),
      );
    }
  }

  Future<void> _updateExistingComment(
      TextEditingController commentTextController,
      GlobalKey<FormState> commentFormKey,
      {required int commentId}) async {
    if (!commentFormKey.currentState!.validate()) {
      return;
    }

    final commentText = commentTextController.text;

    final updatedComment = Comment(
      commentId,
      flight!.flightID,
      SessionManager.shared.session!.username,
      SessionManager.shared.session!.role,
      commentText,
      DateTime.now(),
    );
    Navigator.of(context).pop();
    showDialog(
        context: context,
        builder: (context) =>
            _buildLoadingDialog(_appLocalizations.uploadingComment),
        barrierDismissible: false);
    try {
      await updateComment(id, updatedComment);
      commentTextController.dispose();
      Navigator.of(context).pop();
      // loadDetailFuture(id, forceReload: true);
      setState(() {});
    } on LocalisableException catch (exception) {
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (context) => _buildExceptionDialog(exception),
      );
      commentTextController.dispose();

      showDialog(
        context: context,
        builder: (context) =>
            _buildCommentDialog(comment: updatedComment, isEditing: true),
      );
    }
  }

  AlertDialog _buildCommentDialog(
      {Comment? comment, String? commentText, bool isEditing = false}) {
    final commentTextController =
        TextEditingController(text: isEditing ? comment?.text : commentText);
    final commentFormKey = GlobalKey<FormState>();

    final header = isEditing
        ? _appLocalizations.editComment
        : _appLocalizations.createComment;

    final saveLabel =
        isEditing ? _appLocalizations.update : _appLocalizations.save;
    // final saveAction = isEditing ? _updateExistingComment : _createNewComment;

    return AlertDialog(
      title: Text(header),
      content: SizedBox(
        height: 120,
        child: Form(
          key: commentFormKey,
          child: TextFormField(
            // expands: true,
            controller: commentTextController,
            decoration: InputDecoration(
              labelText: _appLocalizations.comment,
            ),
            expands: true,
            minLines: null,
            maxLines: null,
            // onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _appLocalizations.emptyComment;
              }

              return null;
            },
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            commentTextController.clear();
            // commentTextController.dispose();
          },
          child: Text(_appLocalizations.cancel),
        ),
        TextButton(
          onPressed: () => isEditing
              ? _updateExistingComment(commentTextController, commentFormKey,
                  commentId: comment!.id)
              : _createNewComment(commentTextController, commentFormKey),
          child: Text(saveLabel),
        ),
      ],
    );
  }

  AlertDialog _buildValidateDialog({required bool isValidated}) {
    return AlertDialog(
      title: Text(isValidated
          ? _appLocalizations.unVerifyFlightHeader
          : _appLocalizations.verifyFlightHeader),
      content: Text(isValidated
          ? _appLocalizations.unVerifyFlightBody
          : _appLocalizations.verifyFlightBody),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(_appLocalizations.cancel),
        ),
        TextButton(
            onPressed: () async {
              try {
                // print("Validating flight ${flight!.flightID}");
                showDialog(
                    context: context,
                    builder: (context) => _buildLoadingDialog(isValidated
                        ? _appLocalizations.unVerifyingFlight
                        : _appLocalizations.verifyingFlight),
                    barrierDismissible: false);
                await validateFlight(flight!.flightID,
                    isValidated: isValidated);
                Navigator.of(context).pop(true);
                Navigator.of(context).pop(true);
              } on LocalisableException catch (exception) {
                Navigator.of(context).pop();
                showDialog(
                    context: context,
                    builder: (context) => _buildExceptionDialog(exception));
              }
            },
            child: Text(_appLocalizations.ok))
      ],
    );
  }

  void _createComment() {
    showDialog(context: context, builder: (context) => _buildCommentDialog());
  }

  void _editComment(Comment comment) {
    showDialog(
        context: context,
        builder: (context) =>
            _buildCommentDialog(comment: comment, isEditing: true));
  }

  Future<bool> _validateFlight(bool isValidated) async {
    final shouldReload = await showDialog<bool>(
        context: context,
        builder: (context) => _buildValidateDialog(isValidated: isValidated));

    // print("Should reload: $shouldReload");

    return shouldReload ?? false;
  }

  // void _invalidateFlight() {
  //   showDialog(
  //       context: context, builder: (context) => _buildUnValidateDialog());
  // }

  @override
  List<Widget> get actions {
    if (SessionManager.shared.isLoggedIn && flight != null) {
      // print("Logged in: ${SessionManager.shared.isLoggedIn}");
      // print("Flight is null: ${flight == null}");
      // print("Username: ${SessionManager.shared.session?.username}");
      // print("Flight owner: ${flight?.owner}");

      return [
        if (SessionManager.shared.session!.role == Role.professional &&
            flight!.ownerRole != Role.professional)
          _buildValidateButton(flight!.validated),
        _buildCommentButton(),
        if (SessionManager.shared.session!.username == flight!.owner)
          _buildEditButton()
      ];
    } else {
      // print("Not logged in or flight is null");
      return [];
    }
  }

  IconButton _buildEditButton() {
    return IconButton(
      onPressed: () async {
        var shouldReload = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (context) => FlightFormScreen(
              flight: flight,
            ),
          ),
        );

        if (shouldReload ?? false) {
          loadDetailFuture(id, forceReload: true);
        }
      },
      icon: const Icon(Icons.edit),
      tooltip: AppLocalizations.of(context)!.edit,
    );
  }

  IconButton _buildCommentButton() {
    return IconButton(
      icon: const Icon(Icons.comment),
      tooltip: _appLocalizations.comment,
      onPressed: () => _createComment(),
    );
  }

  IconButton _buildValidateButton(bool isValidated) {
    return IconButton(
      icon: const Icon(Icons.verified),
      tooltip: flight!.validated
          ? _appLocalizations.unVerifyFlightHeader
          : _appLocalizations.verifyFlightHeader,
      onPressed: () async {
        final shouldReload = await _validateFlight(isValidated);

        if (shouldReload) {
          // FlightStore.shared.getFlight(id, forceReload: true);
          loadDetailFuture(id, forceReload: true);
        }
      },
    );
  }

  @override
  String get appBarHeader =>
      AppLocalizations.of(context)!.flightDetailHeader(id);

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);
    // _headerStyle =
    //     Theme.of(context).textTheme.bodyText2!.apply(fontWeightDelta: 2);

    return super.build(context);
  }

  @override
  void processData(Flight flight) {
    this.flight = flight;
//     print("""
// ******************************************************************
// Processing the data.......
// id: ${flight.flightID}
// taxonomy: ${flight.taxonomy}
// owner: ${flight.owner}
// verified: ${flight.validated}
// ******************************************************************
// """);
  }

  @override
  Widget buildDetailScreen(Flight flight) {
    final currentLocale = _appLocalizations.localeName;
    var italicStyle =
        _labelStyle.apply(fontStyle: FontStyle.italic, fontWeightDelta: 2);

    // print("Flight is verified: ${flight.validated}");

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        HeaderRow(label: _appLocalizations.basicInfo),
        _buildTextLabelDetailRow(
            label: _appLocalizations.flightID, detail: "${flight.flightID}"),
        _buildTextLabelDetailRow(
            label: _appLocalizations.genus,
            detail: flight.taxonomy.genus.name,
            detailStyle: italicStyle),
        _buildTextLabelDetailRow(
            label: _appLocalizations.species,
            detail: flight.taxonomy.name,
            detailStyle: italicStyle),
        _buildTextLabelDetailRow(
            label: _appLocalizations.speciesConfidence,
            detail: getConfidenceString(flight.confidence)),
        _buildTextLabelDetailRow(
            label: _appLocalizations.flightSize,
            detail: getSizeString(flight.size)),
        HeaderRow(label: _appLocalizations.dateAndTimeOfFlight),
        _buildTextLabelDetailRow(
            label: _appLocalizations.dateOfFlight,
            detail:
                DateFormat.yMMMd(currentLocale).format(flight.dateOfFlight)),
        _buildTextLabelDetailRow(
            label: _appLocalizations.timeOfFlight,
            detail: DateFormat.jm(currentLocale).format(flight.dateOfFlight)),
        HeaderRow(label: _appLocalizations.flightLocationHeader),
        // _buildTextLabelDetailRow(label: "MAP GOES HERE"),
        _buildLocationRow(
            LatLng(flight.latitude, flight.longitude), flight.radius),
        _buildTextLabelDetailRow(
            label: _appLocalizations.gpsCoordinatesLabel,
            detail: stringFromCoordinates(
                latitude: flight.latitude,
                longitude: flight.longitude,
                precision: 2)),
        _buildTextLabelDetailRow(
            label: _appLocalizations.radiusDetailLabel,
            detail: _appLocalizations.radiusDistanceDetail(flight.radius)),
        HeaderRow(label: _appLocalizations.recordingInformationHeader),
        _buildUserRow(
            label: _appLocalizations.recordedByLabel,
            username: flight.owner,
            userRole: flight.ownerRole),
        _buildTextLabelDetailRow(
            label: _appLocalizations.dateRecordedDetailLabel,
            detail:
                DateFormat.yMMMd(currentLocale).format(flight.dateRecorded)),
        _buildTextLabelDetailRow(
            label: _appLocalizations.timeRecordedDetailLabel,
            detail: DateFormat.jm(currentLocale).format(flight.dateRecorded)),
        // if (flight.imageUrl != null) _buildImageRow(flight.imageUrl!),
        // if (flight.images.isNotEmpty)
          HeaderRow(label: _appLocalizations.imageHeaderDetail),
        // if (flight.images.isNotEmpty)
          _buildImagesRow(),
        // for (var image in flight.images) _buildImageRow(image),
        if (flight.hasWeather) _buildWeatherRows(),
        if (flight.validated && flight.ownerRole != Role.professional)
          _buildVerifiedRows(
              verifiedBy: flight.validatedBy!, verifiedAt: flight.validatedAt!),
        HeaderRow(label: _appLocalizations.commentsHeader),
        // if (flight.comments.isEmpty)
        //   _buildTextLabelDetailRow(label: _appLocalizations.noCommentsMessage),
        // if (flight.comments.isNotEmpty) _buildCommentsSection(flight.comments),
        CommentSection(id: id, editAction: _editComment),
        // for (final comment in flight!.comments) _buildCommentRow(comment),
        HeaderRow(label: _appLocalizations.recordHistoryHeader),
        _buildRecordHistoryRow(id)
      ],
    );
  }
}

class CommentRow extends StatelessWidget {
  const CommentRow({Key? key, required this.comment, required this.editAction})
      : super(key: key);

  final Comment comment;
  final void Function(Comment) editAction;

  @override
  Widget build(BuildContext context) {
    final _appLocalizations = AppLocalizations.of(context)!;
    final currentLocale = _appLocalizations.localeName;
    final textStyle = Theme.of(context)
        .textTheme
        .bodyText2!
        .apply(fontSizeDelta: 4.0)
        .apply(fontWeightDelta: 2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2.0,
      // padding: EdgeInsets.all(4.0),
      // decoration: BoxDecoration(
      //     color: Theme.of(context).cardColor,
      //     borderRadius: BorderRadius.circular(8),
      //     border: Border.all(color: Theme.of(context).dividerColor, width: 2),
      //     boxShadow: [
      //       BoxShadow(
      //           offset: Offset(2, 2),
      //           color: Theme.of(context).shadowColor,
      //           blurRadius: 1.0,
      //           spreadRadius: 0)
      //     ]),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Text(
                  comment.text,
                  style: textStyle,
                )),
                if (comment.author == SessionManager.shared.session?.username)
                  IconButton(
                    onPressed: () => editAction(comment),
                    icon: const Icon(Icons.edit),
                    tooltip: _appLocalizations.editComment,
                  ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserDetailScreen(comment.author),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(comment.author,
                        style: textStyle.apply(
                            fontSizeDelta: -3, fontWeightDelta: -2),
                        textAlign: TextAlign.end),
                  ),
                  if (comment.authorRole == Role.flagged)
                    // const Icon(Icons.warning, color: Colors.red),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: const Image(
                        image: AssetImage("assets/ant_circles/red_ant.png"),
                        width: 16.0,
                      ),
                    ),
                  if (comment.authorRole == Role.professional)
                    // const Icon(Icons.verified, color: Colors.green)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: const Image(
                        image: AssetImage("assets/ant_circles/green_ant.png"),
                        width: 16.0,
                      ),
                    )
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                    child: Text(
                        DateFormat.yMMMd(currentLocale)
                            .add_jm()
                            .format(comment.time),
                        textAlign: TextAlign.end))
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CommentSection extends StatefulWidget {
  const CommentSection(
      {Key? key,
      required this.id,
      required this.editAction,
      this.fetchCommentsFuture})
      : super(key: key);

  final int id;
  final void Function(Comment) editAction;
  final Future<List<Comment>>? fetchCommentsFuture;

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late Future<List<Comment>> _fetchCommentsFuture;

  @override
  void initState() {
    _fetchCommentsFuture =
        widget.fetchCommentsFuture ?? getCommentsForFlight(widget.id);

    super.initState();
  }

  void reload() {
    setState(() {
      _fetchCommentsFuture = getCommentsForFlight(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    final _labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);

    return FutureBuilder(
      future: _fetchCommentsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Comment>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              Text(appLocalizations.loadingComments),
            ],
          );
        }

        if (snapshot.hasData) {
          final comments = snapshot.data!;

          if (comments.isEmpty) {
            return ListTile(
              contentPadding: const EdgeInsets.all(8.0),
              title: Text(appLocalizations.noCommentsMessage, style: _labelStyle,),
            );
          }

          return Column(
            children: comments
                .map((comment) =>
                    CommentRow(comment: comment, editAction: widget.editAction))
                .toList(),
          );
        }

        return const CircularProgressIndicator();
      },
    );
  }
}

class ImageViewer extends StatefulWidget {
  const ImageViewer({Key? key, required this.imageUrl, this.heroTag})
      : super(key: key);

  final Uri imageUrl;
  final String? heroTag;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  var appBarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: appBarVisible
              ? AppBar(
                  // backgroundColor: Colors.black54.withOpacity(0.6),
                  backgroundColor: Colors.transparent,
                  elevation: 1.0,
                  // actions: [
                  //   IconButton(
                  //     onPressed: () {
                  //       Navigator.of(context).push(
                  //         MaterialPageRoute(
                  //           builder: (context) => FlightFormScreen(
                  //             flight: flight,
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //     icon: Icon(Icons.edit),
                  //     tooltip: appLocalization.edit,
                  //   )
                  // ],
                )
              : null,
          body: GestureDetector(
            onTap: () => setState(() {
              appBarVisible = !appBarVisible;
            }),
            child: Container(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.symmetric(vertical: 32),
                // child: Image.network(imageUrl.toString()),
                child: widget.heroTag != null
                    ? Hero(
                        child: CachedNetworkImage(
                            imageUrl: widget.imageUrl.toString()),
                        tag: widget.heroTag!,
                      )
                    : CachedNetworkImage(imageUrl: widget.imageUrl.toString()),
                maxScale: 10.0,
              ),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black,
            ),
          ),
          extendBody: true,
          extendBodyBehindAppBar: true,
        ),
      ],
    );
  }
}
