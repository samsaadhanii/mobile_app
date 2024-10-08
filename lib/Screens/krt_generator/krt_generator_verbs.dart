import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searchable_listview/searchable_listview.dart';
import '../../Constants/constants.dart';
import '../../model/data_provider.dart';
import 'krt_generator_output.dart';

class KrtGeneratorVerbs extends StatefulWidget {
  const KrtGeneratorVerbs({super.key, required this.selectedPrefix});

  final String selectedPrefix;

  @override
  State<KrtGeneratorVerbs> createState() => _KrtGeneratorVerbsState();
}

/// ************************************************************
/// This is the Android version of the Krt Generator Verbs screen.
/// It is called from KrtGeneratorPrefix.
/// It displays the list of verbs for the selected prefix.
/// The user selects a verb from the list.
/// The selected verb is passed to KrtGeneratorOutput.
/// ************************************************************
class _KrtGeneratorVerbsState extends State<KrtGeneratorVerbs> {
  bool _isLoading = false;
  List<Map<String, dynamic>> verbList = [];
  String selectedVerb = '';
  bool verbListReady = false;
  bool updateData = true;
  int selectedIndex = 0;
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
    print('selectedEncoding: ${inputEncodingStr}');
    if (verbList.isNotEmpty) {
      displayVerbList.clear();
      for (var element in verbList) {
        displayVerbList
            .add(element[Const.verbEncodingAbbreviation(inputEncodingStr)]);
      }
    }
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Center(
                child: Text('Krt Generator (कृदन्तरूपनिष्पादिका)')),
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
                              builder: (list, index, item) {
                                final isSelected = index == selectedIndex;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: index.isEven
                                        ? Colors.black12
                                        : Colors.white10,
                                    border:
                                        Border.all(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ListTile(
                                    title: Text(displayVerbList[index]),
                                    tileColor: isSelected ? Colors.blue : null,
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = isSelected
                                            ? -1
                                            : index; // Toggle selection
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
                                  builder: (context) => KrtGeneratorOutput(
                                        selectedPrefix: widget.selectedPrefix,
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
