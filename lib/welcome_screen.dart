/*
 * welcome_screen.dart
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

import 'package:ant_nup_tracker/first_time_screen.dart';
import 'package:ant_nup_tracker/launch_url.dart';
import 'package:ant_nup_tracker/url_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dark_mode_theme_ext.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
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
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(appLocalizations.viewFlightList),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image(
                      image:
                          const AssetImage("assets/ant_circles/white_ant.png"),
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
                      image:
                          const AssetImage("assets/ant_circles/white_ant.png"),
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
                      image:
                          const AssetImage("assets/ant_circles/white_ant.png"),
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
            )
          ],
        ),
      ),
    );
  }
}

Future<void> showWelcomeScreen(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // prefs.remove('hasLoadedWelcome');
  // print("Preparing to show welcome screen.");

  if (!(prefs.getBool("hasLoadedWelcome") ?? false)) {
    // await Navigator.of(context).push(MaterialPageRoute(
    //     fullscreenDialog: true, builder: (_) => const WelcomeScreen()));

    await Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true, builder: (_) => const FirstTimeScreen()));

    prefs.setBool("hasLoadedWelcome", true);
  }
}

Future<void> resetWelcomeScreen({bool shouldReset = true}) async {
  if (!shouldReset) return;

  final prefs = await SharedPreferences.getInstance();

  prefs.setBool('hasLoadedWelcome', false);
}
