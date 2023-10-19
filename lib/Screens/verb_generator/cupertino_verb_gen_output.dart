import 'package:flutter/cupertino.dart';
import 'package:mobile_app/Constants/constants.dart';
import '../../web_api.dart';

class CupertinoVerbGeneratorOutput extends StatefulWidget {
  const CupertinoVerbGeneratorOutput({
    super.key,
    required this.selectedVerb,
    required this.selectedPrefix,
  });

  final String selectedVerb;
  final String selectedPrefix;

  @override
  State<CupertinoVerbGeneratorOutput> createState() =>
      _CupertinoVerbGeneratorOutputState();
}

class _CupertinoVerbGeneratorOutputState
    extends State<CupertinoVerbGeneratorOutput> {
  bool _isLoading = false;
  bool fetchData = true;
  List<dynamic> output = [];
  String _selectedPadi = Const.ATMANEPADI;

  // final ScrollController controller = ScrollController();

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void loadData() {
    setState(() {
      _isLoading = true;
    });
    WebAPI.verbRequest(
            input1: widget.selectedVerb,
            input2: 'karwari-uBayapaxI',
            input3: widget.selectedPrefix,
            inEncoding: 'WX',
            outEncoding: 'IAST')
        .then((value) {
      setState(() {
        _isLoading = false;
        output = value;
        // print(output);
        // print(output.length);
        // txt.text = value as String;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CupertinoPageScaffold(
          // backgroundColor: CupertinoColors.lightBackgroundGray,
          navigationBar: CupertinoNavigationBar(
            // middle: Text('Verb Generator'),
            middle: CupertinoSegmentedControl<String>(
              selectedColor: CupertinoColors.activeBlue,
              // Provide horizontal padding around the children.
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // This represents a currently selected segmented control.
              groupValue: _selectedPadi,
              // Callback that sets the selected segmented control.
              onValueChanged: (String value) {
                setState(() {
                  _selectedPadi = value;
                });
              },
              children: const <String, Widget>{
                Const.ATMANEPADI: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(Const.ATMANEPADI),
                ),
                Const.PARASMAIPADI: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(Const.PARASMAIPADI),
                ),
              },
            ),
          ),
          child: _selectedPadi.contains(Const.ATMANEPADI)
              ? buildAtmanepadi(context)
              : buildParasmaipadi(context),
          // child: buildTab(context),
          // body: SafeArea(child: buildTab(context)),
          // bottomNavigationBar: BottomNavigationBar(
          //   items: const <BottomNavigationBarItem>[
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.home),
          //       label: 'Active',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.business),
          //       label: 'Passive/Impersonal',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.school),
          //       label: 'Causative',
          //     ),
          //   ],
          //   currentIndex: _selectedIndex,
          //   selectedItemColor: Colors.amber[800],
          //   onTap: _onItemTapped,
          // ),
        ),
        if (_isLoading)
          const Opacity(
            opacity: 0.2,
            child:
                ModalBarrier(dismissible: false, color: CupertinoColors.black),
          ),
        if (_isLoading)
          const Center(
            child: CupertinoActivityIndicator(
                radius: 20.0, color: CupertinoColors.activeBlue),
          ),
      ],
    );
  }

  Widget buildAtmanepadi(BuildContext context) {
    if (output.isNotEmpty) {
      List<dynamic> awmane = output[0]['Awmane'];
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(output[0]['rt']),
              const SizedBox(height: 10),

              ///Atmanepadi
              cText(awmane[0]['paxI']),
              const SizedBox(height: 14),
              cText(awmane[0]['lakāra_0']),
              buildFormTable(awmane[0]['l_forms_0']),
              cText(awmane[0]['lakāra_1']),
              buildFormTable(awmane[0]['l_forms_1']),
              cText(awmane[0]['lakāra_2']),
              buildFormTable(awmane[0]['l_forms_2']),
              cText(awmane[0]['lakāra_3']),
              buildFormTable(awmane[0]['l_forms_3']),
              cText(awmane[0]['lakāra_4']),
              buildFormTable(awmane[0]['l_forms_4']),
              cText(awmane[0]['lakāra_5']),
              buildFormTable(awmane[0]['l_forms_5']),
              cText(awmane[0]['lakāra_6']),
              buildFormTable(awmane[0]['l_forms_6']),
              cText(awmane[0]['lakāra_7']),
              buildFormTable(awmane[0]['l_forms_7']),
              cText(awmane[0]['lakāra_8']),
              buildFormTable(awmane[0]['l_forms_8']),
              cText(awmane[0]['lakāra_9']),
              buildFormTable(awmane[0]['l_forms_9']),
            ],
          ),
        ),
      );
    }
    return const Center(child: Text('There are no data'));
  }

  Widget buildParasmaipadi(BuildContext context) {
    if (output.isNotEmpty) {
      List<dynamic> parasme = output[0]['parasmE'];
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(output[0]['rt']),
              const SizedBox(height: 10),

              ///Parasmaipadi
              cText(parasme[0]['paxI']),
              const SizedBox(height: 14),
              cText(parasme[0]['lakāra_0']),
              buildFormTable(parasme[0]['l_forms_0']),
              cText(parasme[0]['lakāra_1']),
              buildFormTable(parasme[0]['l_forms_1']),
              cText(parasme[0]['lakāra_2']),
              buildFormTable(parasme[0]['l_forms_2']),
              cText(parasme[0]['lakāra_3']),
              buildFormTable(parasme[0]['l_forms_3']),
              cText(parasme[0]['lakāra_4']),
              buildFormTable(parasme[0]['l_forms_4']),
              cText(parasme[0]['lakāra_5']),
              buildFormTable(parasme[0]['l_forms_5']),
              cText(parasme[0]['lakāra_6']),
              buildFormTable(parasme[0]['l_forms_6']),
              cText(parasme[0]['lakāra_7']),
              buildFormTable(parasme[0]['l_forms_7']),
              cText(parasme[0]['lakāra_8']),
              buildFormTable(parasme[0]['l_forms_8']),
              cText(parasme[0]['lakāra_9']),
              buildFormTable(parasme[0]['l_forms_9']),
            ],
          ),
        ),
      );
    }
    return const Center(child: Text('There are no data'));
  }

  // Widget buildTab(BuildContext context) {
  //   Container con = Container();
  //   if (output.isNotEmpty) {
  //     List<dynamic> parasme = output[0]['parasmE'];
  //     List<dynamic> awmane = output[0]['Awmane'];
  //     con = Container(
  //       width: MediaQuery.sizeOf(context).width,
  //       height: MediaQuery.sizeOf(context).height * 0.8,
  //       child: CupertinoScrollbar(
  //         child: Column(
  //           children: [
  //             const SizedBox(height: 10),
  //             Text(output[0]['rt']),
  //
  //             ///Atmanepadi
  //             Column(
  //               children: [
  //                 cText(awmane[0]['paxI']),
  //                 const SizedBox(height: 14),
  //                 cText(awmane[0]['lakāra_0']),
  //                 buildFormTable(awmane[0]['l_forms_0']),
  //                 cText(awmane[0]['lakāra_1']),
  //                 buildFormTable(awmane[0]['l_forms_1']),
  //                 cText(awmane[0]['lakāra_2']),
  //                 buildFormTable(awmane[0]['l_forms_2']),
  //                 cText(awmane[0]['lakāra_3']),
  //                 buildFormTable(awmane[0]['l_forms_3']),
  //                 cText(awmane[0]['lakāra_4']),
  //                 buildFormTable(awmane[0]['l_forms_4']),
  //                 cText(awmane[0]['lakāra_5']),
  //                 buildFormTable(awmane[0]['l_forms_5']),
  //                 cText(awmane[0]['lakāra_6']),
  //                 buildFormTable(awmane[0]['l_forms_6']),
  //                 cText(awmane[0]['lakāra_7']),
  //                 buildFormTable(awmane[0]['l_forms_7']),
  //                 cText(awmane[0]['lakāra_8']),
  //                 buildFormTable(awmane[0]['l_forms_8']),
  //                 cText(awmane[0]['lakāra_9']),
  //                 buildFormTable(awmane[0]['l_forms_9']),
  //               ],
  //             ),
  //
  //             ///Parasmaipadi
  //             Column(
  //               children: [
  //                 cText(parasme[0]['paxI']),
  //                 const SizedBox(height: 14),
  //                 cText(parasme[0]['lakāra_0']),
  //                 buildFormTable(parasme[0]['l_forms_0']),
  //                 cText(parasme[0]['lakāra_1']),
  //                 buildFormTable(parasme[0]['l_forms_1']),
  //                 cText(parasme[0]['lakāra_2']),
  //                 buildFormTable(parasme[0]['l_forms_2']),
  //                 cText(parasme[0]['lakāra_3']),
  //                 buildFormTable(parasme[0]['l_forms_3']),
  //                 cText(parasme[0]['lakāra_4']),
  //                 buildFormTable(parasme[0]['l_forms_4']),
  //                 cText(parasme[0]['lakāra_5']),
  //                 buildFormTable(parasme[0]['l_forms_5']),
  //                 cText(parasme[0]['lakāra_6']),
  //                 buildFormTable(parasme[0]['l_forms_6']),
  //                 cText(parasme[0]['lakāra_7']),
  //                 buildFormTable(parasme[0]['l_forms_7']),
  //                 cText(parasme[0]['lakāra_8']),
  //                 buildFormTable(parasme[0]['l_forms_8']),
  //                 cText(parasme[0]['lakāra_9']),
  //                 buildFormTable(parasme[0]['l_forms_9']),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //   return con;
  // }

  Widget cText(String txt) {
    return Text(
      txt,
      style: const TextStyle(
        fontSize: 16,
        color: CupertinoColors.destructiveRed,
      ),
    );
  }

  Widget buildFormTable(List<dynamic> data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Container(
        color: _selectedPadi.contains(Const.ATMANEPADI)
            ? CupertinoColors.systemYellow
            : CupertinoColors.systemOrange,
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('purusah', style: TextStyle(fontSize: 14)),
                Text('ekavacanam', style: TextStyle(fontSize: 14)),
                Text('dvivacanam', style: TextStyle(fontSize: 14)),
                Text('bahuvacanam', style: TextStyle(fontSize: 14)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('prathama'),
                Text(data[0]['form']),
                Text(data[1]['form']),
                Text(data[2]['form']),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('madhyama'),
                Text(data[3]['form']),
                Text(data[4]['form']),
                Text(data[5]['form']),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('uttama'),
                Text(data[6]['form']),
                Text(data[7]['form']),
                Text(data[8]['form']),
              ],
            ),
          ],
        ),
        // DataTable(
        //   columnSpacing: 12,
        //   horizontalMargin: 12,
        //   // dataRowHeight: 24,
        //   // isVerticalScrollBarVisible: true,
        //   // dataRowColor: Colors.blue,
        //   columns: const [
        //     DataColumn(
        //         label: Text('purusah', style: TextStyle(fontSize: 14))),
        //     DataColumn(
        //         label: Text('ekavacanam', style: TextStyle(fontSize: 14))),
        //     DataColumn(
        //         label: Text('dvivacanam', style: TextStyle(fontSize: 14))),
        //     DataColumn(
        //         label: Text('bahuvacanam', style: TextStyle(fontSize: 14))),
        //   ],
        //   rows: [
        //     DataRow(
        //       cells: [
        //         const DataCell(Text('prathama')),
        //         DataCell(Center(child: Text(data[0]['form']))),
        //         DataCell(Center(child: Text(data[1]['form']))),
        //         DataCell(Center(child: Text(data[2]['form']))),
        //       ],
        //     ),
        //     DataRow(
        //       cells: [
        //         const DataCell(Text('madhyama')),
        //         DataCell(Center(child: Text(data[3]['form']))),
        //         DataCell(Center(child: Text(data[4]['form']))),
        //         DataCell(Center(child: Text(data[5]['form']))),
        //       ],
        //     ),
        //     DataRow(
        //       cells: [
        //         const DataCell(Text('uttama')),
        //         DataCell(Center(child: Text(data[6]['form']))),
        //         DataCell(Center(child: Text(data[7]['form']))),
        //         DataCell(Center(child: Text(data[8]['form']))),
        //       ],
        //     ),
        //   ],
        // ),
      ),
    );
  }
}