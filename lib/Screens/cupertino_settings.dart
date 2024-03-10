import 'package:flutter/cupertino.dart';

import '../Constants/constants.dart';

class CupertinoSettings extends StatefulWidget {
  const CupertinoSettings({super.key});

  @override
  State<CupertinoSettings> createState() => _CupertinoSettingsState();
}

const double _kItemExtent = 32.0;

/// *********************************************************************
/// Saṃsādhanī app for Cupertino (iOS) devices
/// This is the settings screen for the app (सेटिङ्गहरू)
/// It provides options for the user to select the input and output encoding
/// which is used throughout the app for the conversion of text
/// *********************************************************************
class _CupertinoSettingsState extends State<CupertinoSettings> {
  final bool _isLoading = false;
  late Size dSize;

  @override
  Widget build(BuildContext context) {
    dSize = MediaQuery.sizeOf(context);
    return Stack(children: [
      CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Settings'),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Column(
            children: [
              SizedBox(height: 10),
              Text('Select appropriate input and output encoding'),
              SizedBox(height: 10),
              Text('This will be used throughout this app'),
              SizedBox(height: 10),
            ],
          ),
          Column(
            children: [
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
            ],
          ),
          const SizedBox(height: 5),
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
              width: dSize.width * 0.4,
              child: Text(text1,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  )),
            ),
            Container(
              width: dSize.width * 0.5,
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
}
