import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Screens/home_page.dart';

class ThemeBlueWhite {
  static bool themeBlue = false;

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
        // home: CupertinoPageScaffold(
        //   navigationBar: CupertinoNavigationBar(
        //     middle: Text(title2),
        //     // leading: IconButton(
        //     //     onPressed: () {}, icon: const Icon(CupertinoIcons.back)),
        //   ),
        //   child: const Text('data'),
        //   // drawer: const SideDrawer(),
        // ),
        home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            currentIndex: 1,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.list_bullet), label: 'Tools'),
            ],
          ),
          tabBuilder: (context, index) {
            switch (index) {
              case 0:
                return CupertinoTabView(
                  builder: (context) {
                    return CupertinoPageScaffold(
                      navigationBar: CupertinoNavigationBar(
                        middle: Text(title1 ?? ''),
                      ),
                      child: Text('Home'),
                    );
                  },
                );
              case 1:
                return CupertinoTabView(
                  builder: (context) {
                    return const CupertinoPageScaffold(
                      navigationBar: CupertinoNavigationBar(
                        middle: Text('Tools'),
                      ),
                      child: Text('Tools'),
                    );
                  },
                );
              default:
                return CupertinoTabView(
                  builder: (context) {
                    return const CupertinoPageScaffold(
                      navigationBar: CupertinoNavigationBar(
                        middle: Text('Home'),
                      ),
                      child: Text('Home'),
                    );
                  },
                );
            }
          },
        ),
      );
    }
  }
}
