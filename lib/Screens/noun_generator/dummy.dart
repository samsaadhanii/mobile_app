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
  TextEditingController inputController = TextEditingController();
  bool _isLoading = false;
  String inputStr = '';
  String inputEncodingStr = Const.inputEncodingList[0];
  String outputEncodingStr = Const.outputEncodingList[0];
  String gender = Const.genderList[0];
  String category = Const.categoryList[0];

  @override
  void initState() {
    super.initState();
    inputController.text = 'राम';
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
                  controller: inputController,
                  placeholder: 'प्रातिपदिकम्/Prātipadikam',
                  padding: const EdgeInsets.all(15.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          cDropDown(
              text1: 'Category: ',
              selected: category,
              ddList: Const.categoryList,
              onChange: (value) {
                setState(() {
                  category = Const.categoryList[value!];
                });
              }),
          const SizedBox(height: 5),
          cDropDown(
              text1: 'Gender: ',
              selected: gender,
              ddList: Const.genderList,
              onChange: (value) {
                setState(() {
                  gender = Const.genderList[value!];
                });
              }),
          const SizedBox(height: 30),
          CupertinoButton.filled(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              String inputStr = inputController.text;
              String inEnStr = Const.encodingAbbreviation(inputEncodingStr);
              String outEnStr = Const.encodingAbbreviation(outputEncodingStr);
              String gen = Const.genderAbbreviation(gender);
              String cate = Const.catAbbreviation(category);

              WebAPI.nounGenRequest(
                inputString: inputStr,
                gender: gen,
                category: cate,
                inEncoding: inEnStr,
                outEncoding: outEnStr,
              ).then(
                (dataList) {
                  setState(
                    () {
                      setState(() {
                        _isLoading = false;
                      });
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
                                  encoding: outputEncodingStr,
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
