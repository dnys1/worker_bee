@JS()

import 'package:js/js.dart';

import 'example.dart';

@JS()
@anonymous
class MyMessageImpl implements MyMessage {
  external factory MyMessageImpl({
    required String message,
  });

  @override
  external String get message;
}
