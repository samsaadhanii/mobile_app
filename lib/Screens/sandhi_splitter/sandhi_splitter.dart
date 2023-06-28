import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../Constants/constants.dart';
import '../../web_api.dart';

class SandhiSplitter extends StatefulWidget {
  const SandhiSplitter({Key? key}) : super(key: key);

  @override
  State<SandhiSplitter> createState() => _SandhiSplitterState();
}

class _SandhiSplitterState extends State<SandhiSplitter> {
  TextEditingController firstInputController = TextEditingController();
  // TextEditingController secondInputController = TextEditingController();
  bool _isLoading = false;
  String inputStr1 = '';
  String outputStr1 = '';
  String inputEncodingStr = Const.inputEncodingList[0];
  String outputEncodingStr = Const.outputEncodingList[0];
  String textTypeStr = Const.textTypeList[0];

  @override
  void initState() {
    firstInputController.text = 'कश्चित्कान्ताविरहगुरुणास्वाधिकारात्प्रमत्त';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Sandhi Splitter'),
          ),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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

                    ///Text Type
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: FormBuilderDropdown(
                        name: 'Text Type',
                        items: Const.textTypeList.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: "Text Type",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: textTypeStr,
                        onChanged: (value) {
                          textTypeStr = value!;
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
                            String inEnStr =
                                Const.encodingAbbreviation(inputEncodingStr);
                            String outEnStr = Const.outEncodingAbbreviation(
                                outputEncodingStr);

                            WebAPI.sandhiSplitter(
                                    input1: inputStr1,
                                    textType: mode,
                                    inEncoding: inEnStr,
                                    outEncoding: outEnStr)
                                .then((value) {
                              setState(() {
                                _isLoading = false;
                                outputStr1 = value['segmentation'].toString();
                                // print(value);
                              });
                            });
                          },
                          child: const Text('Submit')),
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
