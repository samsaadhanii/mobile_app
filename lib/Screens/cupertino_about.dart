import 'package:about/about.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart' as mat;
import '../widgets/app_logo.dart';

class CupertinoAboutPage extends StatefulWidget {
  const CupertinoAboutPage({Key? key}) : super(key: key);

  @override
  State<CupertinoAboutPage> createState() => _CupertinoAboutPageState();
}

class _CupertinoAboutPageState extends State<CupertinoAboutPage> {
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
        'Saṃsādhanī is a computational platform developed at the Department'
        ' of Sanskrit studies for Sanskrit language processing to overcome'
        ' these difficulties. It hosts several computational tools such as'
        ' morphological analyser, morphological generator, sandhi analysis '
        'and generation modules, and a dependency parser and Sanskrit-Hindi'
        ' Machine Translation system.',
        textAlign: TextAlign.justify,
      ),
      applicationIcon: Padding(
        padding: const EdgeInsets.all(28.0),
        child: appLogo,
      ),
      applicationLegalese: 'Copyright © {{ author }}, {{ year }}',
      children: const <Widget>[
        MarkdownPageListTile(
          filename: 'assets/README.md',
          title: Text('View Readme'),
          icon: Icon(mat.Icons.all_inclusive),
        ),
        MarkdownPageListTile(
          filename: 'assets/CHANGELOG.md',
          title: Text('View Changelog'),
          icon: Icon(mat.Icons.view_list),
        ),
        MarkdownPageListTile(
          filename: 'assets/CONTRIBUTING.md',
          title: Text('Contributing'),
          icon: Icon(mat.Icons.share),
        ),
        MarkdownPageListTile(
          filename: 'assets/LICENSE',
          title: Text('Open source License'),
          icon: Icon(mat.Icons.favorite),
        ),
      ],
    );
  }
}
