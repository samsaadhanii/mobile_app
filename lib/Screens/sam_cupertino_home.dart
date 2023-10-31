import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import '../widgets/app_logo.dart';

class SamCupertinoHome extends StatefulWidget {
  const SamCupertinoHome({super.key, required this.title});
  final String title;

  @override
  State<SamCupertinoHome> createState() => _SamCupertinoHomeState();
}

class _SamCupertinoHomeState extends State<SamCupertinoHome> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  final Connectivity _connectivity = Connectivity();

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool timedLogout = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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
      res = CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
        child: Center(child: Text(txt)),
      );
    } else {
      res = CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
        child: Column(children: <Widget>[
          const SizedBox(height: 100),
          Container(
            alignment: Alignment.center,
            padding:
                const EdgeInsets.only(left: 30, top: 10, right: 30, bottom: 10),
            height: 150.00,
            child: appLogo,
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: RichText(
              text: const TextSpan(
                text: '   Saṃsādhanī is a computational platform developed '
                    'at the Department of Sanskrit studies for Sanskrit '
                    'language processing. \n\n\n'
                    'It hosts several computational tools such as word  '
                    'analyser, word generator, sandhi joiner and sandhi '
                    'analyser, sentential analyser and sentence generator, '
                    'and also a  Sanskrit-Hindi Machine Translation system.'
                    '\n\n\n'
                    'The words are also linked to various monolingual and bilingual dictionaries.',
                style: TextStyle(
                  color: CupertinoColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.normal,
                  // fontFamily: 'iFont',
                ),
              ),
            ),
          ),
        ]),
      );
    }
    return res;
  }
}
