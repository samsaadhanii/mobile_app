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

/// ************************************************************
/// This is the stateful class for the HomePage.
/// which displays the home page of the app with the app logo and a brief
/// description of the app. It also checks for the internet connection
/// and displays a message if there is no internet connection.
/// ************************************************************
class _HomePageState extends State<HomePage> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
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
    packageInfo != null
        ? print('packageInfo available')
        : print('packageInfo not available');
    license = packageInfo != null ? packageInfo!.version.toString() : '1';
    buildNumber =
        packageInfo != null ? packageInfo!.buildNumber.toString() : '1';
    print(license);
    print(buildNumber);
    //This is to make sure the fetched value of package info gets into UI
    setState(() {
      // _isLoading = true;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status $e');
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return check();
  }

  Widget check() {
    String txt = 'No internet connection';
    Widget res;
    if (_connectionStatus
            .toString()
            .compareTo(ConnectivityResult.none.toString()) ==
        0) {
      res = Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text(txt)),
      );
    } else {
      res = Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        // body: const Center(child: Text('Home Page')),
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
                  height: 150.00,
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
                // RichText(
                //   text: const TextSpan(
                //     text: '   Sanskrit is the primary culture-bearing language '
                //         'of India. We have witnessed a continuous production'
                //         ' of literature in Sanskrit in all fields of human'
                //         ' endeavour for several thousands of years.',
                //     style: TextStyle(
                //       color: Colors.grey,
                //       fontSize: 20,
                //       fontWeight: FontWeight.bold,
                //       fontStyle: FontStyle.italic,
                //     ),
                //   ),
                // ),
                // RichText(
                //   text: const TextSpan(
                //     text: '   During the past few decades, there has been an '
                //         'emerging trend among Indians to learn Sanskrit to read'
                //         ' and understand these original Sanskrit texts, '
                //         'especially the philosophical, mathematical and '
                //         'Āyurvedic manuscripts. Despite having a very well '
                //         'defined grammar, one finds it challenging to understand '
                //         'Sanskrit texts due to the complexity involved in'
                //         ' compound word-formation in Sanskrit, euphonic changes '
                //         'due to the influence of oral tradition, and the tendency'
                //         ' to use long compound expressions without word breaks.',
                //     style: TextStyle(
                //       color: Colors.grey,
                //       fontSize: 20,
                //       fontWeight: FontWeight.bold,
                //       fontStyle: FontStyle.italic,
                //     ),
                //   ),
                // ),
                // Container(),
                // Text('version: $license')
              ],
            ),
          ),
        ),
        // drawer: const SideDrawer(),
      );
    }
    return res;
  }
}
