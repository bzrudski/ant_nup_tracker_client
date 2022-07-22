/*
 * first_time_screen.dart
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

import 'package:ant_nup_tracker/common_ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'launch_url.dart';
import 'url_manager.dart';
import 'filtering.dart';
import 'dark_mode_theme_ext.dart';

// Plan for the first login screen
/*
  First page: Cartoon ant, welcome, broad overview
  Second page: Load taxonomy, select filtering (eventually include count for how many flights will be loaded)
  Third page: Create account or login
  Last page: big picture about project & useful links
 */

class FirstTimeScreen extends StatefulWidget {
  const FirstTimeScreen({Key? key}) : super(key: key);

  @override
  _FirstTimeScreenState createState() => _FirstTimeScreenState();
}

class _FirstTimeScreenState extends State<FirstTimeScreen> {
  final PageController _pageController = PageController(initialPage: 0);

  final pageCount = 3;

  Future<void> goToPreviousPage() async => await _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
  Future<void> goToNextPage() async => await _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(appLocalizations.welcomeHeader),
      ),
      body: SafeArea(
        child: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (_) => setState(() {}),
          children: [
            SimpleWelcomeScreen(
              pageController: _pageController,
            ),
            PermissionsScreen(
              pageController: _pageController,
            ),
            InitialSettingsScreen(
              pageController: _pageController,
            ),
            MoreDetailsWelcome(
              pageController: _pageController,
            )
          ],
        ),
      ),
    );
  }
}

abstract class PageScreen {
  PageController get pageController;
  Duration get duration;
  Curve get nextCurve;
  Curve get previousCurve;

  void onNextPage();
  void onPreviousPage();
  void onDone();
}

class SimpleWelcomeScreen extends StatelessWidget implements PageScreen {
  const SimpleWelcomeScreen({
    Key? key,
    required this.pageController,
    this.duration = const Duration(milliseconds: 50),
    this.nextCurve = Curves.easeIn,
    this.previousCurve = Curves.easeOut,
  }) : super(key: key);

  @override
  final PageController pageController;

  @override
  final Duration duration;

  @override
  final Curve nextCurve;

  @override
  final Curve previousCurve;

  @override
  void onNextPage() {
    pageController.nextPage(duration: duration, curve: nextCurve);
  }

  @override
  void onPreviousPage() {}

  @override
  void onDone() {}

  // final void Function()? onNextButtonPress;
  // final void Function()? onPreviousButtonPress;
  //
  // bool get _shouldShowButtons =>
  //     onPreviousButtonPress != null || onNextButtonPress != null;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          appLocalizations.welcomeHeader,
          style: Theme.of(context).textTheme.headline5,
          textAlign: TextAlign.center,
        ),
        Image(
          image: Theme.of(context).isDarkMode ? const AssetImage("assets/cartoon_ant/dark/cartoon_ant.png") : const AssetImage("assets/cartoon_ant/cartoon_ant.png"),
          height: 200,
          matchTextDirection: true,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image(
                  image: const AssetImage("assets/ant_circles/white_ant.png"),
                  color: Theme.of(context).textTheme.headline6!.color,
                  colorBlendMode: BlendMode.srcATop,
                ),
              ),
              Expanded(
                child: Text(
                  appLocalizations.welcomeBullet1,
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image(
                  image: const AssetImage("assets/ant_circles/white_ant.png"),
                  color: Theme.of(context).textTheme.headline6!.color,
                  colorBlendMode: BlendMode.srcATop,
                ),
              ),
              Expanded(
                  child: Text(
                appLocalizations.welcomeBullet2,
                style: Theme.of(context).textTheme.headline6,
              )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image(
                  image: const AssetImage("assets/ant_circles/white_ant.png"),
                  color: Theme.of(context).textTheme.headline6!.color,
                  colorBlendMode: BlendMode.srcATop,
                ),
              ),
              Expanded(
                  child: Text(
                appLocalizations.welcomeBullet3,
                style: Theme.of(context).textTheme.headline6,
              )),
            ],
          ),
        ),
        NextPreviousButtonRow(
          onNextPage: onNextPage,
        )
      ],
    );
  }
}

