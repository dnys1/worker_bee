@JS()

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';
import 'package:worker_bee/src/util.dart';

import 'util.dart';

@JS('window')
external WindowBase? get _window;

// Use staticInterop here because the `href` getter throws when using built-in
// dart2js getter.

@JS()
@staticInterop
class _JsWorkerLocation {}

extension on _JsWorkerLocation {
  external String get href;
}

/// {@macro worker_bee.is_web_worker}
bool get isWebWorker {
  return _window == null;
}

/// {@macro worker_bee.current_uri}
Uri get currentUri {
  return (isWebWorker
          ? Uri.tryParse((self.location as _JsWorkerLocation).href)
          : Uri.tryParse(window.location.href)) ??
      Uri();
}

/// {@macro worker_bee.get_worker_assignment}
Future<String> getWorkerAssignment() async {
  final initCompleter = Completer<String>.sync();
  late dynamic Function(Event) eventListener;
  self.addEventListener(
    'message',
    eventListener = (Event event) {
      event as MessageEvent;
      self.removeEventListener('message', eventListener);
      final Object? assignment = event.data;
      if (assignment is! String) {
        initCompleter.completeError(StateError(
          'Invalid worker assignment: ${JSON.stringify(assignment)}',
        ));
      } else {
        initCompleter.complete(assignment);
      }
    },
  );
  final workerAssignment = await initCompleter.future;
  safePrint('(Worker) Got assignment: $workerAssignment');
  return workerAssignment;
}
