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
  // Always store as a list, but normalize input
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<dynamic> _connectivitySubscription;

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

  Future<void> initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (!mounted) return;
      _updateConnectionStatus(result);
    } on PlatformException catch (e) {
      debugPrint("Couldn't check connectivity status: $e");
    }
  }

  void _updateConnectionStatus(dynamic value) {
    // Normalize value → always a List<ConnectivityResult>
    List<ConnectivityResult> normalized;

    if (value is ConnectivityResult) {
      normalized = [value];
    } else if (value is List<ConnectivityResult>) {
      normalized = value;
    } else {
      normalized = [ConnectivityResult.none];
    }

    setState(() {
      _connectionStatus = normalized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    final hasConnection = !_connectionStatus.contains(ConnectivityResult.none);

    if (!hasConnection) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
        child: const Center(child: Text('No internet connection')),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(
                    left: 30, top: 10, right: 30, bottom: 10),
                height: 150.0,
                child: appLogo,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: RichText(
                  text: TextSpan(
                    text: '   Saṃsādhanī is a computational platform developed '
                        'at the Department of Sanskrit studies for Sanskrit '
                        'language processing.',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: RichText(
                  text: TextSpan(
                    text: 'It hosts several computational tools such as word  '
                        'analyser, word generator, sandhi joiner and sandhi '
                        'analyser, sentential analyser and sentence generator, '
                        'and also a Sanskrit-Hindi Machine Translation system.',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: RichText(
                  text: TextSpan(
                    text:
                        '   The words are also linked to various monolingual and bilingual dictionaries.',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
