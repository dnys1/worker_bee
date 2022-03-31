@JS()

import 'dart:async';
import 'dart:html';

import 'package:collection/collection.dart';
import 'package:js/js.dart';
import 'package:worker_bee/src/serializers.dart';
import 'package:worker_bee/worker_bee.dart';

import 'message_port_channel.dart';
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
Future<WorkerAssignment> getWorkerAssignment() async {
  final assignmentCompleter = Completer<WorkerAssignment>.sync();
  late dynamic Function(Event) eventListener;
  self.addEventListener(
    'message',
    eventListener = (Event event) {
      event as MessageEvent;
      final Object? message = event.data;
      final MessagePort? messagePort = event.ports.firstOrNull;
      if (message is String && messagePort is MessagePort) {
        self.removeEventListener('message', eventListener);
        assignmentCompleter.complete(WorkerAssignment(
          message,
          MessagePortChannel<LogMessage>(messagePort),
        ));
      } else {
        assignmentCompleter.completeError(StateError(
          'Invalid worker assignment: '
          '${workerBeeSerializers.serialize(message)}',
        ));
      }
    },
  );
  return assignmentCompleter.future;
}
