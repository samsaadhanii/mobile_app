import 'package:flutter/material.dart';
import 'package:mobile_app/Constants/constants.dart';
import '../../web_api.dart';
import 'ashtadhyayi_simulator.dart';
import 'dictionary.dart';

class NounGeneratorOutput extends StatefulWidget {
  const NounGeneratorOutput(
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
  State<NounGeneratorOutput> createState() => _NounGeneratorOutputState();
}

class _NounGeneratorOutputState extends State<NounGeneratorOutput> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Output')),
          body: SingleChildScrollView(
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
                        MaterialPageRoute(
                          builder: (context) => DictionaryPage(
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
            MaterialPageRoute(
              builder: (context) => AshtadhyayiSimulation(
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
