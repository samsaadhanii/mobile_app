import 'package:flutter/cupertino.dart';

class SamCupertinoHome extends StatelessWidget {
  const SamCupertinoHome({super.key, required this.title});
  final String title;
  // This shows a CupertinoModalPopup which hosts a CupertinoActionSheet.
  // void _showActionSheet(BuildContext context) {
  //   showCupertinoModalPopup<void>(
  //     context: context,
  //     builder: (BuildContext context) => CupertinoActionSheet(
  //       title: const Text('Saṃsādhanī Tools'),
  //       // message: const Text('Message'),
  //       actions: <CupertinoActionSheetAction>[
  //         CupertinoActionSheetAction(
  //           onPressed: () async {
  //             await Future.delayed(const Duration(microseconds: 1));
  //             Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                     builder: (context) => const NounGenerator()));
  //           },
  //           child: const Text('Morphological Noun Generator'),
  //         ),
  //         CupertinoActionSheetAction(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: const Text('Sandhi'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(title)),
      child: Column(children: <Widget>[
        const SizedBox(height: 100),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: RichText(
            text: const TextSpan(
              text: '   Saṃsādhanī is a computational platform developed '
                  'at the Department of Sanskrit studies for Sanskrit language '
                  'processing. \n\n'
                  'It hosts several computational tools such as'
                  ' morphological analyser, morphological generator, sandhi '
                  'analysis and generation modules, and a dependency parser and'
                  ' Sanskrit-Hindi Machine Translation system.',
              style: TextStyle(
                color: CupertinoColors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.normal,
                fontFamily: 'oswald',
              ),
            ),
          ),
        ),
        // Expanded(
        //   child: Align(
        //     alignment: Alignment.bottomCenter,
        //     child: FittedBox(
        //       child: CupertinoButton(
        //         onPressed: () => _showActionSheet(context),
        //         borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        //         color: CupertinoColors.systemTeal,
        //         child: const Text('                  Tools                  ',
        //             style: TextStyle(fontSize: 24)),
        //       ),
        //     ),
        //   ),
        // ),
      ]),
    );
  }
}
