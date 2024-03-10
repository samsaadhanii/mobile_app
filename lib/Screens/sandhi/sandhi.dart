import 'package:flutter/material.dart';
import 'package:mobile_app/Screens/sandhi/sandhi_output.dart';

import '../../Constants/constants.dart';
import '../../web_api.dart';

class Sandhi extends StatefulWidget {
  const Sandhi({Key? key}) : super(key: key);

  @override
  State<Sandhi> createState() => _SandhiState();
}

/// ***************************************************************************
/// Sandhi joining screen for Android devices
/// Here we provide options for the user to select the learner level
/// Which is the input screen for sandhi joining with two input fields
/// And a submit button to send the request to the server
/// ***************************************************************************
class _SandhiState extends State<Sandhi> {
  TextEditingController firstInputController = TextEditingController();
  TextEditingController secondInputController = TextEditingController();
  bool _isLoading = false;
  String inputStr1 = '';
  String inputStr2 = '';
  bool transliterated = false;
  LearnerLevel _lType = LearnerLevel.basic;

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

                ListTile(
                  title: const Text('Basic'),
                  leading: Radio<LearnerLevel>(
                    value: LearnerLevel.basic,
                    groupValue: _lType,
                    onChanged: (LearnerLevel? value) {
                      setState(() {
                        _lType = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Intermediate'),
                  leading: Radio<LearnerLevel>(
                    value: LearnerLevel.intermediate,
                    groupValue: _lType,
                    onChanged: (LearnerLevel? value) {
                      setState(() {
                        _lType = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Advanced'),
                  leading: Radio<LearnerLevel>(
                    value: LearnerLevel.advanced,
                    groupValue: _lType,
                    onChanged: (LearnerLevel? value) {
                      setState(() {
                        _lType = value!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

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
                        String inputStr1 = firstInputController.text;
                        String inputStr2 = secondInputController.text;
                        String inEnStr =
                            Const.encodingAbbreviation(inputEncodingStr);
                        String outEnStr =
                            Const.encodingAbbreviation(outputEncodingStr);

                        WebAPI.sandhiRequest(
                          input1: inputStr1,
                          input2: inputStr2,
                          inEncoding: inEnStr,
                          outEncoding: outEnStr,
                        ).then((dataList) {
                          setState(() {
                            _isLoading = false;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SandhiOutput(
                                  data: dataList,
                                  encoding: outputEncodingStr,
                                  lType: _lType,
                                ),
                              ),
                            );
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
}
