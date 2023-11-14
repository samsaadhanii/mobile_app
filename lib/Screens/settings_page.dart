import 'package:flutter/material.dart';
import 'package:mobile_app/Constants/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saṃsādhanī Settings'),
      ),
      body: body(),
    );
  }

  Widget body() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Column(
            children: [
              SizedBox(height: 10),
              Text(
                'Select your preferred input and',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                ' output encoding',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: DropdownMenu(
                  label: const Text('Input encoding: ',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  initialSelection: inputEncodingStr,
                  dropdownMenuEntries: Const.inputEncodingList
                      .map((e) => DropdownMenuEntry(
                            value: e,
                            label: (e),
                          ))
                      .toList(),
                  onSelected: (value) {},
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: DropdownMenu(
                  label: const Text('Output encoding: ',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  initialSelection: outputEncodingStr,
                  dropdownMenuEntries: Const.outputEncodingList
                      .map((e) => DropdownMenuEntry(
                            value: e,
                            label: (e),
                          ))
                      .toList(),
                  onSelected: (value) {},
                ),
              ),
            ],
          ),
          const Column(
            children: [
              SizedBox(height: 10),
              Text('This will be used throughout this app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
