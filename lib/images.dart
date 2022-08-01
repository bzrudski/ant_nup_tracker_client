/*
 * images.dart
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

import 'package:ant_nup_tracker/exceptions.dart';
import 'package:ant_nup_tracker/sessions.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FlightImage {
  final Uri image;
  final int id;
  final int flight;
  final String author;
  final DateTime date;

  const FlightImage({
    required this.id,
    required this.image,
    required this.flight,
    required this.author,
    required this.date,
  });

  factory FlightImage.fromJson(Map<String, dynamic> json) {
    final id = json["id"] as int;
    final flight = json["flight"] as int;
    final author = json["created_by"] as String;
    final date = DateTime.parse(json["date_created"] as String);
    final image = Uri.parse(json["image"] as String);

    return FlightImage(
      id: id,
      image: image,
      flight: flight,
      author: author,
      date: date,
    );
  }
}

// Future<void> addImageToFlight(int flightId, String imagePath) async {
//   final url = UrlManager.shared.urlForFlightImages(flightId);
//
//   final file = await http.MultipartFile.fromPath("file", imagePath);
//
//   final request = http.MultipartRequest("POST", url);
//   request.files.add(file);
//
//   request.headers["Authorization"] =
//       "Token ${SessionManager.shared.session!.token}";
//
//   request.headers["Content-Type"] = file.contentType.mimeType;
//
//   try {
//     final response = await request.send();
//
//     print(response.statusCode);
//
//     final statusCode = response.statusCode;
//
//     if (statusCode == 401) throw FailedAuthenticationException();
//     if (statusCode == 404) throw NoFlightException(flightId);
//     if (statusCode != 201) throw ImageCreationException(statusCode);
//   } on IOException {
//     throw NoResponseException();
//   }
// }

// // From: https://en.wikipedia.org/wiki/Media_type
// const validExtensions = [
//   ".png",
//   ".jpg",
//   ".jpeg",
//   ".jfif",
//   ".gif",
//   ".pjpeg",
//   ".pjp"
// ];

Future<void> addImageToFlight(int flightId, XFile image) async {
  final url = UrlManager.shared.urlForFlightImages(flightId);

  // final fileExtension = extension(imagePath);

  // final mimeType = image.mimeType;//lookupMimeType(imagePath);

  final mimeType = lookupMimeType(image.path);

  if (mimeType == null) {
    throw InvalidImageTypeException();
  }
  if (!mimeType.startsWith("image/")) {
    throw InvalidImageTypeException(mimeType);
  }

  // final filename = basename(imagePath);
  // final file = File(imagePath);
  // final fileBytes = file.readAsBytesSync();

  final filename = image.name;
  // final fileBytes = await image.readAsBytes();
  final fileBytes =
      await FlutterImageCompress.compressWithFile(image.path, quality: 90);

  // final fileBytes = await http.MultipartFile.fromPath("file", imagePath);

  // final request = http.MultipartRequest("POST", url);
  // request.files.add(fileBytes);
  //
  // request.headers["Authorization"] =
  //     "Token ${SessionManager.shared.session!.token}";
  //
  // request.headers["Content-Type"] = fileBytes.contentType.mimeType;

  try {
    final response = await http.post(url,
        headers: {
          "Authorization": "Token ${SessionManager.shared.session!.token}",
          "Content-Type": mimeType,
          "Content-Disposition": "attachment; filename=\"$filename\""
        },
        body: fileBytes);

    // print(response.statusCode);

    final statusCode = response.statusCode;

    if (statusCode == 401) throw FailedAuthenticationException();
    if (statusCode == 404) throw NoFlightException(flightId);
    if (statusCode != 201) throw ImageCreationException(statusCode);
  } on IOException {
    throw NoResponseException();
  }
}

Future<void> deleteImage(int flightId, int imageId) async {
  final url = UrlManager.shared.urlForImage(flightId, imageId);

  try {
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Token ${SessionManager.shared.session!.token}"
      },
    );

    final statusCode = response.statusCode;

    if (statusCode == 401) throw FailedAuthenticationException();
    if (statusCode == 404) throw NoImageException(imageId);
    if (statusCode != 204) throw ImageDeletionException(statusCode);
  } on IOException {
    throw NoResponseException();
  }
}

Future<List<FlightImage>> fetchImagesForFlight(int id) async {
  final url = UrlManager.shared.urlForFlightImages(id);

  try {
    final response = await http.get(url, headers: SessionManager.shared.headers
    // {
    //   if (SessionManager.shared.isLoggedIn)
    //     "Authorization": "Token ${SessionManager.shared.session!.token}"
    // }
    );

    final statusCode = response.statusCode;

    if (statusCode == 401) throw FailedAuthenticationException();
    if (statusCode == 404) throw NoFlightException(id);
    if (statusCode != 200) throw ReadException(statusCode);

    try {
      final rawList = jsonDecode(response.body) as List<dynamic>;
      final convertedList =
          rawList.map((e) => FlightImage.fromJson(e)).toList();

      return convertedList;
    } catch (error, stacktrace) {
      // print(error);
      // print(stacktrace);
      throw JsonException();
    }
  } on IOException {
    throw NoResponseException();
  }
}
