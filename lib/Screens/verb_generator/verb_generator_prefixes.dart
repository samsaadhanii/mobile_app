import 'package:flutter/material.dart';
import 'package:mobile_app/Screens/verb_generator/verb_generator_verbs.dart';
import 'package:provider/provider.dart';
import 'package:searchable_listview/searchable_listview.dart';
import '../../Constants/constants.dart';
import '../../model/data_provider.dart';

class VerbGeneratorPrefixes extends StatefulWidget {
  const VerbGeneratorPrefixes({super.key});

  @override
  State<VerbGeneratorPrefixes> createState() => _VerbGeneratorPrefixesState();
}

///************************************************************
/// Verb generator screen for Android devices - 1 (क्रियारूप-निष्पादिका)
/// Here we provide options for the user to select the prefix for verb
/// Which is the input screen for verb generation with one input field
/// And a submit button to send the request to the server
/// ************************************************************
class _VerbGeneratorPrefixesState extends State<VerbGeneratorPrefixes> {
  /// This variable is used to check if the data is loading or not.
  bool _isLoading = false;

  /// This variable is used to store the list of prefixes.
  List<Map<String, dynamic>> prefixList = [];

  /// This variable is used to store the selected prefix.
  String selectedPrefix = '';

  /// This variable is used to check if the prefix list is ready or not.
  bool prefixListReady = false;

  /// This variable is used to check if the prefix list is updated or not.
  bool updatePrefix = true;

  /// This variable is used to store the selected index.
  int selectedIndex = 0;

  ///   This variable is used to store the selected encoding.
  // int selectedEncoding = 0;

  /// This variable is used to store the scroll controller.
  final ScrollController controller = ScrollController();

  /// This variable is used to store the display prefix list.
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

  /// This function is used to build the widget for the VerbGeneratorPrefixes.
  /// This function returns a Scaffold widget.
  /// The Scaffold widget contains an AppBar and a body.
  /// The body contains a Column widget.
  /// The Column widget contains a Padding widget and a Container widget.
  /// The Padding widget contains a Center widget and a Text widget.
  /// The Container widget contains a Scrollbar widget and a ListView.builder widget.
  /// The ListView.builder widget contains a itemBuilder and itemCount.
  /// The itemBuilder contains a Container widget and a ListTile widget.
  /// The ListTile widget contains a title and a onTap.
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
            title: const Center(child: Text('Verb Generator')),

            /// This is the action button for the AppBar.
            /// This button is a PopupMenuButton widget.
            /// The PopupMenuButton widget contains an onSelected and itemBuilder.
            // actions: [
            //   PopupMenuButton<int>(
            //     onSelected: (int value) {
            //       setState(() {
            //         selectedEncoding = value;
            //       });
            //     },
            //     itemBuilder: (BuildContext context) => [
            //       PopupMenuItem(
            //         value: 0,
            //         child: Text(Const.verbEncodingList[0]),
            //       ),
            //       PopupMenuItem(
            //         value: 1,
            //         child: Text(Const.verbEncodingList[1]),
            //       ),
            //     ],
            //   )
            // ],
          ),
          resizeToAvoidBottomInset: false,
          body: (_isLoading)
              ? const Center(child: Text('loading!'))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ///
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
                                            ? -1
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
                                  builder: (context) => VerbGeneratorVerbs(
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
