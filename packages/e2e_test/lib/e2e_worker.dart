import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:fixnum/fixnum.dart';
import 'package:worker_bee/worker_bee.dart';
import 'e2e_worker.worker.dart';

part 'e2e_worker.g.dart';

abstract class E2EMessage implements Built<E2EMessage, E2EMessageBuilder> {
  factory E2EMessage([void Function(E2EMessageBuilder) updates]) = _$E2EMessage;
  E2EMessage._();

  BigInt get bigInt;
  bool get bool_;
  BuiltList<String> get builtList;
  BuiltListMultimap<String, String> get builtListMultimap;
  BuiltMap<String, String> get builtMap;
  BuiltSet<String> get builtSet;
  BuiltSetMultimap<String, String> get builtSetMultimap;
  DateTime get dateTime;
  double get double_;
  Duration get duration;
  int get int_;
  Int64 get int64;
  JsonObject get jsonObject;
  num get num_;
  RegExp get regExp;
  String get string;
  Uri get uri;

  static Serializer<E2EMessage> get serializer => _$e2EMessageSerializer;
}

abstract class E2EResult implements Built<E2EResult, E2EResultBuilder> {
  factory E2EResult([void Function(E2EResultBuilder) updates]) = _$E2EResult;
  E2EResult._();

  E2EMessage get message;

  static Serializer<E2EResult> get serializer => _$e2EResultSerializer;
}

@SerializersFor([
  E2EMessage,
  E2EResult,
])
final Serializers serializers = _$serializers;

E2EMessage get message => E2EMessage(
      (b) => b
        ..bigInt = BigInt.from(123)
        ..bool_ = true
        ..builtList.add('abc')
        ..builtListMultimap.addValues('a', ['1', '2', '3'])
        ..builtMap.addAll({'a': '1', 'b': '2', 'c': '3'})
        ..builtSet.add('abc')
        ..builtSetMultimap.addValues('a', ['1', '2', '3'])
        ..dateTime = DateTime.utc(1990, 1, 1)
        ..double_ = 123.0
        ..duration = Duration(minutes: 4)
        ..int_ = 123
        ..int64 = Int64(123)
        ..jsonObject = JsonObject(123)
        ..num_ = 123
        ..regExp = RegExp(r'^\w{3}$')
        ..string = 'abc'
        ..uri = Uri.parse('https://example.com'),
    );

@WorkerBee()
abstract class E2EWorker extends WorkerBeeBase<E2EMessage, E2EResult> {
  E2EWorker() : super(serializers: serializers);
  factory E2EWorker.create() = E2EWorkerImpl;

  @override
  Future<E2EResult?> run(
    Stream<E2EMessage> listen,
    StreamSink<E2EResult> respond,
  ) async {
    // Reflect a received message
    final event = await listen.first;
    final result = E2EResult((b) => b.message.replace(event));
    respond.add(result);

    // Complete with no result
    return null;
  }
}
