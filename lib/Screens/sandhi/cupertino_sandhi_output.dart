import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Constants/constants.dart';

class CupertinoSandhiOutput extends StatefulWidget {
  const CupertinoSandhiOutput({
    Key? key,
    required this.data,
    required this.encoding,
  }) : super(key: key);
  final List data;
  final String encoding;

  @override
  State<CupertinoSandhiOutput> createState() => _CupertinoSandhiOutputState();
}

class _CupertinoSandhiOutputState extends State<CupertinoSandhiOutput> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Output'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
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
        DataCell(Text(element['word1'])),
        DataCell(Text(element['word2'])),
        DataCell(Text(element['saMhiwapaxam'])),
      ]));
    }
    return l;
  }

  List<DataColumn> getColumns() {
    List<String> headings = Const.sandhiTableHeadings(widget.encoding);
    return <DataColumn>[
      DataColumn(label: Expanded(child: Text(headings[0]))),
      DataColumn(label: Expanded(child: Text(headings[1]))),
      DataColumn(label: Expanded(child: Text(headings[2]))),
    ];
  }
}
