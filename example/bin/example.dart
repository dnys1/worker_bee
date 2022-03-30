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
    await worker.spawn();
    worker.sink.add(
      MyMessage((b) => b..data = Uint8List.fromList(utf8.encode(textToEncode))),
    );
    final result = await Result.release(worker.result);
    print('(Main) Got result: $result');
    exit(0);
  });
}

Never usage() {
  stdout.writeln('Usage: dart example.dart <text to encode>');
  exit(1);
}
