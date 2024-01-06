import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Constants/constants.dart';
import '../../web_api.dart';

class CupertinoKrtGeneratorOutput extends StatefulWidget {
  const CupertinoKrtGeneratorOutput({
    super.key,
    required this.selectedVerb,
    required this.selectedPrefix,
  });

  final String selectedVerb;
  final String selectedPrefix;

  @override
  State<CupertinoKrtGeneratorOutput> createState() =>
      _CupertinoKrtGeneratorOutputState();
}

class _CupertinoKrtGeneratorOutputState
    extends State<CupertinoKrtGeneratorOutput> {
  bool _isLoading = false;
  bool fetchData = true;
  List<dynamic> output = [];
  List<Column> cList = [];
  Map<String, Map<String, List<String>>> tableData = {};

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void loadData() {
    setState(() {
      _isLoading = true;
    });
    WebAPI.krtRequest(
            input1: widget.selectedVerb,
            input3: widget.selectedPrefix,
            inEncoding: 'WX',
            outEncoding:
                Const.verbAPIOutEncodingAbbreviation(outputEncodingStr))
        .then((value) {
      setState(() {
        output = value;
        if (output.isNotEmpty) {
          /// creating a map of map of list
          /// key: kqw_prawyayaH
          /// value: map of form and lifgam
          /// value of 'form' map: list of form values
          /// value of 'lifgam' map: list of lifgam values
          for (var element in output) {
            String key = element['kqw_prawyayaH'];
            String lifgamValue = element['lifgam'] ?? '';
            String formValue = element['form'] ?? '';
            if (tableData[key] == null) {
              tableData[key] = {'form': [], 'lifgam': []};
            }
            tableData[key]!['form']?.add(formValue);
            tableData[key]!['lifgam']?.add(lifgamValue);
          }

          /// this is for debugging purpose only
          /// to print the map
          print(tableData.length);
          tableData.forEach((key, value) {
            print('Key: $key, values: $value');
          });

          if (tableData.isNotEmpty) {
            tableData.forEach((key, value) {
              List<String> lifgamList = value['lifgam'] ?? [];
              List<String> formList = value['form'] ?? [];
              cList.add(Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red[300],
                    ),
                    child: Text(
                      key,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue[100],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(width: 100, child: Text(lifgamList[0])),
                            Text(formList[0]),
                          ],
                        ),
                        if (lifgamList.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(width: 100, child: Text(lifgamList[1])),
                              Text(formList[1]),
                            ],
                          ),
                        if (lifgamList.length > 2)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(width: 100, child: Text(lifgamList[2])),
                              Text(formList[2]),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 2, color: Colors.white)
                ],
              ));
            });
          }
        }
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Stack(
        children: [
          const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Krt Generator (कृदन्तरूपनिष्पादिका)'),
            ),
            child: Center(child: Text('Loading...')),
          ),
          if (_isLoading)
            const Opacity(
              opacity: 0.2,
              child: ModalBarrier(
                  dismissible: false, color: CupertinoColors.black),
            ),
          if (_isLoading)
            const Center(
              child: CupertinoActivityIndicator(
                  radius: 20.0, color: CupertinoColors.activeBlue),
            ),
        ],
      );
    } else {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Krt Generator'),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: CupertinoListSection.insetGrouped(
              dividerMargin: 1,
              children: cList,
            ),
          ),
        ),
      );
    }
  }
}
