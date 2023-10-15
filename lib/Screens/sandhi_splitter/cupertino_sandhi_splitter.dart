import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../web_api.dart';
import '../../widgets/cupertino_widgets.dart';
import '../../Constants/constants.dart';

class CupertinoSandhiSplitter extends StatefulWidget {
  const CupertinoSandhiSplitter({super.key});

  @override
  State<CupertinoSandhiSplitter> createState() =>
      _CupertinoSandhiSplitterState();
}

class _CupertinoSandhiSplitterState extends State<CupertinoSandhiSplitter> {
  TextEditingController firstInputController = TextEditingController();

  // TextEditingController secondInputController = TextEditingController();
  bool _isLoading = false;
  String inputStr1 = '';
  String outputStr1 = '';
  String inputEncodingStr = Const.inputEncodingList[0];
  String outputEncodingStr = Const.outputEncodingList[0];
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
    dSize = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Sandhi Splitter'),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 20),

                          ///Input Encoder
                          CW.cDropDown(
                              text1: 'Input encoding: ',
                              selected: inputEncodingStr,
                              ddList: Const.inputEncodingList,
                              onChange: (value) {
                                setState(() {
                                  inputEncodingStr = Const.inputEncodingList[value!];
                                });
                              },
                              context: context),
                          const SizedBox(height: 5),

                          ///Output Encoder
                          CW.cDropDown(
                              text1: 'Output encoding: ',
                              selected: outputEncodingStr,
                              ddList: Const.outputEncodingList,
                              onChange: (value) {
                                setState(() {
                                  outputEncodingStr =
                                      Const.outputEncodingList[value!];
                                });
                              },
                              context: context),
                          const SizedBox(height: 5),

                          ///Text Type
                          CW.cDropDown(
                              text1: 'Text Type: ',
                              selected: textTypeStr,
                              ddList: Const.textTypeList,
                              onChange: (value) {
                                setState(() {
                                  textTypeStr = Const.textTypeList[value!];
                                });
                              },
                              context: context),
                          const SizedBox(height: 10),

                          /// Input 1
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              SizedBox(
                                width: dSize.width*0.4,
                                child: const Text('First Word'),
                              ),
                              Container(
                                width: dSize.width*0.5,
                                padding: const EdgeInsets.all(8.0),
                                // alignment: Alignment.centerRight,
                                child: CupertinoTextField(
                                  controller: firstInputController,
                                  placeholder: 'First Word',
                                  padding: const EdgeInsets.all(15.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          /// button
                          CupertinoButton.filled(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                              });
                              String inputStr1 = firstInputController.text;
                              String mode = Const.textTypeAbbreviation(textTypeStr);
                              String inEnStr =
                                  Const.encodingAbbreviation(inputEncodingStr);
                              String outEnStr =
                                  Const.outEncodingAbbreviation(outputEncodingStr);

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
                            child: const Text('Submit'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // create a text field to display output
                      CupertinoFormRow(
                        helper: const Text('Output',style: TextStyle(color: Colors.black26),),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                        child: CupertinoTextField(
                          controller: TextEditingController(
                            text: outputStr1,
                          ),
                          maxLines: null,
                          // placeholder: 'Output',
                          keyboardType: TextInputType.none,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text('Powered by Sanskrit Heritage Platform'),
                    CupertinoButton(onPressed: _launchUrl, child: const Text('https://sanskrit.inria.fr')),
                    const SizedBox(height: 5),
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
  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }
  }
