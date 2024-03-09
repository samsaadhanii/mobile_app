import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searchable_listview/searchable_listview.dart';
import '../../Constants/constants.dart';
import '../../model/data_provider.dart';
import 'krt_generator_verbs.dart';

class KrtGeneratorPrefix extends StatefulWidget {
  const KrtGeneratorPrefix({super.key});

  @override
  State<KrtGeneratorPrefix> createState() => _KrtGeneratorPrefixState();
}

class _KrtGeneratorPrefixState extends State<KrtGeneratorPrefix> {
  bool _isLoading = false;
  List<Map<String, dynamic>> prefixList = [];
  String selectedPrefix = '';
  bool prefixListReady = false;
  bool updatePrefix = true;
  int selectedIndex = 0;
  // int selectedEncoding = 0;
  final ScrollController controller = ScrollController();
  List<String> displayPrefixList = [];

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
    if (prefixList.isNotEmpty) {
      displayPrefixList.clear();
      for (var element in prefixList) {
        String tmp = element[Const.verbEncodingAbbreviation(inputEncodingStr)];
        displayPrefixList.add(tmp);
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
                          'Prefix List', // Set the title text here
                          style: TextStyle(
                            fontSize: 20, // Set the font size

                            fontWeight: FontWeight.bold, // Set the font weight
                          ),
                        ),
                      ),
                    ),
                    displayPrefixList.isNotEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orangeAccent),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.all(8),
                            height: MediaQuery.sizeOf(context).height * 0.6,
                            child: SearchableList<String>(
                              initialList: displayPrefixList,
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
                                    title: Text(displayPrefixList[index]),
                                    tileColor: isSelected ? Colors.blue : null,
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = isSelected
                                            ? 0
                                            : index; // Toggle selection
                                      });
                                    },
                                  ),
                                );
                              },
                              filter: (value) => displayPrefixList
                                  .where(
                                    (element) =>
                                        element.toLowerCase().contains(value),
                                  )
                                  .toList(),
                              emptyWidget: const Text('No Prefixes'),
                              inputDecoration: InputDecoration(
                                labelText: "Search Prefixes",
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
                    FilledButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => KrtGeneratorVerbs(
                                        selectedPrefix:
                                            prefixList[selectedIndex]['wx'],
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
