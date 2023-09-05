import 'package:flutter/material.dart';
import 'package:mobile_app/Constants/constants.dart';
import 'package:mobile_app/Screens/verb_generator/verb_generator_page2.dart';
import 'package:mobile_app/model/data_provider.dart';
import 'package:provider/provider.dart';
import 'package:searchable_listview/searchable_listview.dart';

class VerbGeneratorPage1 extends StatefulWidget {
  const VerbGeneratorPage1({super.key});

  @override
  State<VerbGeneratorPage1> createState() => _VerbGeneratorPage1State();
}

class _VerbGeneratorPage1State extends State<VerbGeneratorPage1> {
  bool _isLoading = false;
  List<Map<String, dynamic>> verbList = [];
  String selectedVerb = '';
  bool verbListReady = false;
  bool updateData = true;
  int selectedIndex = 0;
  int selectedEncoding = 0;
  final ScrollController controller = ScrollController();
  List<String> displayVerbList = [];

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
    print('selectedEncoding: ${Const.outputEncodingList[selectedEncoding]}');
    if (verbList.isNotEmpty) {
      displayVerbList.clear();
      for (var element in verbList) {
        displayVerbList.add(element[Const.verbEncodingAbbreviation(
            Const.verbEncodingList[selectedEncoding])]);
      }
    }
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Center(child: Text('Verb Generator')),
            actions: [
              PopupMenuButton<int>(
                onSelected: (int value) {
                  setState(() {
                    selectedEncoding = value;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Text(Const.outputEncodingList[0]),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Text(Const.outputEncodingList[1]),
                  ),
                ],
              )
            ],
          ),
          resizeToAvoidBottomInset: false,
          body: (_isLoading)
              ? const Center(child: Text('loading!'))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'Verbal Root', // Set the title text here
                          style: TextStyle(
                            fontSize: 20, // Set the font size

                            fontWeight: FontWeight.bold, // Set the font weight
                          ),
                        ),
                      ),
                    ),
                    displayVerbList.isNotEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.all(8),
                            height: MediaQuery.sizeOf(context).height * 0.6,
                            child: SearchableList<String>(
                              initialList: displayVerbList,
                              builder: (iniIndex, acIndex) {
                                final isSelected = iniIndex == selectedIndex;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: acIndex.isEven
                                        ? Colors.black12
                                        : Colors.white10,
                                    border:
                                        Border.all(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ListTile(
                                    title: Text(displayVerbList[iniIndex]),
                                    tileColor: isSelected ? Colors.blue : null,
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = isSelected
                                            ? -1
                                            : iniIndex; // Toggle selection
                                      });
                                    },
                                  ),
                                );
                              },
                              filter: (value) => displayVerbList
                                  .where(
                                    (element) =>
                                        element.toLowerCase().contains(value),
                                  )
                                  .toList(),
                              emptyWidget: const Text('No verbs'),
                              inputDecoration: InputDecoration(
                                labelText: "Search Verbs",
                                fillColor: Colors.white,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    // verbList.isNotEmpty
                    //     ? Container(
                    //         decoration: BoxDecoration(
                    //           border: Border.all(color: Colors.orangeAccent),
                    //           borderRadius: BorderRadius.circular(6),
                    //         ),
                    //         padding: const EdgeInsets.all(8),
                    //         height: 400,
                    //         child: Scrollbar(
                    //           thickness: 10,
                    //           thumbVisibility: true,
                    //           trackVisibility: true,
                    //           controller: controller,
                    //           child: ListView.builder(
                    //             controller: controller,
                    //             shrinkWrap: true,
                    //             physics: const ScrollPhysics(),
                    //             itemBuilder: (context, index) {
                    //               final isSelected = index == selectedIndex;
                    //               Map<String, dynamic> tmp = verbList[index];
                    //               return Container(
                    //                 decoration: BoxDecoration(
                    //                   color: index.isEven
                    //                       ? Colors.black12
                    //                       : Colors.white10,
                    //                   border:
                    //                       Border.all(color: Colors.transparent),
                    //                   borderRadius: BorderRadius.circular(6),
                    //                 ),
                    //                 child: ListTile(
                    //                   title: Text(tmp[
                    //                       Const.verbEncodingAbbreviation(
                    //                           Const.verbEncodingList[
                    //                               selectedEncoding])]),
                    //                   tileColor:
                    //                       isSelected ? Colors.blue : null, //
                    //                   onTap: () {
                    //                     setState(() {
                    //                       selectedIndex = isSelected
                    //                           ? -1
                    //                           : index; // Toggle selection
                    //                     });
                    //                   },
                    //                 ),
                    //               );
                    //             },
                    //             itemCount: verbList.length,
                    //           ),
                    //         ),
                    //       )
                    //     : Container(),
                    FilledButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => VerbGeneratorPage2(
                                        selectedVerb: verbList[selectedIndex]
                                            ['wx'],
                                      )));
                        },
                        child: const Text('Next')),
                  ],
                ),
        ),
        if (_isLoading)
          const Opacity(
            opacity: 0.2,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
