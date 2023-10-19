import 'package:flutter/material.dart';
import 'package:mobile_app/Screens/noun_generator/noun_generator.dart';
import 'package:mobile_app/Screens/sandhi/sandhi.dart';
import 'package:mobile_app/Screens/sandhi_splitter/sandhi_splitter.dart';
import 'package:mobile_app/Screens/verb_generator/verb_generator_page1.dart';
import '../widgets/app_logo.dart';
import 'about_page.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({Key? key}) : super(key: key);

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          _createHeader(context),
          Divider(
            thickness: 5,
            color: Theme.of(context).primaryColor,
          ),
          _createDrawerItem(Icons.filter_tilt_shift,
              'Morphological Analyser (शब्द-विश्लेषक)', () {}),
          _createDrawerItem(
              Icons.filter_tilt_shift, 'Noun Generator (नामरूप-निष्पादिका)',
              () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const NounGenerator()));
          }),
          _createDrawerItem(Icons.short_text_outlined,
              'Verb Generator (क्रियारूप-निष्पादिका)', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const VerbGeneratorPage1()));
          }),
          _createDrawerItem(Icons.nature_outlined, 'Sandhi Joining (सन्धि)',
              () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Sandhi()));
          }),
          _createDrawerItem(
              Icons.call_split_rounded, 'Sandhi Analyser (सन्धि-विच्छेद)', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SandhiSplitter()));
          }),
          _createDrawerItem(
              Icons.call_split_rounded, 'Dhātupāṭhaḥ (धातुपाठः)', () {}),
          Divider(
            thickness: 1,
            color: Theme.of(context).secondaryHeaderColor,
          ),
          _createDrawerItem(Icons.account_box_outlined, 'About', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AppAboutPage()));
          }),
          // Switch(
          //   value: ThemeBlueWhite.themeBlue,
          //   onChanged: (value) {
          //     setState(() {
          //       ThemeBlueWhite.themeBlue = value;
          //     });
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _createHeader(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 30, top: 30, right: 30, bottom: 30),
      height: 150.00,
      child: appLogo,
    );
  }

  Widget _createDrawerItem(
    IconData icon,
    String text,
    GestureTapCallback onTap,
  ) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),

      // Update the state of the app with onTap
      // ...
      // Then close the drawer
      onTap: onTap,
    );
  }
}
