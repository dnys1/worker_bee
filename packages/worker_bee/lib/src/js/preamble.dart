@JS()

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';

@JS()
external Object? get window;

/// Whether the current script is running inside a web worker.
bool get isWebWorker {
  return window == null;
}

/// Awaits assignment from the main process.
Future<String> getWorkerAssignment() async {
  final initCompleter = Completer<String>();
  late dynamic Function(Event) eventListener;
  WorkerGlobalScope.instance.addEventListener(
      'message',
      eventListener = (event) {
        WorkerGlobalScope.instance
            .removeEventListener('message', eventListener);
        initCompleter.complete((event as MessageEvent).data as String);
      });
  final initMessage = await initCompleter.future;
  print('(Worker) Got assignment: $initMessage');
  return initMessage;
}
