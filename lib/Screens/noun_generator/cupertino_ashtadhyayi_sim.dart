import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';

class CupertinoAshtadhyayiSimulator extends StatefulWidget {
  const CupertinoAshtadhyayiSimulator({Key? key, required this.content})
      : super(key: key);
  final String content;

  @override
  State<CupertinoAshtadhyayiSimulator> createState() =>
      _CupertinoAshtadhyayiSimulatorState();
}

class _CupertinoAshtadhyayiSimulatorState
    extends State<CupertinoAshtadhyayiSimulator> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ashtadhyayi Simulation'),
      ),
      child: widget.content.isNotEmpty
          ? SafeArea(
              child: SingleChildScrollView(child: Html(data: widget.content)))
          : const Center(child: Text('No data available')),
    );
  }
}