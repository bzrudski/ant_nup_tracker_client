/*
 * detail_screen.dart
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

import 'exceptions.dart';

abstract class DetailScreen<K, T> extends StatefulWidget {
  const DetailScreen(this.id, {this.initialValue, Key? key}) : super(key: key);

  @protected
  final K id;

  @protected
  final T? initialValue;

  // @override
  // _DetailScreenState createState() => _DetailScreenState();
}

abstract class DetailScreenState<K, T> extends State<DetailScreen<K, T>> {
  // DetailScreenState(this.id, {this.initialValue});
  DetailScreenState();

  @protected
  late final K id;

  @protected
  late final T? initialValue;

  @protected
  late Future<T> detailFuture;

  @protected
  void loadDetailFuture(K id, {bool forceReload = false});

  @override
  void initState() {
    super.initState();
    id = widget.id;
    initialValue = widget.initialValue;
    if (initialValue == null) {
      loadDetailFuture(id);
    } else {
      detailFuture = Future(() => initialValue!);
    }
  }

  @protected
  Widget buildDetailScreen(T result);

  /// Override to perform non-UI related data tasks
  @protected
  void processData(T data) {}

  @protected
  String get appBarHeader;

  @protected
  List<Widget> actions = [];

  Widget _buildMainBody(BuildContext context, AsyncSnapshot<T> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      // print("Loading the detail screen.");
      return const CircularProgressIndicator();
    }

    if (snapshot.hasData) {
      return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              loadDetailFuture(id, forceReload: true);
            });
          },
          child: buildDetailScreen(snapshot.data!));
    } else if (snapshot.hasError) {
      final error = snapshot.error! as LocalisableException;
      return ExceptionWidget(error, () => loadDetailFuture(id));
    } else {
      return const CircularProgressIndicator();
    }
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: detailFuture,
        builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            processData(snapshot.data!);
          }// else {
          //   print("Waiting for data.............................");
          // }

          return Scaffold(
            appBar: AppBar(
              title: Text(appBarHeader),
              actions: actions,
            ),
            body: SafeArea(
              child: Center(
                child: _buildMainBody(context, snapshot),
              ),
            ),
          );
        });
  }
}
