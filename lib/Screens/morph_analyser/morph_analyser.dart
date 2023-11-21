import 'package:flutter/material.dart';

import '../../Constants/constants.dart';

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
  String inputEncodingStr = Const.inputEncodingList[0];
  String outputEncodingStr = Const.outputEncodingList[0];
  String textTypeStr = Const.textTypeList[0];
  late Size dSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Morph Analyser'),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                                String mode =
                                    Const.textTypeAbbreviation(textTypeStr);
                                String inEnStr = Const.encodingAbbreviation(
                                    inputEncodingStr);
                                String outEnStr = Const.outEncodingAbbreviation(
                                    outputEncodingStr);

                                // WebAPI.sandhiSplitter(
                                //     input1: inputStr1,
                                //     textType: mode,
                                //     inEncoding: inEnStr,
                                //     outEncoding: outEnStr)
                                //     .then((value) {
                                //   setState(() {
                                //     _isLoading = false;
                                //     outputStr1 =
                                //         value['segmentation'].toString();
                                //     // print(value);
                                //   });
                                // });
                              },
                              child: const Text('Show Analysis')),
                        ),
                      ],
                    ),

                    // create a text field to display output
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          child: TextFormField(
                            autofocus: true,
                            controller: TextEditingController(text: outputStr1),
                            decoration: const InputDecoration(
                              labelText: 'Output:',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Column(
              //   children: [
              //     Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceAround,
              //       children: [
              //         const Text('Powered by'),
              //         ElevatedButton(
              //             onPressed: _launchUrl,
              //             child: const Text('Sanskrit Heritage Platform')),
              //         const SizedBox(width: 5),
              //       ],
              //     ),
              //     const SizedBox(height: 5),
              //   ],
              // ),
            ],
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
