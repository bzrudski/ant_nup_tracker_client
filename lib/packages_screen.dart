/*
 * packages_screen.dart
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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'oss_licenses.dart';

class PackageRowInfo {
  PackageRowInfo({required this.package, this.showFullDetails = false});

  final Package package;
  bool showFullDetails;
}

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({Key? key}) : super(key: key);

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {

  final _packageInfo = <PackageRowInfo>[];

  @override
  void initState() {
    _packageInfo.clear();
    _packageInfo.addAll(ossLicenses.map((e) => PackageRowInfo(package: e)));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.packagesInfo),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView.separated(
            primary: true,
            itemBuilder: (context, index) => PackageRow(
              packageRowInfo: _packageInfo[index],
            ),
            itemCount: _packageInfo.length,
            padding: const EdgeInsets.all(8.0),
            separatorBuilder: (BuildContext context, int index) =>
            const Divider(),
          ),
        ),
      ),
    );
  }
}


// class PackagesScreen extends StatelessWidget {
//   const PackagesScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context)!;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(appLocalizations.packagesInfo),
//       ),
//       body: SafeArea(
//         child: Scrollbar(
//           child: ListView.separated(
//             primary: true,
//             itemBuilder: (context, index) => PackageRow(
//               package: ossLicenses[index],
//             ),
//             itemCount: ossLicenses.length,
//             padding: const EdgeInsets.all(8.0),
//             separatorBuilder: (BuildContext context, int index) =>
//                 const Divider(),
//           ),
//         ),
//       ),
//     );
//   }
// }

class PackageRow extends StatefulWidget {
  const PackageRow({
    Key? key,
    required this.packageRowInfo,
    this.duration = const Duration(milliseconds: 250),
  }) : super(key: key);

  final PackageRowInfo packageRowInfo;
  final Duration duration;

  @override
  State<PackageRow> createState() => _PackageRowState();
}

class _PackageRowState extends State<PackageRow> with TickerProviderStateMixin {
  // bool showFullDetails = false;

  late final AnimationController _animationController;
  late final _package = widget.packageRowInfo.package;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: widget.duration);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14);
    var headingStyle =
        textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 18);

    // final appLocalizations = AppLocalizations.of(context)!;

    return AnimatedSize(
      duration: widget.duration,
      alignment: Alignment.topCenter,
      child: InkWell(
        onTap: () {
          setState(() {
            widget.packageRowInfo.showFullDetails = !widget.packageRowInfo.showFullDetails;
          });
          if (widget.packageRowInfo.showFullDetails) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedRotation(turns: !widget.packageRowInfo.showFullDetails ? -0.25 : 0, duration: widget.duration, child: const Icon(Icons.expand_more),),
                  // AnimatedIcon(
                  //     icon: AnimatedIcons.menu_close,
                  //     progress: _animationController, size: 32,),
                  const SizedBox(width: 8.0,),
                  Expanded(
                      child: Text(
                    "${_package.name} ${_package.version}",
                    style: headingStyle,
                  )),
                  if (_package.homepage != null)
                    IconButton(
                        onPressed: () => launch(_package.homepage!),
                        icon: const Icon(Icons.open_in_new), tooltip: AppLocalizations.of(context)!.openPackageSite,)
                ],
              ),
              if (widget.packageRowInfo.showFullDetails) Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                      _package.description,
                      style: textStyle,
                    )),
                  ],
                ),
              ),
              // if (widget.package.homepage != null)
              //   Row(
              //     children: [
              //       GestureDetector(
              //         child: Expanded(child: Text(appLocalizations.openPackageSite)),
              //         onTap: () => launch(widget.package.homepage!),
              //       ),
              //     ],
              //   ),
              if (widget.packageRowInfo.showFullDetails && _package.license != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text( "\n" +
                        _package.license!,
                        style: textStyle,
                      )),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

}
