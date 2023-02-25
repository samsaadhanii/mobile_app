import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Constants/constants.dart';
import '../../web_api.dart';
import 'cupertino_ashtadhyayi_sim.dart';
import 'cupertino_dictionary.dart';

class CupertinoNGOutput extends StatefulWidget {
  const CupertinoNGOutput(
      {Key? key,
      required this.data,
      required this.encoding,
      required this.gender,
      required this.inputWord})
      : super(key: key);
  final Map data;
  final String encoding;
  final String gender;
  final String inputWord;

  @override
  State<CupertinoNGOutput> createState() => _CupertinoNGOutputState();
}

class _CupertinoNGOutputState extends State<CupertinoNGOutput> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Output'),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                TextButton(
                  onPressed: () {
                    WebAPI.getDictionary(inputWord: widget.inputWord)
                        .then((value) {
                      print(value);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => CupertinoDictionary(
                            content: value,
                            inputWord: widget.inputWord,
                          ),
                        ),
                      );
                    });
                  },
                  child: Text(widget.inputWord),
                ),
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      child: DataTable(
                        horizontalMargin: 10,
                        columnSpacing: 20,
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
        ),
      ),
      if (_isLoading)
        const Opacity(
          opacity: 0.8,
          child: ModalBarrier(dismissible: false, color: CupertinoColors.white),
        ),
      if (_isLoading)
        const Center(
          child: CupertinoActivityIndicator(
              radius: 20.0, color: CupertinoColors.activeBlue),
        ),
    ]);
  }

  List<DataRow> getRows() {
    List<DataRow> l = [];
    int index = 0;
    widget.data.forEach((key, value) {
      String vib = Const.vibList_WX[index];
      // print(vib);
      l.add(DataRow(cells: [
        DataCell(Text(value[0])),
        DataCell(interactiveText(text: value[1], vib: vib, vac: 'ekavacana')),
        DataCell(interactiveText(text: value[2], vib: vib, vac: 'xvivacana')),
        DataCell(interactiveText(text: value[3], vib: vib, vac: 'bahuvacana')),
      ]));
      index++;
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

  Widget interactiveText({
    required String text,
    String vib = 'praWamA',
    String vac = 'ekavacana',
  }) {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLoading = true;
        });
        WebAPI.simulation(
          inputWrod: text,
          encoding: Const.encodingAbbreviation(widget.encoding),
          vibhakti: vib,
          linga: Const.genderAbbreviation(widget.gender),
          vacana: vac,
        ).then((value) {
          print(value);
          setState(() {
            _isLoading = false;
          });

          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => CupertinoAshtadhyayiSimulator(
                content: value,
              ),
            ),
          );
        });
      },
      child: Text(text),
    );
  }
}
