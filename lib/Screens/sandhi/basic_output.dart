import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BasicOutput extends StatefulWidget {
  const BasicOutput({super.key, required this.data});
  final List data;

  @override
  State<BasicOutput> createState() => _BasicOutputState();
}

class _BasicOutputState extends State<BasicOutput> {
  bool _w1Spelling = true, _w2Spelling = true;
  bool _w1LastL = true, _w2FirstL = true, _modifiedL = true;

  // double w = 0, h = 0, t = 0, s = 0;

  @override
  Widget build(BuildContext context) {
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
                                          borderRadius:
                                              BorderRadius.circular(8),
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
}
