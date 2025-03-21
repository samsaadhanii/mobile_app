import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../widgets/app_logo.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ConnectivityResult> _connectionStatus = [];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool timedLogout = false;
  PackageInfo? packageInfo;
  String license = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    getPackageInfo();
  }

  Future<void> getPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      license = packageInfo?.version ?? '1';
      buildNumber = packageInfo?.buildNumber ?? '1';
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status $e');
      return;
    }

    if (!mounted) return;

    await _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    setState(() {
      _connectionStatus = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return check();
  }

  Widget check() {
    String txt = 'No internet connection';
    Widget res;
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      res = Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text(txt)),
      );
    } else {
      res = Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(
                      left: 30, top: 0, right: 30, bottom: 10),
                  height: 150.0,
                  child: appLogo,
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      RichText(
                        text: const TextSpan(
                          text:
                          '   Saṃsādhanī is a computational platform developed '
                              'at the Department of Sanskrit studies for Sanskrit '
                              'language processing. \n\n\n'
                              'It hosts several computational tools such as word  '
                              'analyser, word generator, sandhi joiner and sandhi '
                              'analyser, sentential analyser and sentence generator, '
                              'and also a  Sanskrit-Hindi Machine Translation system.'
                              '\n\n\n'
                              'The words are also linked to various monolingual and bilingual dictionaries.',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                            fontFamily: 'oswald',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return res;
  }
}