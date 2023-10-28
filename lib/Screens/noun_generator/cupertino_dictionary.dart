import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';

class CupertinoDictionary extends StatefulWidget {
  const CupertinoDictionary(
      {Key? key, required this.content, required this.inputWord})
      : super(key: key);
  final content;
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
              child: displayDictionary(widget.content),
              // child: SingleChildScrollView(child: Html(data: widget.content)),
            )
          : const Center(child: Text('No data available')),
    );
  }
}

Widget displayDictionary(final resp) {
  final d = jsonDecode(resp);
  String str1 = d[0]['Meaning'];
  List list = str1.split('  ');
  List<String> ts = [];
  for (String l in list) {
    String str = l.trim();
    if(str.isNotEmpty){
    print('l: $l');
    ts.add(l);}
  }
  return Column(
    children: [
      Center(child: Text(d[0]['Word'])),
      Container(
        color: CupertinoColors.activeOrange,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(d[0]['DICT']),
        ),
      ),
      createListView(ts),
    ],
  );
}
Widget createListView(List<dynamic> list){
  return Expanded(
    child: ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
                child: Text(
              list[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.0,
                // color: CupertinoColors.inactiveGray,
              ),
            )));
      },
    ),
  );
}
