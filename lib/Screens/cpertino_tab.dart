import 'package:flutter/cupertino.dart';
import 'package:mobile_app/Screens/contributors.dart';
import 'package:mobile_app/Screens/cupertino_about.dart';
import 'package:mobile_app/Screens/sam_cupertino_home.dart';
import 'package:mobile_app/Screens/sam_cupertino_tools.dart';

import 'cupertino_settings.dart';

class SamCupertinoTab extends StatefulWidget {
  const SamCupertinoTab({Key? key}) : super(key: key);

  @override
  State<SamCupertinoTab> createState() => _SamCupertinoTabState();
}

/// *********************************************************************
/// Saṃsādhanī app for Cupertino (iOS) devices
/// This is the main screen for the app
/// It provides options for the user to select the home, tools, settings,
/// about and contributors screens using the CupertinoTabScaffold
/// *********************************************************************
class _SamCupertinoTabState extends State<SamCupertinoTab> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/images/tools1.png")),
            // icon: Icon(CupertinoIcons.list_bullet),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings_solid),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.info_circle),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.group_solid),
            label: 'Contributors',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            if (index == 0) {
              return const SamCupertinoHome(title: 'Saṃsādhanī');
            } else if (index == 1) {
              return const SamCupertinoTools();
            } else if (index == 2) {
              return const CupertinoSettings();
            } else if (index == 3) {
              return const CupertinoAboutPage();
            } else if (index == 4) {
              return const Contributors();
            } else {
              return const SamCupertinoHome(title: 'Saṃsādhanī');
            }
          },
        );
      },
    );
  }
}
