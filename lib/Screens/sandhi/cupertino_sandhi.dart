import 'package:flutter/cupertino.dart';
import '../../Constants/constants.dart';
import '../../web_api.dart';
import 'cupertino_sandhi_output.dart';

// const double _kItemExtent = 32.0;

class CupertinoSandhi extends StatefulWidget {
  const CupertinoSandhi({Key? key}) : super(key: key);

  @override
  State<CupertinoSandhi> createState() => _CupertinoSandhiState();
}

class _CupertinoSandhiState extends State<CupertinoSandhi> {
  TextEditingController firstInputController = TextEditingController();
  TextEditingController secondInputController = TextEditingController();
  bool _isLoading = false;
  String inputStr1 = '';
  String inputStr2 = '';
  // String inputEncodingStr = Const.inputEncodingList[0];
  // String outputEncodingStr = Const.outputEncodingList[0];
  bool transliterated = false;
  LearnerLevel? _lType = LearnerLevel.basic;
  late Size dSize;

  @override
  void initState() {
    firstInputController.text = 'लक्ष्मीवान्';
    secondInputController.text = 'शुभलक्षणः';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    dSize = MediaQuery.sizeOf(context);
    return Stack(children: [
      CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Sandhi'),
        ),
        child: body(),
      ),
      if (_isLoading)
        const Opacity(
          opacity: 0.8,
          child: ModalBarrier(dismissible: false, color: CupertinoColors.white),
        ),
      if (_isLoading)
        const Center(
          child: CupertinoActivityIndicator(
              radius: 20.0, color: CupertinoColors.activeBlue),
        ),
    ]);
  }

  Widget body() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Row(
          //   children: [
          //     const SizedBox(width: 50),
          //     Column(
          //       children: [
          //         Row(
          //           children: [
          //             const SizedBox(width: 150, child: Text('Basic')),
          //             CupertinoSwitch(
          //               value: _basicSwitch,
          //               onChanged: (value) {
          //                 _basicSwitch = value;
          //                 _interSwitch = !value;
          //                 _advSwitch = !value;
          //               },
          //             ),
          //           ],
          //         ),
          //         Row(
          //           children: [
          //             const SizedBox(width: 150, child: Text('Intermediate')),
          //             CupertinoSwitch(
          //               value: _interSwitch,
          //               onChanged: (value) {
          //                 _interSwitch = value;
          //                 if (_interSwitch) {
          //                   _basicSwitch = false;
          //                   _advSwitch = false;
          //                 }
          //               },
          //             ),
          //           ],
          //         ),
          //         Row(
          //           children: [
          //             const SizedBox(width: 150, child: Text('Advanced')),
          //             CupertinoSwitch(
          //               value: _advSwitch,
          //               onChanged: (value) {
          //                 _advSwitch = value;
          //                 if (_advSwitch) {
          //                   _basicSwitch = false;
          //                   _interSwitch = false;
          //                 }
          //               },
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ],
          // ),
          CupertinoListSection(
            children: [
              CupertinoListTile(
                title: const Text("Basic"),
                leading: CupertinoRadio<LearnerLevel>(
                  value: LearnerLevel.basic,
                  groupValue: _lType,
                  onChanged: (LearnerLevel? value) {
                    setState(() {
                      _lType = value;
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("Intermediate"),
                leading: CupertinoRadio<LearnerLevel>(
                  value: LearnerLevel.intermediate,
                  groupValue: _lType,
                  onChanged: (LearnerLevel? value) {
                    setState(() {
                      _lType = value;
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("Advanced"),
                leading: CupertinoRadio<LearnerLevel>(
                  value: LearnerLevel.advanced,
                  groupValue: _lType,
                  onChanged: (LearnerLevel? value) {
                    setState(() {
                      _lType = value;
                    });
                  },
                ),
              )
            ],
          ),
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
          const SizedBox(height: 5),

          /// Input 2
          Row(
            children: [
              const SizedBox(width: 10),
              SizedBox(
                width: dSize.width*0.4,
                child: const Text('Second Word'),
              ),
              Container(
                width: dSize.width*0.5,
                padding: const EdgeInsets.all(8.0),
                // alignment: Alignment.centerRight,
                child: CupertinoTextField(
                  controller: secondInputController,
                  placeholder: 'Second Word',
                  padding: const EdgeInsets.all(15.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          CupertinoButton.filled(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              String inputStr1 = firstInputController.text;
              String inputStr2 = secondInputController.text;
              String inEnStr = Const.encodingAbbreviation(inputEncodingStr);
              String outEnStr = Const.encodingAbbreviation(outputEncodingStr);

              WebAPI.sandhiRequest(
                input1: inputStr1,
                input2: inputStr2,
                inEncoding: inEnStr,
                outEncoding: outEnStr,
              ).then(
                (dataList) {
                  print(dataList);
                  setState(
                    () {
                      _isLoading = false;
                      Future.delayed(Duration.zero, () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (BuildContext context) {
                              return CupertinoSandhiOutput(
                                data: dataList,
                                encoding: outputEncodingStr,
                                lType: _lType,
                              );
                            },
                          ),
                        );
                      });
                    },
                  );
                },
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

}