class PermissionsScreen extends StatelessWidget implements PageScreen {
  const PermissionsScreen({
    Key? key,
    required this.pageController,
    this.duration = const Duration(milliseconds: 50),
    this.nextCurve = Curves.easeIn,
    this.previousCurve = Curves.easeOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    const textStyle = TextStyle(fontSize: 14);

        // Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14);
    var headingStyle = Theme.of(context).textTheme.headline6;
        // textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 18);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          appLocalizations.appPermissionsHeader,
          style: Theme.of(context).textTheme.headline5,
          textAlign: TextAlign.center,
        ),
        Text(
          appLocalizations.appPermissionsSubtitle,
          style: textStyle,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.location_pin,
                  color: Theme.of(context).textTheme.headline6!.color,
                  size: 32.0,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Align(
                      child: Text(
                        appLocalizations.location,
                        style: headingStyle,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    Text(
                      appLocalizations.locationPermissionDetails,
                      style: textStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).textTheme.headline6!.color,
                  size: 32.0,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Align(
                      child: Text(
                        appLocalizations.camera,
                        style: headingStyle,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    Align(
                      child: Text(
                        appLocalizations.cameraPermissionDetails,
                        style: textStyle,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.photo,
                  color: Theme.of(context).textTheme.headline6!.color,
                  size: 32.0,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Align(
                      child: Text(
                        appLocalizations.gallery,
                        style: headingStyle,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    Text(
                      appLocalizations.galleryPermissionDetails,
                      style: textStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          appLocalizations.permissionsScreenBottomNote,
          style: textStyle,
        ),
        NextPreviousButtonRow(
          onPreviousPage: onPreviousPage,
          onNextPage: onNextPage,
        )
      ],
    );
  }

  @override
  final Curve nextCurve;

  @override
  final Curve previousCurve;

  @override
  final Duration duration;

  @override
  void onDone() {}

  @override
  Future<void> onNextPage() async {
    // Request permissions
    await [Permission.location, Permission.camera, Permission.photos, Permission.storage].request();

    pageController.nextPage(duration: duration, curve: nextCurve);
  }

  @override
  void onPreviousPage() {
    pageController.previousPage(duration: duration, curve: previousCurve);
  }

  @override
  final PageController pageController;
}

class InitialSettingsScreen extends StatefulWidget implements PageScreen {
  const InitialSettingsScreen({
    Key? key,
    required this.pageController,
    this.duration = const Duration(milliseconds: 250),
    this.nextCurve = Curves.easeIn,
    this.previousCurve = Curves.easeOut,
  }) : super(key: key);

  // final void Function()? onPreviousButtonPress;
  // final void Function()? onNextButtonPress;

  @override
  _InitialSettingsScreenState createState() => _InitialSettingsScreenState();

  @override
  final Duration duration;

  @override
  final PageController pageController;

  @override
  final Curve previousCurve;

  @override
  final Curve nextCurve;

  @override
  void onDone() {}

  @override
  void onNextPage() async {
    await FilteringManager.shared.saveFilters();
    pageController.nextPage(duration: duration, curve: nextCurve);
  }

  @override
  void onPreviousPage() {
    pageController.previousPage(duration: duration, curve: previousCurve);
  }
}

class _InitialSettingsScreenState extends State<InitialSettingsScreen> {
  // bool get _shouldShowButtons =>
  //     widget.onPreviousButtonPress != null || widget.onNextButtonPress != null;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        HeaderRow(label: appLocalizations.setUpSorting),
        SortingSection(
          ordering: FilteringManager.shared.ordering,
          direction: FilteringManager.shared.direction,
          locationFilter: FilteringManager.shared.locationFilter,
          onSortingChanged: (ordering, direction, locationFilter) {
            FilteringManager.shared.ordering = ordering;
            FilteringManager.shared.direction = direction;
            FilteringManager.shared.locationFilter = locationFilter;
            // print("Now selected location: ${locationFilter?.location ?? "None"}.");
          },
        ),
        HeaderRow(label: appLocalizations.setUpFiltering),
        TaxonomyFilteringRow(
          filter: FilteringManager.shared.taxonomyFilter,
          onFilteringChanged: (taxonomyFilter) =>
              FilteringManager.shared.taxonomyFilter = taxonomyFilter,
        ),
        DateFilteringRow(
          filter: FilteringManager.shared.dateFilter,
          onFilteringChanged: (dateFilter) =>
              FilteringManager.shared.dateFilter = dateFilter,
        ),
        ImageFilteringRow(
          filter: FilteringManager.shared.imageFilter,
          onFilteringChanged: (imageFilter) =>
              FilteringManager.shared.imageFilter = imageFilter,
        ),
        VerificationFilteringRow(
          filter: FilteringManager.shared.verificationFilter,
          onFilteringChanged: (verificationFilter) =>
              FilteringManager.shared.verificationFilter = verificationFilter,
        ),
        NextPreviousButtonRow(
          onNextPage: widget.onNextPage,
          onPreviousPage: widget.onPreviousPage,
        )
      ],
    );
  }
}

class MoreDetailsWelcome extends StatelessWidget implements PageScreen {
  const MoreDetailsWelcome({
    Key? key,
    required this.pageController,
    this.duration = const Duration(milliseconds: 250),
    this.nextCurve = Curves.easeIn,
    this.previousCurve = Curves.easeOut,
  }) : super(key: key);

  @override
  final Duration duration;

  @override
  final PageController pageController;

  @override
  final Curve previousCurve;

  @override
  final Curve nextCurve;

  @override
  void onDone() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasLoadedWelcome', true);
  }

  @override
  void onNextPage() async {}

  @override
  void onPreviousPage() {
    pageController.previousPage(duration: duration, curve: previousCurve);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Image(
          image: Theme.of(context).isDarkMode ? const AssetImage("assets/cartoon_ant/dark/cartoon_ant.png") : const AssetImage("assets/cartoon_ant/cartoon_ant.png"),
          height: 200,
          matchTextDirection: true,
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            appLocalizations.welcomeBodyText,
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(
          height: 32,
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            appLocalizations.welcomeBottomText,
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
        ),
        // ElevatedButton(
        //   onPressed: () => Navigator.of(context).pop(),
        //   child: Text(appLocalizations.viewFlightList),
        // ),
        const SizedBox(height: 32.0),
        ElevatedButton.icon(
          onPressed: () async {
            final urlString = UrlManager.shared.aboutUrl.toString();
            await launchUrl(urlString);
          },
          label: Text(appLocalizations.moreAboutUs),
          icon: const Icon(Icons.open_in_new),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final urlString = UrlManager.shared.privacyUrl.toString();
            await launchUrl(urlString);
          },
          label: Text(appLocalizations.privacyPolicy),
          icon: const Icon(Icons.open_in_new),
        ),
        ElevatedButton(
          onPressed: () {
            // Navigator.of(context).push(MaterialPageRoute(
            //   builder: (context) => const PackagesScreen(),
            // ));
            showLicensePage(context: context, applicationLegalese: appLocalizations.applicationLegalese, applicationIcon: Image(
              image: Theme.of(context).isDarkMode ? const AssetImage("assets/cartoon_ant/dark/cartoon_ant.png") : const AssetImage("assets/cartoon_ant/cartoon_ant.png"),
              height: 80,
              matchTextDirection: true,
            ));
          },
          child: Text(appLocalizations.packagesInfo),
        ),
        NextPreviousButtonRow(
          onPreviousPage: onPreviousPage,
          onDone: () {
            onDone();

            // Pop to show the list
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}

class NextPreviousButtonRow extends StatelessWidget {
  const NextPreviousButtonRow({
    Key? key,
    this.onNextPage,
    this.onPreviousPage,
    this.onDone,
  }) : super(key: key);

  final void Function()? onNextPage;

  final void Function()? onPreviousPage;

  final void Function()? onDone;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (onPreviousPage != null)
          ElevatedButton(
              onPressed: onPreviousPage,
              child: Text(appLocalizations.previous)),
        if (onNextPage != null)
          ElevatedButton(
              onPressed: onNextPage, child: Text(appLocalizations.next)),
        if (onDone != null)
          ElevatedButton(onPressed: onDone, child: Text(appLocalizations.done))
      ],
    );
  }
}

// class NextPreviousButtonRow extends StatefulWidget {
//   const NextPreviousButtonRow({
//     Key? key,
//     required this.pageController,
//     required this.pageCount,
//     required this.duration,
//     required this.curve,
//     this.resizeDuration = const Duration(milliseconds: 50),
//     this.onFinished,
//   }) : super(key: key);
//
//   final int pageCount;
//   final PageController pageController;
//   final Duration duration;
//   final Curve curve;
//   final Duration resizeDuration;
//   final void Function()? onFinished;
//
//   @override
//   _NextPreviousButtonRowState createState() => _NextPreviousButtonRowState();
// }
//
// class _NextPreviousButtonRowState extends State<NextPreviousButtonRow> {
//   bool get isOnFirstPage =>
//       (widget.pageController.page ?? widget.pageController.initialPage)
//           .toInt() ==
//       0;
//   bool get isOnLastPage =>
//       (widget.pageController.page ?? widget.pageController.initialPage)
//           .toInt() ==
//       widget.pageCount - 1;
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context)!;
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         if (!isOnFirstPage)
//           ElevatedButton(
//               onPressed: () async {
//                 widget.pageController
//                     .previousPage(
//                         duration: widget.duration, curve: widget.curve)
//                     .then((value) => setState(() {}));
//               },
//               child: Text(appLocalizations.previous)),
//         // if (!isOnLastPage && !isOnFirstPage)
//         //   const SizedBox(
//         //     width: 48,
//         //   ),
//         if (!isOnLastPage)
//           ElevatedButton(
//               onPressed: () async {
//                 widget.pageController
//                     .nextPage(duration: widget.duration, curve: widget.curve)
//                     .then((value) => setState(() {}));
//               },
//               child: Text(appLocalizations.next)),
//         if (isOnLastPage)
//           ElevatedButton(
//               onPressed: () {
//                 if (widget.onFinished != null) {
//                   widget.onFinished!();
//                 }
//               },
//               child: Text(appLocalizations.done))
//       ],
//     );
//   }
// }

// class NextPreviousButtonRow extends StatelessWidget {
//   const NextPreviousButtonRow(
//       {Key? key,
//       required this.pageController,
//       required this.pageCount,
//       required this.duration,
//       required this.curve,
//       this.resizeDuration = const Duration(milliseconds: 50),
//       })
//       : super(key: key);
//
//   final int pageCount;
//   final PageController pageController;
//   final Duration duration;
//   final Curve curve;
//   final Duration resizeDuration;
//
//   bool get isOnFirstPage => pageController.page == 0;
//   bool get isOnLastPage => pageController.page == pageCount - 1;
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context)!;
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         if (!isOnFirstPage)
//           AnimatedContainer(
//             duration: resizeDuration,
//             width: isOnLastPage ? 400 : 250,
//             child: ElevatedButton(
//                 onPressed: () =>
//                     pageController.previousPage(duration: duration, curve: curve),
//                 child: Text(appLocalizations.previous)),
//           ),
//         if (!isOnFirstPage && !isOnLastPage)
//           const SizedBox(
//             width: 48,
//           ),
//         if (!isOnLastPage)
//           AnimatedContainer(
//             duration: resizeDuration,
//             width: isOnFirstPage ? 400 : 250,
//             child: ElevatedButton(
//                 onPressed: () =>
//                     pageController.nextPage(duration: duration, curve: curve),
//                 child: Text(appLocalizations.next)),
//           )
//       ],
//     );
//   }
// }
