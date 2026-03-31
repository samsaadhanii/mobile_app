import 'package:flutter/material.dart';
import 'package:mobile_app/Screens/home_page.dart';
import 'package:mobile_app/Screens/settings_page.dart';
import 'package:mobile_app/features/tools/tools_page_v2.dart';

import 'about_page.dart';
import 'contributors.dart';

class TabbedView extends StatefulWidget {
  const TabbedView({super.key, required this.title});
  final String title;

  @override
  State<TabbedView> createState() => _TabbedViewState();
}

/// *********************************************************************
/// Saṃsādhanī app for Android devices
/// This is the main screen for the app
/// It provides options for the user to select the home, tools, settings,
/// about and contributors screens using the CupertinoTabScaffold
/// *********************************************************************
class _TabbedViewState extends State<TabbedView> {
  int selectedTab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: loadSelectedPage(selectedTab),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withAlpha(180),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
            backgroundColor: Color(0xFF4DB6AC),
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/images/tools1.png")),
            label: 'Tools',
            backgroundColor: Color(0xFF4DB6AC),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
            backgroundColor: Color(0xFF4DB6AC),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'About',
            backgroundColor: Color(0xFF4DB6AC),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'Contributors',
            backgroundColor: Color(0xFF4DB6AC),
          ),
        ],
        onTap: (int index) {
          setState(() {
            selectedTab = index;
          });
        },
        currentIndex: selectedTab,
      ),
    );
  }

  Widget loadSelectedPage(index) {
    if (index == 0) {
      return HomePage(title: widget.title);
    } else if (index == 1) {
      return const ToolsPageV2();
    } else if (index == 2) {
      return const SettingsPage();
    } else if (index == 3) {
      return const AppAboutPage();
    } else if (index == 4) {
      return const Contributors();
    } else {
      return HomePage(title: widget.title);
    }
  }
}
