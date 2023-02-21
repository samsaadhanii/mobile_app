import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:mobile_app/Screens/sandhi_output.dart';

import '../Constants/constants.dart';
import '../web_api.dart';

class Sandhi extends StatefulWidget {
  const Sandhi({Key? key}) : super(key: key);

  @override
  State<Sandhi> createState() => _SandhiState();
}

class _SandhiState extends State<Sandhi> {
  TextEditingController firstInputController = TextEditingController();
  TextEditingController secondInputController = TextEditingController();
  bool _isLoading = false;
  String inputStr1 = '';
  String inputStr2 = '';
  String inputEncodingStr = Const.inputEncodingList[0];
  String outputEncodingStr = Const.outputEncodingList[0];
  bool transliterated = false;

  @override
  void initState() {
    firstInputController.text = 'लक्ष्मीवान्';
    secondInputController.text = 'शुभलक्षणः';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Sandhi'),
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
                    initialValue: inputEncodingStr,
                    onChanged: (value) {
                      inputEncodingStr = value!;
                    },
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
                    initialValue: outputEncodingStr,
                    onChanged: (value) {
                      outputEncodingStr = value!;
                    },
                  ),
                ),
                const SizedBox(height: 10),

                /// Input 1
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: TextFormField(
                    autofocus: true,
                    controller: firstInputController,
                    decoration: const InputDecoration(
                      labelText: 'First Word',
                      border: OutlineInputBorder(),
                    ),
                    // onChanged: (String value) {
                    //   setState(() {
                    //     inputController.text = value;
                    //   });
                    // },
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(height: 10),

                /// Input 2
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: TextFormField(
                    autofocus: true,
                    controller: secondInputController,
                    decoration: const InputDecoration(
                      labelText: 'Second Word',
                      border: OutlineInputBorder(),
                    ),
                    // onChanged: (String value) {
                    //   setState(() {
                    //     inputController.text = value;
                    //   });
                    // },
                    keyboardType: TextInputType.text,
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
                        WebAPI.transLiterateWord(
                          input: firstInputController.text,
                          src: Const.encodingAbbreviation(inputEncodingStr),
                        ).then((inputLiteral) {
                          inputStr1 = inputLiteral;
                          WebAPI.transLiterateWord(
                            input: secondInputController.text,
                            src: Const.encodingAbbreviation(inputEncodingStr),
                          ).then((inputLiteral) {
                            inputStr2 = inputLiteral;
                            WebAPI.sandhiRequest(
                                    input1: inputStr1, input2: inputStr2)
                                .then((dataList) {
                              WebAPI.transLiterateData(
                                      body: dataList,
                                      tar: Const.encodingAbbreviation(
                                          outputEncodingStr))
                                  .then((value) {
                                setState(() {
                                  _isLoading = false;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SandhiOutput(
                                          data: value,
                                          encoding: outputEncodingStr),
                                    ),
                                  );
                                });
                              });
                            });
                          });
                        });
                      },
                      child: const Text('Submit')),
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
  //
  // /// formatting WX to IAST displayable format
  // Map formatData(List data) {
  //   Map<String, List<String>> curData = <String, List<String>>{};
  //   List<String> vacanam = [];
  //   for (var element in data) {
  //     if (element['vib'] != null) {
  //       curData.putIfAbsent(element['vib'], () => [element['vib'], '', '', '']);
  //     }
  //     if (element['vac'] != null) {
  //       if (!vacanam.contains(element['vac'])) vacanam.add(element['vac']);
  //     }
  //   }
  //   // curData.forEach((key, value) {
  //   //   print(value);
  //   // });
  //   for (var element in data) {
  //     // print(element['vib']);
  //     String key = element['vib'];
  //     if (curData.containsKey(key)) {
  //       if (element['vac'].toString().contains(vacanam[0])) {
  //         curData[key]![1] = element['form'];
  //       } else if (element['vac'].toString().contains(vacanam[1])) {
  //         curData[key]![2] = element['form'];
  //       } else if (element['vac'].toString().contains(vacanam[2])) {
  //         curData[key]![3] = element['form'];
  //       }
  //       // print(curData[key]);
  //     }
  //   }
  //   return curData;
  // }
}
