import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';

class CupertinoDictionary extends StatefulWidget {
  const CupertinoDictionary(
      {Key? key, required this.content, required this.inputWord})
      : super(key: key);
  final String content;
  final String inputWord;

  @override
  State<CupertinoDictionary> createState() => _CupertinoDictionaryState();
}

class _CupertinoDictionaryState extends State<CupertinoDictionary> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Dictionary'),
      ),
      child: widget.content.isNotEmpty
          ? SafeArea(
              child: SingleChildScrollView(child: Html(data: widget.content)))
          : const Center(child: Text('No data available')),
    );
  }
}
