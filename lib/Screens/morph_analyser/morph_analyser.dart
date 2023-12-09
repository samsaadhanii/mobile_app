import 'package:flutter/material.dart';

import '../../Constants/constants.dart';
import '../../web_api.dart';

class MorphAnalyser extends StatefulWidget {
  const MorphAnalyser({super.key});

  @override
  State<MorphAnalyser> createState() => _MorphAnalyserState();
}

class _MorphAnalyserState extends State<MorphAnalyser> {
  TextEditingController firstInputController = TextEditingController();
  // TextEditingController secondInputController = TextEditingController();
  bool _isLoading = false;
  String inputStr1 = '';
  String outputStr1 = '';
  String textTypeStr = Const.textTypeList[0];
  late Size dSize;
  String output1 = '';
  String output2 = '';

  @override
  void initState() {
    firstInputController.text = 'रामः';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Morph Analyser'),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// Input 1
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: TextFormField(
                    autofocus: true,
                    controller: firstInputController,
                    decoration: const InputDecoration(
                      labelText: 'Input Word',
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
                        String inputStr1 = firstInputController.text;

                        String inEnStr =
                            Const.encodingAbbreviation(inputEncodingStr);
                        String outEnStr =
                            Const.outEncodingAbbreviation(outputEncodingStr);

                        WebAPI.morphAnalyser(
                                input1: inputStr1,
                                inEncoding: inEnStr,
                                outEncoding: outEnStr)
                            .then((value) {
                          List<dynamic> morphList = value;
                          setState(() {
                            _isLoading = false;
                            if (morphList.isNotEmpty) {
                              output1 = morphList[0]['RT'] +
                                  ' ' +
                                  morphList[0]['ANS'];
                              output2 = morphList[1]['RT'] +
                                  ' ' +
                                  morphList[1]['ANS'];
                            } else {
                              output1 = 'No analysis found';
                              output2 = '';
                            }
                            // print(value);
                          });
                        });
                      },
                      child: const Text('Show Analysis')),
                ),
                // create a text field to display output
                Column(
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width * 0.9,
                      // height: MediaQuery.sizeOf(context).height * 0.5,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      // padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: output1,
                              style: TextStyle(
                                // fontWeight: FontWeight.bold,
                                color: Colors.black,
                                backgroundColor: Colors.pink.shade50,
                                // fontSize: 20,
                              ),
                            ),
                            TextSpan(
                              text: output2,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                                backgroundColor: Colors.blue.shade50,
                                // fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // child: TextFormField(
                      //   autofocus: true,
                      //   controller: TextEditingController(text: outputStr1),
                      //   decoration: const InputDecoration(
                      //     labelText: 'Output:',
                      //     border: OutlineInputBorder(),
                      //   ),
                      //   maxLines: null,
                      //   keyboardType: TextInputType.none,
                      // ),
                    ),
                  ],
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
}
