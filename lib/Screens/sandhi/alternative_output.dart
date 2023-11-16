import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Constants/constants.dart';

class AlternativeOutput extends StatefulWidget {
  const AlternativeOutput({
    super.key,
    required this.data,
    this.lType = LearnerLevel.basic,
  });
  final List data;
  final LearnerLevel? lType;

  @override
  State<AlternativeOutput> createState() => _AlternativeOutputState();
}

class _AlternativeOutputState extends State<AlternativeOutput> {
  bool _isInit = true;
  double w = 0, h = 0, t = 0, s = 0;
  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      w = MediaQuery.of(context).size.width;
      h = w / 2;
      t = h / 3;
      if (widget.lType == LearnerLevel.intermediate ||
          widget.lType == LearnerLevel.advanced) t = w / 7;
      s = h / 2;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    List<String> h = Const.sandhiTableHeadings(outputEncodingStr);
    List<Container> cList = [];
    // for (var e in widget.data) {
    List e = widget.data;
    for (int i = 0; i < e.length; i++) {
      // bool flag = (i) % 2 == 0;
      cList.add(Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(25)),
          color: CupertinoColors.systemGrey6,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          text1(h[0], ts1()),
          text2(e[i]['word1']),
          const Divider(height: 5),
          text1(h[1], tsBlue()),
          text2(e[i]['word2']),
          const Divider(height: 5),
          text1(h[2], tsOrange()),
          text2(e[i]['saMhiwapaxam']),
          const Divider(height: 5),
          text1(h[3], tsPurple()),
          text2(e[i]['sanXiH']),
          const Divider(height: 5),
          if (widget.lType == LearnerLevel.advanced) text1(h[4], tsRed()),
          if (widget.lType == LearnerLevel.advanced) text2(e[i]['sUwram']),
          const Divider(height: 5),
        ]),
      ));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          CupertinoListSection.insetGrouped(
              // header: Text(""),
              backgroundColor: CupertinoColors.white,
              children: cList),
        ],
      ),
    );
  }

  Widget text1(String s, TextStyle ts) {
    return Text(
      s,
      style: ts,
      textAlign: TextAlign.start,
      softWrap: true,
    );
  }

  Widget text2(String s) {
    return SizedBox(
      width: w,
      child: Text(s, textAlign: TextAlign.center, softWrap: true),
    );
  }

  TextStyle ts1() {
    return const TextStyle(fontSize: 14, color: CupertinoColors.activeGreen);
  }

  TextStyle tsBlue() {
    return const TextStyle(fontSize: 14, color: CupertinoColors.activeBlue);
  }

  TextStyle tsOrange() {
    return const TextStyle(fontSize: 14, color: CupertinoColors.activeOrange);
  }

  TextStyle tsPurple() {
    return const TextStyle(fontSize: 14, color: CupertinoColors.systemPurple);
  }

  TextStyle tsRed() {
    return const TextStyle(fontSize: 14, color: CupertinoColors.destructiveRed);
  }
}
