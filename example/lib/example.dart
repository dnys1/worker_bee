import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:example/serializers.dart';
import 'package:worker_bee/worker_bee.dart';
import 'example.worker.dart';

part 'example.g.dart';

abstract class MyMessage implements Built<MyMessage, MyMessageBuilder> {
  factory MyMessage([void Function(MyMessageBuilder) updates]) = _$MyMessage;
  MyMessage._();

  Uint8List get data;

  static Serializer<MyMessage> get serializer => _$myMessageSerializer;
}

@WorkerBee('main.dart.js')
abstract class MyWorker extends WorkerBeeBase<MyMessage, String> {
  MyWorker() : super(serializers);
  factory MyWorker.create() = MyWorkerImpl;

  @override
  Future<String> run(
    Stream<MyMessage> listen,
    StreamSink<MyMessage> respond,
  ) async {
    final messageToEncode = await listen.first;
    return base64Encode(messageToEncode.data);
  }
}
