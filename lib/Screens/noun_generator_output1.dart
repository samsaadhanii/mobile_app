import 'package:flutter/material.dart';
import 'package:mobile_app/Constants/constants.dart';
import '../web_api.dart';

class NounGeneratorOutput extends StatefulWidget {
  const NounGeneratorOutput(
      {Key? key, required this.data, required this.encoding})
      : super(key: key);
  final Map data;
  final String encoding;

  @override
  State<NounGeneratorOutput> createState() => _NounGeneratorOutputState();
}

class _NounGeneratorOutputState extends State<NounGeneratorOutput> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Output')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Center(
              child: DataTable(
                horizontalMargin: 10,
                columnSpacing: 20,
                border: TableBorder.all(),
                columns: getColumns(),
                rows: getRows(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> getRows() {
    List<DataRow> l = [];
    widget.data.forEach((key, value) {
      l.add(DataRow(cells: [
        DataCell(Text(value[0])),
        DataCell(Text(value[1])),
        DataCell(Text(value[2])),
        DataCell(Text(value[3])),
      ]));
    });
    return l;
  }

  List<DataColumn> getColumns() {
    List<String> headings = Const.headings(widget.encoding);
    return <DataColumn>[
      const DataColumn(label: Expanded(child: Text(''))),
      DataColumn(label: Expanded(child: Text(headings[0]))),
      DataColumn(label: Expanded(child: Text(headings[1]))),
      DataColumn(label: Expanded(child: Text(headings[2]))),
    ];
  }
}
