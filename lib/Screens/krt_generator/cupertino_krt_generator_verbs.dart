import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../Constants/constants.dart';
import '../../model/data_provider.dart';
import 'cupertino_krt_generator_output.dart';

class CupertinoKrtGeneratorVerbs extends StatefulWidget {
  const CupertinoKrtGeneratorVerbs({super.key, required this.selectedPrefix});

  final String selectedPrefix;

  @override
  State<CupertinoKrtGeneratorVerbs> createState() =>
      _CupertinoKrtGeneratorVerbsState();
}

/// ************************************************************
/// This is the Cupertino version of the Krt Generator Verbs screen.
/// It is called from CupertinoKrtGeneratorPrefix.
/// It displays the list of verbs for the selected prefix.
/// The user selects a verb from the list.
/// The selected verb is passed to CupertinoKrtGeneratorOutput.
///
class _CupertinoKrtGeneratorVerbsState
    extends State<CupertinoKrtGeneratorVerbs> {
  bool _isLoading = false;
  List<Map<String, dynamic>> verbList = [];
  String selectedVerb = '';
  bool verbListReady = false;
  bool updateData = true;
  int selectedIndex = 0;
  final ScrollController controller = ScrollController();
  List<String> displayVerbList = [];
  String searchText = '';
  int indexCnt = 0;

  @override
  void didChangeDependencies() {
    _isLoading =
        !Provider.of<DataProvider>(context, listen: true).verbDataLoaded;
    if (Provider.of<DataProvider>(context, listen: true).verbDataLoaded) {
      if (updateData) {
        updateData = false;
        verbList = Provider.of<DataProvider>(context).verbData;
        // for (var element in data) {
        //   Map<String, dynamic> tmp = element;
        //   verbList.add(tmp);
        // }
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.sizeOf(context).width;
    if (verbList.isNotEmpty) {
      displayVerbList.clear();
      for (var element in verbList) {
        String verb = element[Const.verbEncodingAbbreviation(inputEncodingStr)];
        bool tmp = verb.contains(searchText);
        if (tmp) {
          displayVerbList.add(verb);
        }
      }
    }
    return Stack(children: [
      SafeArea(
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Krt Generator (कृदन्तरूपनिष्पादिका)'),
          ),
          child: (_isLoading)
              ? const Center(child: Text('loading!'))
              : SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// Heading - verbs
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            'Verbal Root', // Set the title text here
                            style: TextStyle(
                              fontSize: 20, // Set the font size

                              fontWeight:
                                  FontWeight.bold, // Set the font weight
                            ),
                          ),
                        ),
                      ),

                      /// Search bar for verbs
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SearchTextField(
                          fieldValue: (String value) {
                            setState(() {
                              searchText = value;
                            });
                          },
                        ),
                      ),

                      /// Display the list of verbs
                      displayVerbList.isNotEmpty
                          ? SizedBox(
                              height: w * 0.9,
                              child: SingleChildScrollView(
                                child: CupertinoListSection(
                                  children: generateList(),
                                ),
                              ),
                            )
                          : Container(),
                      // Text(selectedVerb),
                      const SizedBox(height: 10),
                      CupertinoButton(
                          onPressed: () {
                            print('selectedPrefix: ${widget.selectedPrefix}');
                            print(
                                'selectedVerb: ${verbList[selectedIndex]['wx']}');
                            Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) =>
                                        CupertinoKrtGeneratorOutput(
                                          selectedPrefix: widget.selectedPrefix,
                                          selectedVerb: verbList[selectedIndex]
                                              ['wx'],
                                        )));
                          },
                          child: const Text('Next')),
                    ],
                  ),
                ),
        ),
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

  List<CupertinoListTile> generateList() {
    List<CupertinoListTile> list = [];
    for (int i = 0; i < displayVerbList.length; i++) {
      String e = displayVerbList[i];
      list.add(CupertinoListTile(
        title: Text(e),
        backgroundColor: selectedVerb.compareTo(e) == 0
            ? CupertinoColors.activeBlue
            : (indexCnt++) % 2 == 0
                ? CupertinoColors.lightBackgroundGray
                : CupertinoColors.white,
        onTap: () {
          setState(() {
            selectedVerb = e;
            selectedIndex = i;
          });
        },
      ));
    }
    return list;
  }
}

class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    required this.fieldValue,
  });

  final ValueChanged<String> fieldValue;

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      onChanged: (String value) {
        fieldValue(value);
      },
      onSubmitted: (String value) {
        fieldValue(value);
      },
    );
  }
}
