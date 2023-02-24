import 'package:flutter/cupertino.dart';
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
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
