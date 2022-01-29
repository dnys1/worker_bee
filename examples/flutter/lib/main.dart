import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_example/example.dart' as example_worker;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _inputController = TextEditingController();
  String _output = '';

  Future<String> computeBase64(String text) async {
    final worker = example_worker.MyWorker.create();
    await worker.spawn();
    worker.sink.add(
        example_worker.MyMessage(data: Uint8List.fromList(utf8.encode(text))));
    return (await worker.stream.first).result!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Calculate Base64'),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: TextField(
                      controller: _inputController,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final value = _inputController.text;
                      if (value.isEmpty) {
                        return;
                      }
                      final result = await computeBase64(value);
                      setState(() {
                        _output = result;
                      });
                    },
                    child: const Text('Go'),
                  ),
                ],
              ),
            ),
            Text('Output: $_output'),
          ],
        ),
      ),
    );
  }
}
