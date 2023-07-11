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
            : Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.lightBlueAccent,
                        child: Row(
                          children: [
                            (widget.lType == LearnerLevel.intermediate ||
                                    widget.lType == LearnerLevel.advanced)
                                ? const Icon(Icons.check)
                                : const Icon(Icons.close),
                            const SizedBox(width: 6),
                            const Text('Sandhi'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.lightBlueAccent,
                        child: Row(
                          children: [
                            (widget.lType == LearnerLevel.advanced)
                                ? const Icon(Icons.check)
                                : const Icon(Icons.close),
                            const SizedBox(width: 6),
                            const Text('sūtram'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      child: Center(
                        child: DataTable(
                          horizontalMargin: 10,
                          columnSpacing: 10,
                          border: TableBorder.all(),
                          columns: getColumns(),
                          rows: getRows(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _w1Spelling?
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.amber[50],
                                ),
                                child: Text(
                                  e['spelling_word1'],
                                  style:
                                      const TextStyle(color: Colors.redAccent),
                                ),
                              ):Container(),
                              const Text(' + '),
                              _w2Spelling?
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.red[300],
                                ),
                                child: Text(
                                  e['spelling_word2'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ):Container(),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    : Container(),

                /// Last and first letter & Modified letter
                _w1LastL||_w2FirstL||_modifiedL?
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    /// Last and first letter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _w1LastL?
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red,
                          ),
                          child: Text(
                            e['last_letter'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ):Container(),
                        const Text(' + '),
                        _w2FirstL?Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.blue,
                          ),
                          child: Text(
                            e['first_letter'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ):Container(),
                      ],
                    ),
                    const Text(' = '),

                    /// Modified letter
                    _modifiedL?
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.lightGreenAccent,
                      ),
                      child: Text(
                        e['modified_letter'],
                        style: const TextStyle(color: Colors.red),
                      ),
                    ):Container(),
                  ],
                ):Container(),
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
}
