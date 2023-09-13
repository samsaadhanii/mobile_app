import 'package:flutter/cupertino.dart';
import 'package:mobile_app/Screens/sandhi/cupertino_sandhi.dart';
import 'package:mobile_app/Screens/sandhi_splitter/cupertino_sandhi_splitter.dart';
import 'package:mobile_app/Screens/verb_generator/cupertino_verb_gen_page1.dart';
import 'noun_generator/dummy.dart';

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
              title: const Text('Morphological Noun Generator'),
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
              title: const Text('Sandhi'),
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
              title: const Text('Sandhi Splitter'),
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
              title: const Text('Verb Generator'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => Future.delayed(Duration.zero, () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) {
                      return const CupertinoVerbGenerator1();
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
