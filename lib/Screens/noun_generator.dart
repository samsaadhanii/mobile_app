import 'package:mobile_app/Screens/noun_generator_output1.dart';
import 'package:mobile_app/web_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../Constants/constants.dart';

class NounGenerator extends StatefulWidget {
  const NounGenerator({Key? key}) : super(key: key);

  @override
  State<NounGenerator> createState() => _NounGeneratorState();
}

class _NounGeneratorState extends State<NounGenerator> {
  TextEditingController inputController = TextEditingController();
  bool _isLoading = false;
  String inputStr = '';

  @override
  void initState() {
    inputController.text = 'राम';
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // WebAPI.nounGenRequest().then((value) {
    //   debugPrint(value.body.toString());
    //   setState(() {
    //     if (value.statusCode == 200) {
    //       _responseBody = jsonDecode(value.body);
    //     }
    //   });
    // });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Noun Generator'),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                ///Input Encoder
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: FormBuilderDropdown(
                    name: 'Input Encoder',
                    items: Const.inputEncodingList.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: "Input Encoder",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: Const.inputEncodingList[0],
                  ),
                ),
                const SizedBox(height: 10),

                ///Output Encoder
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: FormBuilderDropdown(
                    name: 'Output Encoder',
                    items: Const.outputEncodingList.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: "Output Encoder",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: Const.outputEncodingList[0],
                  ),
                ),
                const SizedBox(height: 10),

                /// Input
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: TextFormField(
                    controller: inputController,
                    decoration: const InputDecoration(
                      labelText: 'प्रातिपदिकम्/Prātipadikam',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String value) {
                      inputController.text = value;
                    },
                  ),
                ),
                const SizedBox(height: 10),

                ///Category
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: FormBuilderDropdown(
                    name: 'Category',
                    items: Const.list3.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: Const.list3[0],
                  ),
                ),
                const SizedBox(height: 10),

                ///Gender
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: FormBuilderDropdown(
                    name: 'Gender',
                    items: Const.genderList.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: Const.genderList[0],
                  ),
                ),
                const SizedBox(height: 10),

                /// button
                Container(
                  height: 60,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                        });
                        WebAPI.transLiterate(input: inputController.text).then(
                          (inputLiteral) =>
                              WebAPI.nounGenRequest(inputString: inputLiteral)
                                  .then(
                            (dataList) {
                              setState(
                                () {
                                  _isLoading = false;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NounGeneratorOutput(data: dataList),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('रूपाणि दर्श्यताम्')),
                ),
                // DisplayData(
                //   data: _responseBody,
                // ),
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
}

class DisplayData extends StatefulWidget {
  const DisplayData({Key? key, required this.data}) : super(key: key);
  final data;
  @override
  State<DisplayData> createState() => _DisplayDataState();
}

class _DisplayDataState extends State<DisplayData> {
  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: getColumns(),
      rows: getRows(),
    );
  }

  List<DataRow> getRows() {
    List<DataRow> l = [];
    if (widget.data != null) {
      List r = widget.data as List;
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

  List<DataColumn> getColumns() {
    return const <DataColumn>[
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
    ];
  }
}
