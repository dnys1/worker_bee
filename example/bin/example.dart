import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:worker_bee/worker_bee.dart';
import 'package:example/example.dart';

part 'example.g.dart';

@WorkerHive([
  MyWorker,
])
void main(List<String> args) async {
  await runHive(workers, () async {
    final textToEncode = args.firstOrNull;
    if (textToEncode == null) {
      usage();
    }

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
    worker.sink.add(utf8.encode(textToEncode) as Uint8List);
    final result = await worker.stream.first;
    print('Got result: $result');
    exit(0);
  });
}

Never usage() {
  stdout.writeln('Usage: dart example.dart <text to encode>');
  exit(1);
}
