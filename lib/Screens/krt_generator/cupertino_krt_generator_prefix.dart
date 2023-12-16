import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../Constants/constants.dart';
import '../../model/data_provider.dart';
import 'cupertino_krt_generator_verbs.dart';

class CupertinoKrtGeneratorPrefix extends StatefulWidget {
  const CupertinoKrtGeneratorPrefix({super.key});

  @override
  State<CupertinoKrtGeneratorPrefix> createState() =>
      _CupertinoKrtGeneratorPrefixState();
}

class _CupertinoKrtGeneratorPrefixState
    extends State<CupertinoKrtGeneratorPrefix> {
  bool _isLoading = false;
  List<Map<String, dynamic>> prefixList = [];
  String selectedPrefix = '';
  bool prefixListReady = false;
  bool updatePrefix = true;
  int selectedIndex = 0;
  final ScrollController controller = ScrollController();
  List<String> displayPrefixList = [];
  String searchText = '';
  int indexCnt = 0;

  @override
  void didChangeDependencies() {
    _isLoading =
        !Provider.of<DataProvider>(context, listen: true).prefixDataLoaded;
    if (Provider.of<DataProvider>(context, listen: true).prefixDataLoaded) {
      if (updatePrefix) {
        updatePrefix = false;
        prefixList = Provider.of<DataProvider>(context).prefixData;
      }
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.sizeOf(context).width;
    var list = Provider.of<DataProvider>(context).prefixData;
    print('list length: ${list.length}');
    if (list.length > 1) {
      /// Fill the prefix list with the prefixes of the selected encoding
      displayPrefixList.clear();
      for (var element in list) {
        String? tmp =
            element[Const.prefixEncodingAbbreviation(inputEncodingStr)];
        if (tmp != null) {
          if (searchText.isEmpty) {
            displayPrefixList.add(tmp);
          } else {
            if (tmp.contains(searchText)) displayPrefixList.add(tmp);
          }
        }
      }
      print('displayPrefixList length: ${displayPrefixList.length}');
      _isLoading = false;
    } else {
      _isLoading = true;
    }
    return Stack(children: [
      SafeArea(
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Krt Generator'),
          ),
          child: (_isLoading)
              ? const Center(child: Text('loading!'))
              : SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// Heading - prefixes
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            'Prefixes', // Set the title text here
                            style: TextStyle(
                              fontSize: 20, // Set the font size

                              fontWeight:
                                  FontWeight.bold, // Set the font weight
                            ),
                          ),
                        ),
                      ),

                      /// Search bar for prefixes
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

                      /// Display the list of Prefixes
                      displayPrefixList.length > 1
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                color: CupertinoColors.activeOrange,
                                height: w * 0.9,
                                child: SingleChildScrollView(
                                  child: CupertinoListSection(
                                    children: displayPrefixList
                                        .map(
                                          (e) => CupertinoListTile(
                                            title: Text(e),
                                            backgroundColor:
                                                selectedPrefix.compareTo(e) == 0
                                                    ? CupertinoColors.activeBlue
                                                    : (indexCnt++) % 2 == 0
                                                        ? CupertinoColors
                                                            .lightBackgroundGray
                                                        : CupertinoColors.white,
                                            onTap: () {
                                              setState(() {
                                                selectedPrefix = e;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      // Text(selectedVerb),
                      const SizedBox(height: 10),
                      CupertinoButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) =>
                                        CupertinoKrtGeneratorVerbs(
                                            selectedPrefix: selectedPrefix)));
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
