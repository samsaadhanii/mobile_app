import 'package:flutter/material.dart';
import 'package:mobile_app/Screens/home_page.dart';
import 'package:mobile_app/Screens/settings_page.dart';
import 'package:mobile_app/Screens/tools_page.dart';

import 'about_page.dart';

class TabbedView extends StatefulWidget {
  const TabbedView({super.key, required this.title});
  final String title;

  @override
  State<TabbedView> createState() => _TabbedViewState();
}

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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, color: Colors.white),
            label: 'Home',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/images/tools1.png"),
                color: Colors.white),
            label: 'Tools',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, color: Colors.white),
            label: 'Settings',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline, color: Colors.white),
            label: 'About',
            backgroundColor: Colors.blue,
          ),
        ],
        onTap: (int index) {
          // print('index: $index');
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
      return const ToolsPage();
    } else if (index == 2) {
      return const SettingsPage();
    } else if (index == 3) {
      return const AppAboutPage();
    } else {
      return HomePage(title: widget.title);
    }
  }
}
