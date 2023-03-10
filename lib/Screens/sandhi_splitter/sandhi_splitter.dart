import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../Constants/constants.dart';

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
  // String inputStr2 = '';
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
                        // setState(() {
                        //   _isLoading = true;
                        // });
                        // String inputStr1 = firstInputController.text;
                        // String inputStr2 = secondInputController.text;
                        // String inEnStr =
                        // Const.encodingAbbreviation(inputEncodingStr);
                        // String outEnStr =
                        // Const.encodingAbbreviation(outputEncodingStr);
                        //
                        // WebAPI.sandhiRequest(
                        //   input1: inputStr1,
                        //   input2: inputStr2,
                        //   inEncoding: inEnStr,
                        //   outEncoding: outEnStr,
                        // ).then((dataList) {
                        //   setState(() {
                        //     _isLoading = false;
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => SandhiOutput(
                        //             data: dataList,
                        //             encoding: outputEncodingStr),
                        //       ),
                        //     );
                        //   });
                        // });
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
