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
}
