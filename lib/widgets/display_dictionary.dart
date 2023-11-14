import 'dart:convert';
import 'package:flutter/cupertino.dart';

class DisplayDictionary {
  static Widget displayDictionary(final resp) {
    final d = jsonDecode(resp);
    String str1 = d[0]['Meaning'];
    List list = str1.split('  ');
    List<String> ts = [];
    for (String l in list) {
      String str = l.trim();
      if (str.isNotEmpty) {
        print('l: $l');
        ts.add(l);
      }
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

  static Widget createListView(List<dynamic> list) {
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
}
