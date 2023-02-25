import 'package:flutter/material.dart';

import '../../Constants/constants.dart';

class SandhiOutput extends StatefulWidget {
  const SandhiOutput({
    Key? key,
    required this.data,
    required this.encoding,
  }) : super(key: key);
  final List data;
  final String encoding;

  @override
  State<SandhiOutput> createState() => _SandhiOutputState();
}

class _SandhiOutputState extends State<SandhiOutput> {
  final bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Output'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  DataTable(
                    horizontalMargin: 10,
                    columnSpacing: 20,
                    border: TableBorder.all(),
                    columns: getColumns(),
                    rows: getRows(),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          const Opacity(
            opacity: 0.2,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
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
