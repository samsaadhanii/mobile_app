import 'package:flutter/cupertino.dart';
import '../../Constants/constants.dart';
import '../../web_api.dart';
import '../cupertino_data_not_found.dart';
import 'cupertino_noun_gen_output1.dart';

const double _kItemExtent = 32.0;

class CupertinoNounGenerator extends StatefulWidget {
  const CupertinoNounGenerator({Key? key}) : super(key: key);

  @override
  State<CupertinoNounGenerator> createState() => _CupertinoNounGeneratorState();
}

class _CupertinoNounGeneratorState extends State<CupertinoNounGenerator> {
  int _selectedIE = 0;
  int _selectedOE = 0;
  int _category = 0;
  int _gender = 0;
  final TextEditingController _inputTextController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inputTextController.text = 'राम';
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
          middle: Text('Noun Generator'),
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
          cDropDown(
              text1: 'Input encoding: ',
              selected: _selectedIE,
              ddList: Const.inputEncodingList,
              onChange: (value) {
                setState(() {
                  _selectedIE = value!;
                });
              }),
          const SizedBox(height: 5),
          cDropDown(
              text1: 'Output encoding: ',
              selected: _selectedOE,
              ddList: Const.outputEncodingList,
              onChange: (value) {
                setState(() {
                  _selectedOE = value!;
                });
              }),
          const SizedBox(height: 5),
          Row(
            children: [
              const SizedBox(width: 10),
              const SizedBox(
                width: 130,
                child: Text('प्रातिपदिकम्/Prātipadikam:'),
              ),
              Container(
                width: 215,
                padding: const EdgeInsets.all(8.0),
                // alignment: Alignment.centerRight,
                child: CupertinoTextField(
                  controller: _inputTextController,
                  placeholder: 'प्रातिपदिकम्/Prātipadikam',
                  padding: const EdgeInsets.all(15.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          cDropDown(
              text1: 'Category: ',
              selected: _category,
              ddList: Const.categoryList,
              onChange: (value) {
                setState(() {
                  _category = value!;
                });
              }),
          const SizedBox(height: 5),
          cDropDown(
              text1: 'Gender: ',
              selected: _gender,
              ddList: Const.genderList,
              onChange: (value) {
                setState(() {
                  _gender = value!;
                });
              }),
          const SizedBox(height: 30),
          CupertinoButton.filled(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              String inputStr = _inputTextController.text;
              String inputEncodingStr = Const.encodingAbbreviation(
                  Const.inputEncodingList[_selectedIE]);
              String outputEncodingStr = Const.encodingAbbreviation(
                  Const.outputEncodingList[_selectedOE]);
              String gender =
                  Const.genderAbbreviation(Const.genderList[_gender]);
              String category =
                  Const.catAbbreviation(Const.categoryList[_category]);

              WebAPI.nounGenRequest(
                inputString: inputStr,
                gender: gender,
                category: category,
                inEncoding: inputEncodingStr,
                outEncoding: outputEncodingStr,
              ).then(
                (dataList) {
                  setState(
                    () {
                      _isLoading = false;
                      if (dataList.isEmpty) {
                        Future.delayed(Duration.zero, () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (BuildContext context) {
                                return const CupertinoDataNotFound();
                              },
                            ),
                          );
                        });
                      } else {
                        Map curData = formatData(dataList);
                        Future.delayed(Duration.zero, () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (BuildContext context) {
                                return CupertinoNGOutput(
                                  data: curData,
                                  encoding: inputEncodingStr,
                                  gender: gender,
                                  inputWord: inputStr,
                                );
                              },
                            ),
                          );
                        });
                      }
                    },
                  );
                },
              );
            },
            child: const Text('रूपाणि दर्श्यताम्'),
          ),
        ],
      ),
    );
  }

  Center cDropDown(
      {required String text1,
      required int selected,
      required List ddList,
      required MyFunction onChange}) {
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
                  ddList[selected],
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

  /// formatting WX to IAST displayable format
  Map formatData(List data) {
    Map<String, List<String>> curData = <String, List<String>>{};
    List<String> vacanam = [];
    for (var element in data) {
      if (element['vib'] != null) {
        curData.putIfAbsent(element['vib'], () => [element['vib'], '', '', '']);
      }
      if (element['vac'] != null) {
        if (!vacanam.contains(element['vac'])) vacanam.add(element['vac']);
      }
    }
    // curData.forEach((key, value) {
    //   print(value);
    // });
    for (var element in data) {
      // print(element['vib']);
      String key = element['vib'];
      if (curData.containsKey(key)) {
        if (element['vac'].toString().contains(vacanam[0])) {
          curData[key]![1] = element['form'];
        } else if (element['vac'].toString().contains(vacanam[1])) {
          curData[key]![2] = element['form'];
        } else if (element['vac'].toString().contains(vacanam[2])) {
          curData[key]![3] = element['form'];
        }
        // print(curData[key]);
      }
    }
    return curData;
  }
}
