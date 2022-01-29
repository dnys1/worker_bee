import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:worker_bee/worker_bee.dart';
import 'package:example/example.dart' deferred as example_worker;

// in .g.dart
final workers = <String, Future<void> Function()>{
  'example': () async {
    await example_worker.loadLibrary();
    await example_worker.MyWorker.create().connect();
  }
};

void main(List<String> args) async {
  await runHive(workers, () async {
    final textToEncode = args.firstOrNull;
    if (textToEncode == null) {
      usage();
    }

    await example_worker.loadLibrary();
    final worker = example_worker.MyWorker.create();
    await worker.spawn();
    worker.sink.add(example_worker.MyMessage(
        data: Uint8List.fromList(utf8.encode(textToEncode))));
    final result = (await worker.stream.first).result!;
    print('(Main) Got result: $result');
  });
}

Never usage() {
  stdout.writeln('Usage: dart example.dart <text to encode>');
  exit(1);
}
