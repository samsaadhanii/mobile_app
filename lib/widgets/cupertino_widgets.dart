import 'package:flutter/cupertino.dart';
import 'package:mobile_app/Constants/constants.dart';

const double _kItemExtent = 32.0;

class CW {
  // This shows a CupertinoModalPopup with a reasonable fixed height which hosts CupertinoPicker.

  static cupertinoDropDown(
      BuildContext context, List dropDownList, MyFunction onChange) {
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
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: _kItemExtent,
            // This is called when selected item is changed.
            onSelectedItemChanged: onChange,
            children: List<Widget>.generate(dropDownList.length, (int index) {
              return Center(
                child: Text(
                  dropDownList[index],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static Center cDropDown(
      {required String text1,
        required String selected,
        required List ddList,
        required MyFunction2 onChange,
      required BuildContext context,}) {
    Size dSize = MediaQuery.sizeOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            SizedBox(
              width: dSize.width*0.4,
              child: Text(text1,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  )),
            ),
            Container(
              width: dSize.width*0.5,
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
                  ),context,
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


  static void _showDialog(Widget child, BuildContext context) {
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
