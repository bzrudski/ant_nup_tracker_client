/*
 * url_manager.dart
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

import 'package:ant_nup_tracker/flights.dart';

import 'filtering.dart';

/// Singleton class for managing all the URLs in the app.
///
/// All http requests should involve a URL obtained using
/// the methods in this class. All urls should end with a slash.
///
/// **Naming Conventions:**
///  - Getters: purposeUrl
///  - Methods: urlForPurpose
class UrlManager {
  final Uri _baseUrl;

  /// Private constructor.
  ///
  /// For custom servers, the [base] defines the url for the server.
  UrlManager._(String base) :
    _baseUrl = Uri.parse(base);
  
  static final shared = UrlManager._("https://www.antnuptialflights.com/");

  final _apiUrl = "api";
  final _loginUrl = "login";
  final _verifyUrl = "verify";
  final _logoutDeviceUrl = "logout";
  final _flightsUrl = "flights";
  final _createUrl = "create";
  final _createAccountUrl = "create-account";
  final _commentsUrl = "comments";
  final _mySpeciesUrl = "my-species";
  final _myGeneraUrl = "my-genera";
  final _historyUrl = "history";
  final _weatherUrl = "weather";
  final _imagesUrl = "images";
  final _usersUrl = "users";
  final _resetPassUrl = "reset-password";
  final _validateUrl = "verify";
  final _loadTaxonomyUrl = "latest-taxonomy";
  final _taxonomyVersionUrl = "taxonomy-version";
  final _generaUrl = "genera";
  final _speciesUrl = "species";
  final _aboutUrl = "about";
  final _privacyUrl = "privacy-policy";
  final _termsUrl = "terms-and-conditions";
  final _emailAddress = "mailto:nuptialtracker@gmail.com";

  Uri get homeUrl => _baseUrl;
  Uri get listUrl => _baseUrl.resolve("$_apiUrl/$_flightsUrl/");
  Uri get filteredListUrl {
    // var url = _baseUrl.resolve("$_apiUrl/$_flightsUrl/");

    final queryParameters = <String, String>{
      "ordering": FilteringManager.shared.ordering
          .urlEntry(FilteringManager.shared.direction),
      for (var filter in FilteringManager.shared.filters)
        ...filter.queryParameters
    };

    final url = listUrl.replace(queryParameters: queryParameters);

    // print(url);

    return url;
  }
  
  Uri get apiUrl => _baseUrl.resolve("$_apiUrl/");
  Uri get createUrl => apiUrl.resolve("$_createUrl/");
  Uri get commentsUrl => apiUrl.resolve("$_commentsUrl/");
  Uri get loginUrl => apiUrl.resolve("$_loginUrl/");
  Uri get verifyUrl => loginUrl.resolve("$_verifyUrl/");
  Uri get logoutUrl => apiUrl.resolve("$_logoutDeviceUrl/");
  Uri get mySpeciesUrl => apiUrl.resolve("$_mySpeciesUrl/");
  Uri get myGeneraUrl => apiUrl.resolve("$_myGeneraUrl/");
  Uri get loadTaxonomyUrl => apiUrl.resolve("$_loadTaxonomyUrl/");
  Uri get taxonomyVersionUrl => apiUrl.resolve("$_taxonomyVersionUrl/");
  Uri get generaUrl => apiUrl.resolve("$_generaUrl/");
  Uri get createAccountUrl => _baseUrl.resolve("$_createAccountUrl/");
  Uri get usersUrl => apiUrl.resolve("$_usersUrl/");
  Uri get passwordResetUrl => _baseUrl.resolve("$_resetPassUrl/");
  Uri get aboutUrl => _baseUrl.resolve("$_aboutUrl/");
  Uri get privacyUrl => _baseUrl.resolve("$_privacyUrl/");
  Uri get termsUrl => _baseUrl.resolve("$_termsUrl/");
  Uri get contactUrl => Uri.parse(_emailAddress);

  Uri urlForFlight(int id) {
    return listUrl.resolve("$id/");
  }

  Uri urlForFlightImages(int id) {
    return urlForFlight(id).resolve("$_imagesUrl/");
  }

  Uri urlForImage(int flightId, int imageId) {
    return urlForFlightImages(flightId).resolve("$imageId/");
  }

  Uri urlForWeather(int id) {
    return urlForFlight(id).resolve(_weatherUrl);
  }

  Uri urlForComments(int id) {
    return urlForFlight(id).resolve("$_commentsUrl/");
  }

  Uri urlForCommentEdit(int id, int commentId) {
    return urlForComments(id).resolve("$commentId/");
  }

  Uri urlForHistory(int id) {
    return urlForFlight(id).resolve(_historyUrl);
  }

  Uri urlForValidate(int id) {
    return urlForFlight(id).resolve("$_validateUrl/");
  }

  Uri urlForUser(String username) {
    return usersUrl.resolve("$username/");
  }

  Uri urlForGenus(Genus genus) {
    return generaUrl.resolve("${genus.id}/");
  }

  Uri urlForSpeciesList(Genus genus) {
    return urlForGenus(genus).resolve("$_speciesUrl/");
  }

  // Uri urlForFilteredFlights({Genus? genus, Species? species}) {
  //   if (species != null) {
  //     var queryParams = {"genus": species.genus.name, "species": species.name};
  //     return listUrl.replace(queryParameters: queryParams);
  //   } else if (genus != null) {
  //     var queryParams = {"genus": genus.name};
  //     return listUrl.replace(queryParameters: queryParams);
  //   }
  //
  //   return listUrl;
  // }
}

extension UrlName on ListOrdering {
  String urlEntry([SortingDirection direction = SortingDirection.descending]) {
    final directionString = direction == SortingDirection.descending ? "-" : "";

    switch (this) {
      case ListOrdering.flightId:
        return "${directionString}flightID";
      case ListOrdering.dateOfFlight:
        return "${directionString}dateOfFlight";
      case ListOrdering.dateRecorded:
        return "${directionString}dateRecorded";
      // case ListOrdering.lastUpdated:
      //   return "${directionString}lastUpdated";
      case ListOrdering.location:
        return "${directionString}location";
    }
  }
}

// void main() {
//   var id = 34;
//   // var genus = Genus.get("Pheidole");
//   // var species = Species.get(genus, "dentata");
//
//   print(UrlManager.shared.homeUrl);
//   print(UrlManager.shared.filteredListUrl);
//
//   print(UrlManager.shared.urlForFlight(id));
//   print(UrlManager.shared.urlForWeather(id));
//
//   // print(UrlManager.shared.urlForFilteredFlights(genus: genus));
//   // print(UrlManager.shared.urlForFilteredFlights(species: species));
//   print(UrlManager.shared.urlForHistory(id));
//   print(UrlManager.shared.contactUrl);
// }
