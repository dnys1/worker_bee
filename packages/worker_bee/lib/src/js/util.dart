@JS()

import 'dart:html';

import 'package:js/js.dart';

final self = WorkerGlobalScope.instance;

@JS()
class JSON {
  external static String stringify(Object? object);
}
