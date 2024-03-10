import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Screens/cpertino_tab.dart';
import 'Screens/tabbed_view.dart';
import 'model/data_provider.dart';

/// *************************************************************************
/// The main entry point for the application
///   - This is where the app starts
///   - It provides the ChangeNotifierProvider for the DataProvider
///   - It provides the defaultTargetPlatform for the app
///   - It provides the MyHttpOverrides for the app
///   - It provides the runApp for the app
///   ***********************************************************************
void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataProvider(),
      child: defaultTargetPlatform == TargetPlatform.android
          ? const SamMaterial()
          : const SamCupertino(),
    ),
  );
}

String appTitle = 'Saṃsādhanī';

class SamMaterial extends StatefulWidget {
  const SamMaterial({super.key});

  @override
  State<SamMaterial> createState() => _SamMaterialState();
}

class _SamMaterialState extends State<SamMaterial> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TabbedView(title: appTitle),
    );
  }
}

class SamCupertino extends StatefulWidget {
  const SamCupertino({super.key});

  @override
  State<SamCupertino> createState() => _SamCupertinoState();
}

class _SamCupertinoState extends State<SamCupertino> {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      theme: const CupertinoThemeData(brightness: Brightness.light),
      home: const SamCupertinoTab(),
      // home: CupertinoPageScaffold(
      //   navigationBar: CupertinoNavigationBar(
      //     middle: Text(title1),
      //     // leading: IconButton(
      //     //     onPressed: () {}, icon: const Icon(CupertinoIcons.back)),
      //   ),
      //   child: Column(children: <Widget>[
      //     const Text('Align Button to the Bottom in Flutter'),
      //     Expanded(
      //       child: Align(
      //         alignment: Alignment.bottomCenter,
      //         child: CupertinoButton(
      //           onPressed: () {},
      //           child: const Text(
      //             'Tools',
      //             style: TextStyle(fontSize: 24),
      //           ),
      //         ),
      //       ),
      //     ),
      //   ]),
      //   // drawer: const SideDrawer(),
      // ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
