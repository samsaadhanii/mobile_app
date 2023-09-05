// ignore_for_file: public_member_api_docs

import 'package:about/about.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/app_logo.dart';

// import 'pubspec.dart';

// void main() => runApp(const MyApp());

class AppAboutPage extends StatefulWidget {
  const AppAboutPage({Key? key}) : super(key: key);

  @override
  State<AppAboutPage> createState() => _AppAboutPageState();
}

class _AppAboutPageState extends State<AppAboutPage> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    getPackageInfo();
  }

  Future<void> getPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();

    //This is to make sure the fetched value of package info gets into UI
    setState(() {
      // _isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AboutPage(
      values: {
        'version': packageInfo != null ? packageInfo!.version.toString() : '1',
        'buildNumber':
            packageInfo != null ? packageInfo!.buildNumber.toString() : '102',
        'year': DateTime.now().year.toString(),
        'author': 'https://sanskrit.uohyd.ac.in/faculty/amba/',
      },
      title: const Text('About'),
      applicationVersion: 'Version {{ version }}, build #{{ buildNumber }}',
      applicationDescription: const Text(
        'Saṃsādhanī is a computational platform developed at the Department '
        'of Sanskrit studies for Sanskrit language processing following the'
        ' traditional knowledge systems of Vyākaraṇa, Nyāya and Mīmāṃsā and'
        ' the theories of śābdabodhaḥ. All the tools are developed by a '
        'Team led by Prof. Amba Kulkarni and her research students',
        textAlign: TextAlign.justify,
      ),
      applicationIcon: Padding(
        padding: const EdgeInsets.all(28.0),
        child: appLogo,
      ),
      applicationLegalese: 'Copyright © {{ author }}, {{ year }}',
      children: const <Widget>[
        MarkdownPageListTile(
          filename: 'README.md',
          title: Text('View Readme'),
          icon: Icon(Icons.all_inclusive),
        ),
        MarkdownPageListTile(
          filename: 'CHANGELOG.md',
          title: Text('View Changelog'),
          icon: Icon(Icons.view_list),
        ),
        MarkdownPageListTile(
          filename: 'LICENSE.md',
          title: Text('View License'),
          icon: Icon(Icons.description),
        ),
        MarkdownPageListTile(
          filename: 'CONTRIBUTING.md',
          title: Text('Contributing'),
          icon: Icon(Icons.share),
        ),
        MarkdownPageListTile(
          filename: 'CODE_OF_CONDUCT.md',
          title: Text('Code of conduct'),
          icon: Icon(Icons.sentiment_satisfied),
        ),
        LicensesPageListTile(
          title: Text('Open source Licenses'),
          icon: Icon(Icons.favorite),
        ),
      ],
    );
  }
}
