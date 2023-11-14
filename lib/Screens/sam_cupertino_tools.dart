import 'package:flutter/cupertino.dart';
import 'package:mobile_app/Screens/sandhi/cupertino_sandhi.dart';
import 'package:mobile_app/Screens/sandhi_splitter/cupertino_sandhi_splitter.dart';
// import 'package:mobile_app/Screens/verb_generator/cupertino_verb_gen_page1.dart';
import 'package:mobile_app/Screens/verb_generator/cupertino_verb_gen_prefix.dart';
import 'dhatupatha/dhatupatha_page_one.dart';
import 'noun_generator/cupertino_noun_generator.dart';

class SamCupertinoTools extends StatefulWidget {
  const SamCupertinoTools({Key? key}) : super(key: key);

  @override
  State<SamCupertinoTools> createState() => _SamCupertinoToolsState();
}

class _SamCupertinoToolsState extends State<SamCupertinoTools> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Samsaadhanii Tools'),
      ),
      child: SafeArea(
        child: CupertinoListSection.insetGrouped(
          // header: const Text('Sam Tools'),
          children: <CupertinoListTile>[
            CupertinoListTile.notched(
              title: const Text('Morphological Analyser (शब्द-विश्लेषक)'),
              trailing: const CupertinoListTileChevron(),
              onTap: () {},
            ),
            CupertinoListTile.notched(
              title: const Text('Noun Generator (नामरूप-निष्पादिका)'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => Future.delayed(Duration.zero, () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) {
                      return const CupertinoNounGenerator();
                    },
                  ),
                );
              }),
            ),
            CupertinoListTile.notched(
              title: const Text('Verb Generator (क्रियारूप-निष्पादिका)'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => Future.delayed(Duration.zero, () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) {
                      return const CupertinoVerbGeneratorPrefix();
                    },
                  ),
                );
              }),
            ),
            CupertinoListTile.notched(
              title: const Text('Sandhi Joining (सन्धि)'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => Future.delayed(Duration.zero, () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) {
                      return const CupertinoSandhi();
                    },
                  ),
                );
              }),
            ),
            CupertinoListTile.notched(
              title: const Text('Sandhi Analyser (सन्धि-विच्छेद)'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => Future.delayed(Duration.zero, () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) {
                      return const CupertinoSandhiSplitter();
                    },
                  ),
                );
              }),
            ),
            CupertinoListTile.notched(
              title: const Text('Dhātupāṭhaḥ (धातुपाठः)'),
              trailing: const CupertinoListTileChevron(),
              onTap: ()  => Future.delayed(Duration.zero, () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) {
                      return const DhatupathaPageOne();
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
