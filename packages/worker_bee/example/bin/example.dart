import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:example/example.dart';

void main(List<String> args) async {
  final textToEncode = args.firstOrNull;
  if (textToEncode == null) {
    usage();
  }

  final worker = MyWorker.create();
  await worker.start();
  worker.sink
      .add(MyMessage(data: Uint8List.fromList(utf8.encode(textToEncode))));
  final result = (await worker.stream.first).result!;
  print('(Main) Got result: $result');
}

Never usage() {
  stdout.writeln('Usage: dart example.dart <text to encode>');
  exit(1);
}
