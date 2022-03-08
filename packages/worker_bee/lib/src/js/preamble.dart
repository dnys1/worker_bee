@JS()

import 'dart:async';
import 'dart:html' hide window;

import 'package:js/js.dart';

import 'util.dart';

@JS('window')
external Object? get _window;

/// {@macro worker_bee.is_web_worker}
bool get isWebWorker {
  return _window == null;
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
  print('(Worker) Got assignment: $workerAssignment');
  return workerAssignment;
}
