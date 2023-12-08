import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String textTypeStr = Const.textTypeList[0];
  late Size dSize;
  final Uri _url = Uri.parse('https://sanskrit.inria.fr');

  @override
  void initState() {
    firstInputController.text = 'कश्चित्कान्ताविरहगुरुणास्वाधिकारात्प्रमत्तः';
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
                                String inEnStr = Const.encodingAbbreviation(
                                    inputEncodingStr);
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
                                    outputStr1 =
                                        value['segmentation'].toString();
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
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text('Powered by'),
                      ElevatedButton(
                          onPressed: _launchUrl,
                          child: const Text('Sanskrit Heritage Platform')),
                      const SizedBox(width: 5),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              ),
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

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }
}
