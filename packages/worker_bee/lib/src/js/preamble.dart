@JS()

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';

import 'util.dart';

@JS()
external Object? get window;

/// Whether the current script is running inside a web worker.
bool get isWebWorker {
  return window == null;
}

/// Awaits assignment from the main process.
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
  print('(Worker) Got assignment: $workerAssignment');
  return workerAssignment;
}
