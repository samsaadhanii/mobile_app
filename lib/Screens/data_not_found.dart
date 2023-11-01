import 'package:flutter/material.dart';

class DataNotFound extends StatefulWidget {
  const DataNotFound({Key? key}) : super(key: key);

  @override
  State<DataNotFound> createState() => _DataNotFoundState();
}

class _DataNotFoundState extends State<DataNotFound> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data not found'),
      ),
      body: const Center(
        child: FittedBox(
          child: Column(
            children: [
              Icon(
                Icons.close,
                color: Colors.redAccent,
                size: 50.0,
              ),
              Text('Data not found!'),
            ],
          ),
        ),
      ),
    );
  }
}
