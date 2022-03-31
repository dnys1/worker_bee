import 'dart:io';

import 'package:tuple/tuple.dart';
import 'package:worker_bee/worker_bee.dart';

/// {@template worker_bee.is_web_worker}
/// Whether the current script is running inside a web worker.
///
/// Always returns `false` on VM.
/// {@endtemplate}
bool get isWebWorker => false;

/// {@template worker_bee.current_uri}
/// The current URI of the running worker.
/// {@endtemplate}
Uri get currentUri => Platform.script;

/// {@template worker_bee.get_worker_assignment}
/// Awaits assignment from the main process.
///
/// Should not be called on VM.
/// {@endtemplate}
Future<Tuple2<String, StreamChannel<LogMessage>>> getWorkerAssignment() async {
  throw UnimplementedError('Should not be called on VM');
}
