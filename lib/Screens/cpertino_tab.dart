import 'package:flutter/cupertino.dart';
import 'package:mobile_app/Screens/sam_cupertino_home.dart';
import 'package:mobile_app/Screens/sam_cupertino_tools.dart';

class SamCupertinoTab extends StatefulWidget {
  const SamCupertinoTab({Key? key}) : super(key: key);

  @override
  State<SamCupertinoTab> createState() => _SamCupertinoTabState();
}

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
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Tools',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            if (index == 0) {
              return SamCupertinoHome(title: 'Saṃsādhanī');
            } else if (index == 1) {
              return const SamCupertinoTools();
            } else {
              return SamCupertinoHome(title: 'Saṃsādhanī');
            }
          },
        );
      },
    );
  }
}
