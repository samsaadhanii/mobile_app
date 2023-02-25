import 'package:flutter/cupertino.dart';

import '../widgets/app_logo.dart';

class SamCupertinoHome extends StatelessWidget {
  const SamCupertinoHome({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(title)),
      child: Column(children: <Widget>[
        const SizedBox(height: 100),
        Container(
          alignment: Alignment.center,
          padding:
              const EdgeInsets.only(left: 30, top: 10, right: 30, bottom: 10),
          height: 150.00,
          child: appLogo,
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: RichText(
            text: const TextSpan(
              text: ' Saṃsādhanī is a computational platform developed '
                  'at the Department of Sanskrit Studies, University of Hyderabad for Sanskrit language '
                  'processing. \n\n\n\n'
                  '  It hosts the following Sanskrit computational tools:\n'
                  ' - morphological analyser,\n'
                  ' - morphological generator,\n'
                  ' - sandhi analysis and generation modules,\n'
                  ' - dependency parser and \n'
                  ' - Sanskrit-Hindi Machine Translation system.',
              style: TextStyle(
                color: CupertinoColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.normal,
                // fontFamily: 'iFont',
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
