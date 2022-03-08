@JS()

import 'dart:html';

import 'package:js/js.dart';

/// The context-independent global scope.
final self = DedicatedWorkerGlobalScope.instance;

/// Browser-based JSON utilities.
@JS()
class JSON {
  /// Stringifies a JSON-like object.
  external static String stringify(Object? object);
}
