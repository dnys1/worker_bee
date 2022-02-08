import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:worker_bee/worker_bee.dart';
import 'package:example/example.dart';

part 'main.g.dart';

// in .g.dart
final workers = <String, Future<void> Function()>{
  'MyWorker': MyWorker.create().connect,
};

Future<String> computeBase64(String text) async {
  final worker = MyWorker.create();
  await worker.spawn();
  worker.sink.add(MyMessage(
    data: Uint8List.fromList(utf8.encode(text)),
  ));
  return worker.result;
}

@WorkerHive([
  MyWorker,
])
void main() {
  runHive(workers, () {
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
