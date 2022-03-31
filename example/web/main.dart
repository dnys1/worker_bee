import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:example/example.dart';
import 'package:worker_bee/worker_bee.dart';

part 'main.g.dart';

Future<String> computeBase64(String text) async {
  final worker = MyWorker.create();
  worker.logs.listen((log) {
    print('[${log.level}] (${log.workerName}) ${log.message}');
    if (log.error != null) {
      print(log.error);
    }
    if (log.stackTrace != null) {
      print(log.stackTrace);
    }
  });
  await worker.spawn();
  worker.sink.add(MyMessage(
    (b) => b..data = Uint8List.fromList(utf8.encode(text)),
  ));
  return Result.release(worker.result);
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
