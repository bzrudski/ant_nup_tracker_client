/*
 * main.dart
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

import 'package:ant_nup_tracker/exceptions.dart';
import 'package:ant_nup_tracker/filtering.dart';
import 'package:ant_nup_tracker/flight_detail_screen.dart';
import 'package:ant_nup_tracker/flight_form.dart';
import 'package:ant_nup_tracker/flight_list.dart';
import 'package:ant_nup_tracker/flights.dart';
import 'package:ant_nup_tracker/sessions.dart';
import 'package:ant_nup_tracker/users.dart';
import 'package:ant_nup_tracker/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'location_picker.dart';
import 'dark_mode_theme_ext.dart';
import 'taxonomy_manager.dart';

void main() => runApp(const AntNupTrackerApp());

class AntNupTrackerApp extends StatefulWidget {
  const AntNupTrackerApp({Key? key}) : super(key: key);

  @override
  _AntNupTrackerAppState createState() => _AntNupTrackerAppState();
}

class _AntNupTrackerAppState extends State<AntNupTrackerApp> {
  final Future<FirebaseApp> _firebaseInitialization = Firebase.initializeApp();

  // Future<void> _onReceivedBackgroundNotification(RemoteMessage message) async {
  //   final id = message.data["flight_id"] as int?;
  //
  //   if (id != null) {
  //
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(backgroundColor: const Color(0xffbfedff)),
        fontFamily: 'Open_Sans',
        textTheme: const TextTheme(
          subtitle2:
              TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
          subtitle1:
              TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
          headline1:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline2:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline3:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline4:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline5:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline6:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          overline: TextStyle(fontFamily: 'Open_Sans'),
          bodyText1: TextStyle(fontFamily: 'Open_Sans'),
          bodyText2: TextStyle(fontFamily: 'Open_Sans'),
          caption: TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
          button: TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
          subtitle2:
              TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
          subtitle1:
              TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
          headline1:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline2:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline3:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline4:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline5:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          headline6:
              TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w700),
          overline: TextStyle(fontFamily: 'Open_Sans'),
          bodyText1: TextStyle(fontFamily: 'Open_Sans'),
          bodyText2: TextStyle(fontFamily: 'Open_Sans'),
          caption: TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
          button: TextStyle(fontFamily: 'Open_Sans', fontWeight: FontWeight.w500),
        ),
      ),
      title: "AntNupTracker",
      home: FutureBuilder(
        future: _firebaseInitialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // print("Finished with error!!!!");
            // print(snapshot.error!);
            // print(snapshot.stackTrace!);
            return Center(
              child: Image(
                image: Theme.of(context).isDarkMode
                    ? const AssetImage(
                        "assets/cartoon_ant/dark/cartoon_ant.png")
                    : const AssetImage("assets/cartoon_ant/cartoon_ant.png"),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            final messaging = FirebaseMessaging.instance;
            messaging
                .requestPermission(
                    alert: true, badge: true, provisional: false, sound: true)
                .then((value) {
              // print("User granted permission: ${value.authorizationStatus}");
              FirebaseMessaging.instance.getToken().then((token) {
                SessionManager.shared.firebaseToken = token;
                // print("Device token is $token");
                // print("It is ${token?.length ?? 0} characters long!");
              });
            });
            return const NewFlightListScreen();
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // locale: const Locale("fr"),
      debugShowCheckedModeBanner: false,
      // darkTheme: ThemeData.dark()
      //     .copyWith(
      //   accentColor: Colors.blue[700],
      //   primaryColor: Colors.blue[800],
      //   primaryColorDark: Colors.blue[900],
      //   backgroundColor: Colors.indigo[800],
      //   scaffoldBackgroundColor: Colors.indigo[900],
      //   dialogBackgroundColor: Colors.blue[900],
      //   buttonColor: Colors.deepPurple[800],
      //   highlightColor: Colors.deepPurple[800],
      //   cardColor: Colors.blue[700],
      // ),
    );
    // ;
  }
}

// class AntNupTrackerApp extends StatelessWidget {
//   const AntNupTrackerApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: "AntNupTracker",
//         home: const NewFlightListScreen(),
//         localizationsDelegates: AppLocalizations.localizationsDelegates,
//         supportedLocales: AppLocalizations.supportedLocales,
//         // locale: const Locale("fr"),
//         debugShowCheckedModeBanner: false,
//         darkTheme: ThemeData.dark()
//         //     .copyWith(
//         //   accentColor: Colors.blue[700],
//         //   primaryColor: Colors.blue[800],
//         //   primaryColorDark: Colors.blue[900],
//         //   backgroundColor: Colors.indigo[800],
//         //   scaffoldBackgroundColor: Colors.indigo[900],
//         //   dialogBackgroundColor: Colors.blue[900],
//         //   buttonColor: Colors.deepPurple[800],
//         //   highlightColor: Colors.deepPurple[800],
//         //   cardColor: Colors.blue[700],
//         // ),
//         );
//   }
// }

class NewFlightListScreen extends StatefulWidget {
  const NewFlightListScreen({Key? key}) : super(key: key);

  @override
  _NewFlightListScreenState createState() => _NewFlightListScreenState();
}

class _NewFlightListScreenState extends State<NewFlightListScreen> {
  late AppLocalizations _appLocalizations;

  final _animatedStateKey = GlobalKey<AnimatedListState>();
  // var _animatedStateKey = GlobalKey<AnimatedListState>();

  // final _flightStore = FlightStore();
  final _flights = <Flight>[];

  late Future<int> _fetchFlightsFuture;
  late InitialLoadingProgress _loadingProgress;

  Future<int> _generateFlightReadFuture([bool loadTaxonomy = true]) async {
    if (loadTaxonomy) {
      // await TaxonomyManager.shared.loadSpecies();
      _loadingProgress.loadingStage = LoadingStage.taxonomy;
      await loadTaxonomyFromServer();
    }

    _loadingProgress.loadingStage = LoadingStage.flights;
    var flightsRead = await FlightStore.shared.load();

    _loadingProgress.loadingStage = LoadingStage.done;

    return flightsRead;

    // if (loadTaxonomy){
    //   return await TaxonomyManager.shared.loadTaxonomy().then((_) => FlightStore.shared.load());
    // } else {
    //   return await FlightStore.shared.load();
    // }
  }

  void _triggerFlightListFetch([bool loadTaxonomy = true]) {
    setState(() {
      // _fetchFlightsFuture = _flightStore.load();
      _fetchFlightsFuture = _generateFlightReadFuture(loadTaxonomy);
    });
  }

  // Future<void> _checkForNewFlights() async {
  //   final changedFlights =
  //       await FlightStore.shared.updateFlights(loadedFlights: _flights.length);
  //
  //   final newFlights =
  //       LinkedHashMap<int, Tuple2<Flight, FlightChange>>.from(changedFlights);
  //
  //   newFlights.removeWhere(
  //       (index, flightTuple) => flightTuple.item2 == FlightChange.update);
  //
  //   for (var index in newFlights.keys) {
  //     print("Inserting new row!");
  //     final newFlight = newFlights[index]!.item1;
  //
  //     print("Inserted at index $index");
  //
  //     _flights.insert(index, newFlight);
  //
  //     // _flightRows.insert(
  //     //     index,
  //     //     FlightRow(
  //     //       newFlight,
  //     //       key: UniqueKey(),
  //     //     ));
  //     _animatedStateKey.currentState!
  //         .insertItem(index, duration: const Duration(milliseconds: 500));
  //   }
  //
  //   final updatedFlights =
  //       LinkedHashMap<int, Tuple2<Flight, FlightChange>>.from(changedFlights);
  //   updatedFlights.removeWhere(
  //       (index, flightTuple) => flightTuple.item2 == FlightChange.inserted);
  //
  //   for (var index in updatedFlights.keys) {
  //     final changedFlight = updatedFlights[index]!.item1;
  //
  //     //   setState(() => _flightRows[index] = FlightRow(
  //     //         changedFlight,
  //     //         key: UniqueKey(),
  //     //       ));
  //     // }
  //     setState(() {
  //       _flights[index] = changedFlight;
  //     });
  //   }
  // }

  Future<void> _checkForNewFlights() async {
    // final changedFlights =
    // await FlightStore.shared.updateFlights(loadedFlights: _flights.length);

    final newFlights = await FlightStore.shared.updateFlights();

    for (var index in newFlights) {
      _animatedStateKey.currentState!
          .insertItem(index, duration: const Duration(milliseconds: 500));
    }

    setState(() {});
  }

  void _readMoreFlights([int n = 15]) {
    if (!FlightStore.shared.canRead) return;

    _isLoading = true;
    final flightsCount = FlightStore.shared.loadedFlightCount;

    // print(
    //     "Loading more flights... There are currently $flightsCount loaded flights.");
    FlightStore.shared.getNextFlights(count: n).then((numLoaded) {
      // print("Got $numLoaded more flights!");

      for (var i = 0; i < numLoaded; i++) {
        _animatedStateKey.currentState!.insertItem(flightsCount + i);
        // print("Inserting item at ${flightsCount + i}");
      }
      // print("Done loading");

      // var totalRowCount = flightsCount + numLoaded;

      _isLoading = false;

      // print(
      //     "Done adding all the rows! There are now ${FlightStore.shared.loadedFlightCount} loaded flights.");
    });
  }

  var _hasReloaded = false;

  Widget _buildFilteringButton() {
    return IconButton(
      icon: const Icon(Icons.filter_alt),
      tooltip: _appLocalizations.filteringAndSorting,
      onPressed: () async {
        // final currentLocation = await getCurrentLocation();
        final didChangeFiltering = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
              // builder: (context) => FilteringScreen(currentLocation: currentLocation),
              builder: (context) => const FilteringScreen(),
              fullscreenDialog: true),
        );

        if (didChangeFiltering ?? false) {
          _flights.clear();
          // print("Flight list cleared");
          // while (_flights.isNotEmpty) {
          //   final flight = _flights.removeAt(0);
          //
          //   _animatedStateKey.currentState!
          //       .removeItem(0, (context, animation) => FlightRow(flight));
          // }
          _hasReloaded = true;
          _isLoading = true;
          // setState(() {
          //   _animatedStateKey = GlobalKey<AnimatedListState>();
          // });
          _triggerFlightListFetch(false);
        }
      },
    );
  }

  Future<void> loadTaxonomyData() async {
    _loadingProgress.loadingStage = LoadingStage.taxonomy;

    await loadTaxonomy();
  }

  Future<void> loadCredentialsAndFiltering() async {
    // await loadTaxonomyFromServer();

    _loadingProgress.loadingStage = LoadingStage.credentials;
    try {
      final didLoadCredentials =
          await SessionManager.shared.loadAndVerifyCredentials();
      if (didLoadCredentials) {
        setState(() {});
      } else {
        await showLoginScreen(context);
      }
    } on LocalisableException catch (error, stacktrace) {
      // final localisableException = error as LocalisableException;
      final title = error.getLocalisedName(context);
      final body = error.getLocalisedDescription(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
        ),
      );
    }

    // _loadingProgress.loadingStage = LoadingStage.taxonomy;
    //
    // await loadTaxonomy();

    _loadingProgress.loadingStage = LoadingStage.filtering;
    await FilteringManager.shared.loadFilters();
  }

  @override
  void initState() {
    super.initState();
    initializeTimeZones();
    _loadingProgress = InitialLoadingProgress();
    _fetchFlightsFuture =
        resetWelcomeScreen(shouldReset: false)
        .then((_) => LicenseRegistry.addLicense(() async* {
              final ofl = await rootBundle.loadString("fonts/Dosis/OFL.txt");
              yield LicenseEntryWithLineBreaks(['Dosis'], ofl);

              final apache = await rootBundle.loadString("fonts/Open_Sans/LICENSE.txt");
              yield LicenseEntryWithLineBreaks(['Open Sans'], apache);
            }))
        .then((_) async {
          // print("At stage: Loading taxonomy");
          await loadTaxonomyData();
        })
        .then((_) async {
          // print("At stage: Showing Welcome Screen");
          await showWelcomeScreen(context);
        })
        .then((_) async {
          // print("At stage: Loading credentials and filtering");
          await loadCredentialsAndFiltering();
        })
        // loadTaxonomyAndCredentialsAndFiltering()
        .then((_) async {
          // print("At stage: reading flight list");
          return await _generateFlightReadFuture(false);
        });
    // SessionManager.shared.loadAndVerifyCredentials().then((value) {
    //   print("Credentials loaded $value");
    //   if (value) setState(() {});
    // }).catchError((error) {
    //   final localisableException = error as LocalisableException;
    //   final title = localisableException.getLocalisedName(context);
    //   final body = localisableException.getLocalisedDescription(context);
    //
    //   showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //       title: Text(title),
    //       content: Text(body),
    //     ),
    //   );
    // }, test: (error) => error is LocalisableException);
    // _fetchFlightsFuture = _flightStore.getTopFlights();
  }

  Future<void> showLoginScreen(BuildContext context) async {
    if (!kIsWeb &&
        MediaQuery.of(context).orientation ==
            Orientation.landscape &&
        MediaQuery.of(context).size.height < 500) {
      final didLogIn =
      await Navigator.of(context).push(MaterialPageRoute<bool>(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                child: const LoginForm()),
          ),
          fullscreenDialog: true));
      if (didLogIn ?? false) {
        setState(() {});
      }
    } else {
      final didLogIn = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => const Dialog(
            // title: Text(
            //     AppLocalizations.of(context)!.loginAppBarHeader),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: LoginForm(),
            ),
          ),
        barrierDismissible: false
      );

      if (didLogIn ?? false) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _appLocalizations = AppLocalizations.of(context)!;
    // print("There are ${_flights.length} flights.");

    final labelStyle =
        Theme.of(context).textTheme.bodyText2!.apply(fontSizeDelta: 4.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AntNupTracker",
          // style: TextStyle(fontFamily: 'Dosis', fontWeight: FontWeight.w800),
        ),
        // bottom: _isLoading ? const AppBarProgressIndicator(appBarHeight: 8) : null,
        // primary: true,
        leading: IconButton(
          icon: const Icon(Icons.info),
          tooltip: AppLocalizations.of(context)!.infoButton,
          // onPressed: ()=>showDialog(context: context, builder: (context) => const Dialog(child: WelcomeScreen()),),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const WelcomeScreen(),
                fullscreenDialog: true),
          ),
        ),
        actions: [
          _buildFilteringButton(),
          if (!SessionManager.shared.isLoggedIn)
            IconButton(
              // onPressed: () => Navigator.of(context).push(
              //   MaterialPageRoute(
              //     builder: (context) => LoginScreen(),
              //     fullscreenDialog: true,
              //   ),
              // ),
              // onPressed: () => showLoginScreen(context),
              onPressed: null,
              icon: const Icon(Icons.login),
              tooltip: AppLocalizations.of(context)!.loginButtonHeader,
              // child: Text(
              //   AppLocalizations.of(context)!.loginButtonHeader,
              //   style:
              //       TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              // ),
            ),
          if (SessionManager.shared.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () async {
                var didLogOut = await Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (context) => const UserProfileScreen(),
                    fullscreenDialog: true,
                  ),
                );

                // print("Did log out is $didLogOut");

                if (didLogOut ?? false) {
                  _flights.clear();
                  setState(() {});
                  showLoginScreen(context);
                }
                // SessionManager.shared.logout();
              },
              tooltip: SessionManager.shared.session!.username,
            )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: FutureBuilder(
            future: _fetchFlightsFuture,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              _isLoading = true;

              if (snapshot.connectionState != ConnectionState.done) {
                final progress = _loadingProgress.getProgress();
                // print("Progress is currently: $progress");
                final caption = _loadingProgress.getProgressCaption(context);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(value: progress),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        caption,
                        style: labelStyle,
                      )
                    ],
                  ),
                );
              }

              if (snapshot.hasData) {
                // final newFlights = snapshot.data!;
                // print("Loaded ${newFlights.length} flights!!!");
                // print("Loaded IDs: ${newFlights.map((e) => e.flightID)}");
                // print(
                //     "Current flights: ${_flights.take(15).map((e) => e.flightID)}");
                // _updateFlights(_currentFrame.results);
                // _flights
                // ..clear()
                // ..addAll(_currentFrame.results);
                _isLoading = false;

                if (_hasReloaded) {
                  // _flights.clear();
                  _hasReloaded = false;
                  // _flights.clear();
                }

                // if (_flights.isEmpty) {
                //   _flights.addAll(newFlights);
                // }

                // print(
                //     "There are ${FlightStore.shared.loadedFlightCount} loaded flights");

                if (snapshot.data! == 0) {
                  return ExceptionWidget(
                    NoFlightResultsException(),
                    null,
                    icon: Icons.info,
                  );
                }

                return _buildFlightListTable();
              } else if (snapshot.hasError) {
                // print("Error!!!!");
                // print(snapshot.error);
                // print(snapshot.stackTrace);
                if (snapshot.error! is! LocalisableException) {
                  // print(snapshot.error!);
                  // print(snapshot.stackTrace!);
                  return Image(
                    image: Theme.of(context).isDarkMode
                        ? const AssetImage(
                            "assets/cartoon_ant/dark/cartoon_ant.png")
                        : const AssetImage(
                            "assets/cartoon_ant/cartoon_ant.png"),
                  );
                }
                final error = snapshot.error as LocalisableException;
                return ExceptionWidget(error, () => _triggerFlightListFetch());
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
      floatingActionButton: _buildAddFlightButton(),
    );
  }

  Widget? _buildAddFlightButton() {
    if (SessionManager.shared.isLoggedIn) {
      return FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.gettingLocation),
                    content: const LinearProgressIndicator(),
                  ),
              barrierDismissible: false);
          final currentLocation = await getCurrentLocation();
          Navigator.of(context).pop();
          var shouldReload = await Navigator.of(context).push(
              MaterialPageRoute<bool>(
                  builder: (context) =>
                      FlightFormScreen(currentLocation: currentLocation),
                  // const FlightFormScreen(),
                  fullscreenDialog: true));

          // print("There are currently ${_flights.length} rows");
          // print(_flights.map((e) => e.flightID));
          if (shouldReload ?? false) await _checkForNewFlights();
          // print("There are currently ${_flights.length} rows");
          // print(_flights.map((e) => e.flightID));
        },
        tooltip: AppLocalizations.of(context)!.addNewFlightButton,
      );
      // return FloatingActionButton(
      //   child: Icon(Icons.add),
      //   onPressed: () => showDialog(
      //       context: context,
      //       builder: (context) => Dialog(child: FlightFormScreen())),
      //   tooltip: AppLocalizations.of(context)!.addNewFlightButton,
      // );
    }

    return null;
  }

  bool _isLoading = false;

  Widget _buildFlightListTable() {
    // _flightRows.addAll(flights.map((e) => FlightRow(
    //       e,
    //       key: UniqueKey(),
    //     )));

    // _flights.addAll(flights);

    // print(
    // "First 15 flights have indices: ${_flights.take(15).map((e) => e.flightID)}");

    // print(
    //     "There are now ${FlightStore.shared.loadedFlightCount} loaded flights");

    _isLoading = false;

    return RefreshIndicator(
      onRefresh: _checkForNewFlights,
      child: Scrollbar(
        child: AnimatedList(
          primary: true,
          key: _animatedStateKey,
          physics: const AlwaysScrollableScrollPhysics(),
          // initialItemCount: _flights.length,
          initialItemCount: FlightStore.shared.loadedFlightCount,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          itemBuilder: (context, index, animation) {
            // print("Building at index $index");
            // print("The initial item count is ${FlightStore.shared.loadedFlightCount}");
            // print("There are ${_flightRows.length} rows loaded");
            if (!_isLoading &&
                index >= FlightStore.shared.loadedFlightCount - 3) {
              _readMoreFlights();
            }

            // if (_isLoading && index == FlightStore.shared.loadedFlightCount) {
            //   const SizedBox(height: 48, child: CircularProgressIndicator(),);
            // }

            // return _flightRows[index];

            final flight = FlightStore.shared.getFlightAtIndex(index);

            return SizeTransition(
                sizeFactor: animation.drive(CurveTween(curve: Curves.easeIn)),
                // child: FlightRow(_flights[index]));
                child: FlightRow(
                  flight,
                  key: ValueKey(flight.flightID),
                ));

            // return SlideTransition(
            //     position: animation.drive(
            //       Tween(
            //         begin: const Offset(-1, 0),
            //         end: Offset.zero,
            //       ),
            //     ),
            //     child: FlightRow(_flights[index]));
          },
        ),
      ),
    );
  }
}

class FlightRow extends StatelessWidget {
  const FlightRow(this.flight, {Key? key}) : super(key: key);

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final currentLocale = appLocalizations.localeName;
    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (BuildContext context) {
        return FlightDetailScreen(flight.flightID, initialValue: null);
      })),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                // child: (flight.validationLevel == Role.professional) ? Icon(Icons.check_circle, size: 32.0) : Icon(null, size: 32.0)
                child: _getFlightIcon()),
            Expanded(
              child: Column(
                children: [
                  Text("${flight.taxonomy} (#${flight.flightID})",
                      style: Theme.of(context).textTheme.headline6),
                  Text(
                    stringFromCoordinates(
                        latitude: flight.latitude, longitude: flight.longitude),
                    // style: const TextStyle(fontFamily: 'Open_Sans'),
                  ),
                  Text(
                    intl.DateFormat.yMMMd(currentLocale)
                        .add_jm()
                        .format(flight.dateOfFlight),
                    // style: const TextStyle(fontFamily: 'Open_Sans'),
                  ),
                  Row(
                    children: [
                      // TextButton(
                      //   child: Text(flight.owner),
                      //   onPressed: null,
                      // ),
                      Text(
                        flight.owner,
                        // style: const TextStyle(fontFamily: 'Open_Sans'),
                      ),
                      if (flight.ownerRole == Role.flagged)
                        // const Icon(Icons.warning, color: Colors.red),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: const Image(
                            image: AssetImage("assets/ant_circles/red_ant.png"),
                            width: 16.0,
                          ),
                        ),
                      if (flight.ownerRole == Role.professional)
                        // const Icon(Icons.verified, color: Colors.green)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: const Image(
                            image:
                                AssetImage("assets/ant_circles/green_ant.png"),
                            width: 16.0,
                          ),
                        )
                    ],
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getFlightIcon() {
    IconData? icon;
    Color? colour;
    switch (flight.validationLevel) {
      case Role.citizen:
        icon = null;
        colour = null;
        break;
      case Role.professional:
        icon = Icons.verified;
        colour = Colors.green;
        break;
      case Role.flagged:
        icon = Icons.warning;
        colour = Colors.red;
        break;
    }

    return Icon(icon, size: 32.0, color: colour);
  }
}
