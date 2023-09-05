import 'package:flutter/material.dart';
import '../../web_api.dart';

class VerbGeneratorPage3 extends StatefulWidget {
  const VerbGeneratorPage3({
    super.key,
    required this.selectedVerb,
    required this.selectedPrefix,
  });

  final String selectedVerb;
  final String selectedPrefix;

  @override
  State<VerbGeneratorPage3> createState() => _VerbGeneratorPage3State();
}

class _VerbGeneratorPage3State extends State<VerbGeneratorPage3> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool fetchData = true;
  List<dynamic> output = [];

  @override
  void initState() {
    loadData();
    super.initState();
  }

  // @override
  // void didChangeDependencies() {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   // if (fetchData) {
  //   //   fetchData = false;
  //   //   WebAPI.verbRequest(
  //   //           input1: widget.selectedVerb,
  //   //           input2: 'karwari-uBayapaxI',
  //   //           input3: widget.selectedPrefix,
  //   //           inEncoding: 'WX',
  //   //           outEncoding: 'IAST')
  //   //       .then((value) {
  //   //     setState(() {
  //   //       _isLoading = false;
  //   //       output = value;
  //   //       print(output);
  //   //       // txt.text = value as String;
  //   //     });
  //   //   });
  //   //   // String find = '';
  //   //   // WebAPI.transLiterateWord(input: 'ub')
  //   // }
  //
  //   super.didChangeDependencies();
  // }

  void _onItemTapped(int index) {
    _selectedIndex = index;
    loadData();
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
        Scaffold(
          appBar: AppBar(title: const Text('Verb Generator')),
          body: SafeArea(child: buildTab(context)),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Active',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'Passive/Impersonal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Causative',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber[800],
            onTap: _onItemTapped,
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
    // return DefaultTabController(
    //   length: 3, // Specify the number of tabs
    //   child: Scaffold(
    //     appBar: AppBar(
    //       title: const Text('Verb Generator'),
    //       bottom: const TabBar(
    //         tabs: [
    //           Tab(text: 'Active'),
    //           Tab(text: 'Passive/Impersonal'),
    //           Tab(text: 'Causative'),
    //         ],
    //       ),
    //     ),
    //     body: const TabBarView(
    //       children: [
    //         Center(
    //           child: Text('Active Content'),
    //         ),
    //         Center(
    //           child: Text('Passive/Impersonal Content'),
    //         ),
    //         Center(
    //           child: Text('Causative Content'),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }

  Widget buildTab(BuildContext context) {
    Container con = Container();
    if (output.isNotEmpty) {
      List<dynamic> parasme = output[0]['parasmE'];
      List<dynamic> awmane = output[0]['Awmane'];
      con = Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(output[0]['rt']),

              ///Atmanepadi
              Column(
                children: [
                  Text(
                    awmane[0]['paxI'],
                    style: const TextStyle(fontSize: 20, color: Colors.green),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    awmane[0]['lakāra_0'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_0']),
                  Text(
                    awmane[0]['lakāra_1'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_1']),
                  Text(
                    awmane[0]['lakāra_2'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_2']),
                  Text(
                    awmane[0]['lakāra_3'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_3']),
                  Text(
                    awmane[0]['lakāra_4'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_4']),
                  Text(
                    awmane[0]['lakāra_5'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_5']),
                  Text(
                    awmane[0]['lakāra_6'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_6']),
                  Text(
                    awmane[0]['lakāra_7'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_7']),
                  Text(
                    awmane[0]['lakāra_8'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_8']),
                  Text(
                    awmane[0]['lakāra_9'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(awmane[0]['l_forms_9']),
                ],
              ),

              ///Parasmaipadi
              Column(
                children: [
                  Text(
                    parasme[0]['paxI'],
                    style: const TextStyle(fontSize: 20, color: Colors.green),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    parasme[0]['lakāra_0'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_0']),
                  Text(
                    parasme[0]['lakāra_1'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_1']),
                  Text(
                    parasme[0]['lakāra_2'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_2']),
                  Text(
                    parasme[0]['lakāra_3'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_3']),
                  Text(
                    parasme[0]['lakāra_4'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_4']),
                  Text(
                    parasme[0]['lakāra_5'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_5']),
                  Text(
                    parasme[0]['lakāra_6'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_6']),
                  Text(
                    parasme[0]['lakāra_7'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_7']),
                  Text(
                    parasme[0]['lakāra_8'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_8']),
                  Text(
                    parasme[0]['lakāra_9'],
                    style:
                        const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  buildFormTable(parasme[0]['l_forms_9']),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return con;
  }

  Widget buildFormTable(List<dynamic> data) {
    return Column(
      children: [
        const SizedBox(height: 2),
        Container(
          color: Colors.orange[50],
          child: DataTable(
            columnSpacing: 12,
            horizontalMargin: 12,
            // dataRowHeight: 24,
            // isVerticalScrollBarVisible: true,
            // dataRowColor: Colors.blue,
            columns: const [
              DataColumn(
                  label: Text('purusah', style: TextStyle(fontSize: 14))),
              DataColumn(
                  label: Text('ekavacanam', style: TextStyle(fontSize: 14))),
              DataColumn(
                  label: Text('dvivacanam', style: TextStyle(fontSize: 14))),
              DataColumn(
                  label: Text('bahuvacanam', style: TextStyle(fontSize: 14))),
            ],
            rows: [
              DataRow(
                cells: [
                  const DataCell(Text('prathama')),
                  DataCell(Center(child: Text(data[0]['form']))),
                  DataCell(Center(child: Text(data[1]['form']))),
                  DataCell(Center(child: Text(data[2]['form']))),
                ],
              ),
              DataRow(
                cells: [
                  const DataCell(Text('madhyama')),
                  DataCell(Center(child: Text(data[3]['form']))),
                  DataCell(Center(child: Text(data[4]['form']))),
                  DataCell(Center(child: Text(data[5]['form']))),
                ],
              ),
              DataRow(
                cells: [
                  const DataCell(Text('uttama')),
                  DataCell(Center(child: Text(data[6]['form']))),
                  DataCell(Center(child: Text(data[7]['form']))),
                  DataCell(Center(child: Text(data[8]['form']))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // DataRow buildRow(List<dynamic> data) {
  //   return DataRow(cells: [
  //     DataCell(Text(data[0]['person'])),
  //     DataCell(Text(data[0]['form'])),
  //     DataCell(Text(data[1]['form'])),
  //     DataCell(Text(data[2]['form'])),
  //   ]);
  // }
}
