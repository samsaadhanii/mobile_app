import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class NounGenerator extends StatefulWidget {
  const NounGenerator({Key? key}) : super(key: key);

  @override
  State<NounGenerator> createState() => _NounGeneratorState();
}

class _NounGeneratorState extends State<NounGenerator> {
  var _responseBody;

  @override
  void initState() {
    makeRequest();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noun Generator'),
      ),
      // body: Table(
      //   border: TableBorder.all(),
      //   columnWidths: const <int, TableColumnWidth>{
      //     0: FlexColumnWidth(),
      //     1: FlexColumnWidth(),
      //     2: FlexColumnWidth(),
      //     3: FlexColumnWidth(),
      //   },
      //   defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      //   children: <TableRow>[
      //     TableRow(
      //       children: <Widget>[
      //         Container(
      //           height: 32,
      //           color: Colors.green,
      //         ),
      //         TableCell(
      //           verticalAlignment: TableCellVerticalAlignment.top,
      //           child: Container(
      //             height: 32,
      //             width: 32,
      //             color: Colors.red,
      //           ),
      //         ),
      //         Container(
      //           height: 64,
      //           color: Colors.blue,
      //         ),
      //         Container(
      //           height: 64,
      //           color: Colors.blue,
      //         ),
      //       ],
      //     ),
      //     TableRow(
      //       decoration: const BoxDecoration(
      //         color: Colors.grey,
      //       ),
      //       children: <Widget>[
      //         Container(
      //           height: 64,
      //           width: 128,
      //           color: Colors.purple,
      //         ),
      //         Container(
      //           height: 32,
      //           color: Colors.yellow,
      //         ),
      //         Center(
      //           child: Container(
      //             height: 32,
      //             width: 32,
      //             color: Colors.orange,
      //           ),
      //         ),
      //         Center(
      //           child: Container(
      //             height: 32,
      //             width: 32,
      //             color: Colors.orange,
      //           ),
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
      body: DataTable(
        columns: const <DataColumn>[
          DataColumn(
            label: Expanded(
              child: Text(
                'form',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'vib',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'vac',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ],
        rows: getRows(),
        // const <DataRow>[
        //   DataRow(
        //     cells: <DataCell>[
        //       DataCell(Text('Sarah')),
        //       DataCell(Text('19')),
        //       DataCell(Text('Student')),
        //     ],
        //   ),
        //   DataRow(
        //     cells: <DataCell>[
        //       DataCell(Text('Janine')),
        //       DataCell(Text('43')),
        //       DataCell(Text('Professor')),
        //     ],
        //   ),
        //   DataRow(
        //     cells: <DataCell>[
        //       DataCell(Text('William')),
        //       DataCell(Text('27')),
        //       DataCell(Text('Associate Professor')),
        //     ],
        //   ),
        // ],
      ),
    );
  }

  List<DataRow> getRows() {
    List<DataRow> l = [];
    if (_responseBody != null) {
      List r = _responseBody as List;
      for (var element in r) {
        l.add(DataRow(cells: [
          DataCell(Text(element['form'])),
          DataCell(Text(element['vib'])),
          DataCell(Text(element['vac'])),
        ]));
      }
    }
    return l;
  }

  Future<void> makeRequest() async {
    var url =
        'http://scl.samsaadhanii.in/cgi-bin/scl/skt_gen/noun/noun_gen_json.cgi?rt=vana&gen=puM&jAwi=nA&level=1';
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    _responseBody = jsonDecode(responseBody);
    print(_responseBody);
  }
}
