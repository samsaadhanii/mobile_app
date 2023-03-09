import 'package:flutter/cupertino.dart';

import '../../Constants/constants.dart';
import '../../web_api.dart';
import 'cupertino_sandhi_output.dart';

const double _kItemExtent = 32.0;

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
  String inputEncodingStr = Const.inputEncodingList[0];
  String outputEncodingStr = Const.outputEncodingList[0];
  bool transliterated = false;
  bool _basicSwitch = true;
  bool _interSwitch = false;
  bool _advSwitch = false;

  @override
  void initState() {
    firstInputController.text = 'लक्ष्मीवान्';
    secondInputController.text = 'शुभलक्षणः';
    super.initState();
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              // The Bottom margin is provided to align the popup above the system navigation bar.
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              // Provide a background color for the popup.
              color: CupertinoColors.systemBackground.resolveFrom(context),
              // Use a SafeArea widget to avoid system overlaps.
              child: SafeArea(
                top: false,
                child: child,
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Text('Basic'),
                  CupertinoSwitch(
                    value: _basicSwitch,
                    onChanged: (value) {
                      _basicSwitch = value;
                      if (_basicSwitch) {
                        _interSwitch = false;
                        _advSwitch = false;
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Intermediate'),
                  CupertinoSwitch(
                    value: _interSwitch,
                    onChanged: (value) {
                      _interSwitch = value;
                      if (_interSwitch) {
                        _basicSwitch = false;
                        _advSwitch = false;
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Advanced'),
                  CupertinoSwitch(
                    value: _advSwitch,
                    onChanged: (value) {
                      _advSwitch = value;
                      if (_advSwitch) {
                        _basicSwitch = false;
                        _interSwitch = false;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          cDropDown(
              text1: 'Input encoding: ',
              selected: inputEncodingStr,
              ddList: Const.inputEncodingList,
              onChange: (value) {
                setState(() {
                  inputEncodingStr = Const.inputEncodingList[value!];
                });
              }),
          const SizedBox(height: 5),
          cDropDown(
              text1: 'Output encoding: ',
              selected: outputEncodingStr,
              ddList: Const.outputEncodingList,
              onChange: (value) {
                setState(() {
                  outputEncodingStr = Const.outputEncodingList[value!];
                });
              }),
          const SizedBox(height: 5),

          /// Input 1
          Row(
            children: [
              const SizedBox(width: 10),
              const SizedBox(
                width: 130,
                child: Text('First Word'),
              ),
              Container(
                width: 215,
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
              const SizedBox(
                width: 130,
                child: Text('Second Word'),
              ),
              Container(
                width: 215,
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

  Center cDropDown(
      {required String text1,
      required String selected,
      required List ddList,
      required MyFunction2 onChange}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            SizedBox(
              width: 130,
              child: Text(text1,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  )),
            ),
            Container(
              width: 200,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  border: Border.all(color: CupertinoColors.lightBackgroundGray)
                  // color: CupertinoColors.extraLightBackgroundGray,
                  ),
              // padding: const EdgeInsets.all(7.0),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                // Display a CupertinoPicker with list of fruits.
                onPressed: () => _showDialog(
                  CupertinoPicker(
                    magnification: 1.5,
                    squeeze: 1,
                    useMagnifier: true,
                    itemExtent: _kItemExtent,
                    // This is called when selected item is changed.
                    onSelectedItemChanged: onChange,
                    children: List<Widget>.generate(ddList.length, (int index) {
                      return Center(
                        child: Text(
                          ddList[index],
                        ),
                      );
                    }),
                  ),
                ),
                // This displays the selected fruit name.
                child: Text(
                  selected,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
