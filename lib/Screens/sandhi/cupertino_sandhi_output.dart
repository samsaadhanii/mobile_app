import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Constants/constants.dart';
import 'alternative_output.dart';
import 'basic_output.dart';

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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Output'),
      ),
      child: SafeArea(
          child: widget.lType == LearnerLevel.basic
              ? BasicOutput(data: widget.data)
              : AlternativeOutput(data: widget.data, lType: widget.lType)
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
