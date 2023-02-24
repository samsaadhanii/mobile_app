import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Screens/cpertino_tab.dart';
import 'Screens/home_page.dart';

class ThemeBlueWhite {
  static bool themeBlue = true;

  static Widget theApp(String title1) {
    print('themeBlue: $themeBlue');
    if (themeBlue) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: title1,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomePage(title: title1),
      );
    } else {
      return CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: title1,
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: SamCupertinoTab(),
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
}
