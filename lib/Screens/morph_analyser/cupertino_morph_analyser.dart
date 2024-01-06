import 'package:flutter/cupertino.dart';
import '../../web_api.dart';
import '../../Constants/constants.dart';

class CupertinoMorphAnalyser extends StatefulWidget {
  const CupertinoMorphAnalyser({super.key});

  @override
  State<CupertinoMorphAnalyser> createState() => _CupertinoMorphAnalyserState();
}

class _CupertinoMorphAnalyserState extends State<CupertinoMorphAnalyser> {
  TextEditingController firstInputController = TextEditingController();
  bool _isLoading = false;
  late Size dSize;
  String inputStr1 = '';
  String outputStr1 = '';
  String outputStr2 = '';

  @override
  void initState() {
    firstInputController.text = 'रामः';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    dSize = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Morphological Analyser (शब्द-विश्लेषक)'),
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

                          /// Input 1
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              SizedBox(
                                width: dSize.width * 0.4,
                                child: const Text('Input Word'),
                              ),
                              Container(
                                width: dSize.width * 0.5,
                                padding: const EdgeInsets.all(8.0),
                                // alignment: Alignment.centerRight,
                                child: CupertinoTextField(
                                  controller: firstInputController,
                                  placeholder: 'Input Word',
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
                              String inEnStr =
                                  Const.encodingAbbreviation(inputEncodingStr);
                              String outEnStr =
                                  Const.morphOutEncodingAbbreviation(
                                      outputEncodingStr);
                              WebAPI.morphAnalyser(
                                input1: inputStr1,
                                inEncoding: inEnStr,
                                outEncoding: outEnStr,
                              ).then((value) {
                                List<dynamic> morphList = value;

                                setState(() {
                                  if (morphList.isNotEmpty) {
                                    outputStr1 =
                                        '${morphList[0]['RT']} ${morphList[0]['ANS']}';
                                    outputStr2 = morphList[1]['RT'] +
                                        ' ' +
                                        morphList[1]['ANS'];
                                  } else {
                                    outputStr1 = 'No analysis found';
                                  }
                                  _isLoading = false;
                                });
                              });
                            },
                            child: const Text('Show Analysis'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // create a text field to display output
                      CupertinoFormSection(
                        header: const Text('Output'),
                        children: [
                          CupertinoFormRow(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: CupertinoColors.systemGrey,
                                ),
                                borderRadius: BorderRadius.circular(5),
                                color: outputStr1.isNotEmpty
                                    ? CupertinoColors
                                        .systemPink.darkHighContrastColor
                                    : CupertinoColors.systemGrey4,
                              ),
                              child: Text(outputStr1),
                            ),
                          ),
                          CupertinoFormRow(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: CupertinoColors.systemGrey,
                                ),
                                borderRadius: BorderRadius.circular(5),
                                color: outputStr2.isNotEmpty
                                    ? CupertinoColors.systemTeal
                                    : CupertinoColors.systemGrey4,
                              ),
                              child: Text(outputStr2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const Opacity(
            opacity: 0.2,
            child:
                ModalBarrier(dismissible: false, color: CupertinoColors.black),
          ),
        if (_isLoading)
          const Center(
            child: CupertinoActivityIndicator(
              radius: 10,
            ),
          ),
      ],
    );
  }
}
