import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:worker_bee/worker_bee.dart';
import 'package:example/example.dart' deferred as example_worker;

// in .g.dart
final workers = <String, Future<void> Function()>{
  'example': () async {
    await example_worker.loadLibrary();
    await example_worker.MyWorker.create().connect();
  }
};

Future<String> computeBase64(String text) async {
  await example_worker.loadLibrary();
  final worker = example_worker.MyWorker.create();
  await worker.start();
  worker.sink.add(
      example_worker.MyMessage(data: Uint8List.fromList(utf8.encode(text))));
  return (await worker.stream.first).result!;
}

void main() {
  runHive(workers, () async {
    final submitBtn =
        document.getElementById('submit') as SubmitButtonInputElement;
    final inputEl = document.getElementById('encodeText') as TextInputElement;
    final outputEl = document.getElementById('out') as SpanElement;
    submitBtn.onClick.listen((event) {
      event.preventDefault();
      final text = inputEl.value;
      if (text == null || text.isEmpty) {
        return;
      }
      computeBase64(text).then((result) {
        outputEl.innerText = result;
      });
    });
  });
}
