import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Constants/constants.dart';

class CupertinoSandhiOutput extends StatefulWidget {
  const CupertinoSandhiOutput({
    Key? key,
    required this.data,
    required this.encoding,
    this.lType = LearnerLevel.basic,
  }) : super(key: key);
  final List data;
  final String encoding;
  final LearnerLevel? lType;

  @override
  State<CupertinoSandhiOutput> createState() => _CupertinoSandhiOutputState();
}

class _CupertinoSandhiOutputState extends State<CupertinoSandhiOutput> {
  bool _isInit = true, _w1Spelling = true, _w2Spelling = true;
  bool _w1LastL = true, _w2FirstL = true, _modifiedL = true;
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Output'),
      ),
      child: SafeArea(
          child: widget.lType == LearnerLevel.basic
              ? basicOutput()
              : alternativeOutput()
          // : Column(
          //     children: [
          //       /// No longer used
          //       // const SizedBox(
          //       //   height: 10,
          //       // ),
          //       // Row(
          //       //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //       //   children: [
          //       //     Container(
          //       //       padding: const EdgeInsets.all(8),
          //       //       color: Colors.lightBlueAccent,
          //       //       child: Row(
          //       //         children: [
          //       //           (widget.lType == LearnerLevel.intermediate ||
          //       //                   widget.lType == LearnerLevel.advanced)
          //       //               ? const Icon(Icons.check)
          //       //               : const Icon(Icons.close),
          //       //           const SizedBox(width: 6),
          //       //           const Text('Sandhi'),
          //       //         ],
          //       //       ),
          //       //     ),
          //       //     Container(
          //       //       padding: const EdgeInsets.all(8),
          //       //       color: Colors.lightBlueAccent,
          //       //       child: Row(
          //       //         children: [
          //       //           (widget.lType == LearnerLevel.advanced)
          //       //               ? const Icon(Icons.check)
          //       //               : const Icon(Icons.close),
          //       //           const SizedBox(width: 6),
          //       //           const Text('sūtram'),
          //       //         ],
          //       //       ),
          //       //     ),
          //       //   ],
          //       // ),
          //       const SizedBox(height: 10),
          //       Padding(
          //         padding: const EdgeInsets.all(8.0),
          //         child: FittedBox(
          //           child: Center(
          //             child: DataTable(
          //               horizontalMargin: 10,
          //               columnSpacing: 10,
          //               border: TableBorder.all(),
          //               columns: getColumns(),
          //               rows: getRows(),
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          ),
    );
  }

  List<DataRow> getRows() {
    List<DataRow> l = [];
    for (var element in widget.data) {
      l.add(DataRow(cells: [
        DataCell(SizedBox(
            width: t,
            child: Text(
              element['word1'],
              softWrap: true,
            ))),
        DataCell(SizedBox(
            width: t,
            child: Text(
              element['word2'],
              softWrap: true,
            ))),
        DataCell(SizedBox(
            width: t,
            child: Text(
              element['saMhiwapaxam'],
              softWrap: true,
            ))),
        if (widget.lType == LearnerLevel.intermediate ||
            widget.lType == LearnerLevel.advanced)
          DataCell(SizedBox(
              width: t,
              child: Text(
                element['sanXiH'],
                softWrap: true,
              ))),
        if (widget.lType == LearnerLevel.advanced)
          DataCell(SizedBox(
              width: t, child: Text(element['sUwram'], softWrap: true))),
      ]));
    }
    return l;
  }

  TextStyle sandhiTextStyle() {
    return const TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 32,
    );
  }

  List<DataColumn> getColumns() {
    List<String> h = Const.sandhiTableHeadings(widget.encoding);
    return <DataColumn>[
      DataColumn(label: SizedBox(width: t, child: Text(h[0], softWrap: true))),
      DataColumn(label: SizedBox(width: t, child: Text(h[1], softWrap: true))),
      DataColumn(label: SizedBox(width: t, child: Text(h[2], softWrap: true))),
      if (widget.lType == LearnerLevel.intermediate ||
          widget.lType == LearnerLevel.advanced)
        DataColumn(
            label: SizedBox(width: t, child: Text(h[3], softWrap: true))),
      if (widget.lType == LearnerLevel.advanced)
        DataColumn(
            label: SizedBox(width: t, child: Text(h[4], softWrap: true))),
    ];
  }

  Widget basicOutput() {
    List<Column> cList = [];
    for (var e in widget.data) {
      cList.add(Column(
        children: [
          Container(height: 10, color: Colors.white),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                /// word1 and word2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.teal,
                      ),
                      child: Text(
                        e['word1'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const Text(' + '),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.teal,
                      ),
                      child: Text(
                        e['word2'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                /// spelling word 1 & spelling word 2
                _w1Spelling || _w2Spelling
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _w1Spelling
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.amber[50],
                                      ),
                                      child: Text(
                                        e['spelling_word1'],
                                        style: const TextStyle(
                                            color: Colors.redAccent),
                                        softWrap: true,
                                      ),
                                    )
                                  : Container(),
                              const Text(' + '),
                              _w2Spelling
                                  ? Expanded(
                                    child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.red[300],
                                        ),
                                        child: Text(
                                          e['spelling_word2'],
                                          style: const TextStyle(
                                              color: Colors.white),
                                          softWrap: true,
                                        ),
                                      ),
                                  )
                                  : Container(),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    : Container(),

                /// Last and first letter & Modified letter
                _w1LastL || _w2FirstL || _modifiedL
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          /// Last and first letter
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _w1LastL
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.red,
                                      ),
                                      child: Text(
                                        e['last_letter'],
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    )
                                  : Container(),
                              const Text(' + '),
                              _w2FirstL
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.blue,
                                      ),
                                      child: Text(
                                        e['first_letter'],
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                          const Text(' = '),

                          /// Modified letter
                          _modifiedL
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.lightGreenAccent,
                                  ),
                                  child: Text(
                                    e['modified_letter'],
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                )
                              : Container(),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        ],
      ));
      // print(e['word1']);
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          CupertinoListSection(
            children: [
              CupertinoListTile(
                title: const Text("Spelling of word 1"),
                leading: CupertinoSwitch(
                  value: _w1Spelling,
                  onChanged: (bool value) {
                    setState(() {
                      _w1Spelling = value;
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("Spelling of word 2"),
                leading: CupertinoSwitch(
                  value: _w2Spelling,
                  onChanged: (bool value) {
                    setState(() {
                      _w2Spelling = value;
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("Last letter of word 1"),
                leading: CupertinoSwitch(
                  value: _w1LastL,
                  onChanged: (bool value) {
                    setState(() {
                      _w1LastL = value;
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("First letter of word 2"),
                leading: CupertinoSwitch(
                  value: _w2FirstL,
                  onChanged: (bool value) {
                    setState(() {
                      _w2FirstL = value;
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("Sandhied Letters"),
                leading: CupertinoSwitch(
                  value: _modifiedL,
                  onChanged: (bool value) {
                    setState(() {
                      _modifiedL = value;
                    });
                  },
                ),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            dividerMargin: 15,
            children: cList,
          ),
        ],
      ),
    );
  }

  Widget alternativeOutput() {
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
      child: Text(s, textAlign: TextAlign.center,softWrap: true),
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
// Widget buildFormTable(List<dynamic> data) {
//   String prathama =
//       outputEncodingStr == Const.UNICODE_DEVANAGARI ? 'पुरुषः' : 'prathama';
//   String dvitiya =
//       outputEncodingStr == Const.UNICODE_DEVANAGARI ? 'पुरुषः' : 'dvitiya';
//   String samhita =
//       outputEncodingStr == Const.UNICODE_DEVANAGARI ? 'पुरुषः' : 'samhita';
//   String sandhi =
//       outputEncodingStr == Const.UNICODE_DEVANAGARI ? 'पुरुषः' : 'sandhi';
//   return Padding(
//     padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
//     child: Container(
//       child: Column(children: [
//         Text(prathama, style: const TextStyle(fontSize: 14)),
//         Text(data['word1'])
//       ],),
//     ),
//   );
// }
}
