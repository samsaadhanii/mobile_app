import 'package:flutter/cupertino.dart';

class CupertinoDataNotFound extends StatefulWidget {
  const CupertinoDataNotFound({Key? key}) : super(key: key);

  @override
  State<CupertinoDataNotFound> createState() => _CupertinoDataNotFoundState();
}

class _CupertinoDataNotFoundState extends State<CupertinoDataNotFound> {
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Data not found'),
      ),
      child: Center(
        child: FittedBox(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.clear_circled,
                color: CupertinoColors.destructiveRed,
                size: 50.0,
                semanticLabel: 'Text to announce in accessibility modes',
              ),
              Text('Data not found!'),
            ],
          ),
        ),
      ),
    );
  }
}
