import 'package:flutter/material.dart';
import 'package:mobile_app/Constants/constants.dart';
import '../web_api.dart';

class NounGeneratorOutput extends StatefulWidget {
  const NounGeneratorOutput({Key? key, required this.data}) : super(key: key);
  final List data;

  @override
  State<NounGeneratorOutput> createState() => _NounGeneratorOutputState();
}

class _NounGeneratorOutputState extends State<NounGeneratorOutput> {
  late Map<String, List<String>> curData;
  @override
  void initState() {
    // curData = <String, List<String>>{
    //   'prathamā': ['', '', ''],
    //   'dvitīyā': ['', '', ''],
    //   'tṛtīyā': ['', '', ''],
    //   'caturthī': ['', '', ''],
    //   'pañcamī': ['', '', ''],
    //   'ṣaṣṭhī': ['', '', ''],
    //   'saptamī': ['', '', ''],
    //   'saṃ.pra': ['', '', ''],
    // };
    curData = {
      for (var vib in Const.vibList) vib: [vib, '', '', '']
    };
    formatData();
    super.initState();
  }

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

  void formatData() {
    WebAPI.transLiterateData(body: widget.data).then((value) {
      for (var element in value) {
        // print(element['vib']);
        String key = element['vib'];
        if (curData.containsKey(key)) {
          if (element['vac'].toString().contains('eka')) {
            curData[key]![1] = element['form'];
          } else if (element['vac'].toString().contains('dvi')) {
            curData[key]![2] = element['form'];
          } else if (element['vac'].toString().contains('bahu')) {
            curData[key]![3] = element['form'];
          }
          print(curData[key]);
        }
      }
    });
  }

  List<DataRow> getRows() {
    List<DataRow> l = [];
    for (var vib in Const.vibList) {
      l.add(DataRow(cells: [
        DataCell(Text(curData[vib]![0])),
        DataCell(Text(curData[vib]![1])),
        DataCell(Text(curData[vib]![2])),
        DataCell(Text(curData[vib]![3])),
      ]));
    }
    return l;
  }

  List<DataColumn> getColumns() {
    return const <DataColumn>[
      DataColumn(
        label: Expanded(
          child: Text(
            '',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      DataColumn(
        label: Expanded(
          child: Text(
            'ekavacanam',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      DataColumn(
        label: Expanded(
          child: Text(
            'dvivacanam',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
      DataColumn(
        label: Expanded(
          child: Text(
            'bahuvacanam',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    ];
  }
}
