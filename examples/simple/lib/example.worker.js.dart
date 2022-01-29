import 'dart:core';
import 'dart:typed_data';

import 'package:example/example.dart';
import 'package:js/js.dart';

@JS()
@anonymous
class MyMessageImpl implements MyMessage {
  external factory MyMessageImpl({required Uint8List data});

  external factory MyMessageImpl._done({required String result});

  @override
  external Uint8List get data;
  @override
  external String? get result;
}
