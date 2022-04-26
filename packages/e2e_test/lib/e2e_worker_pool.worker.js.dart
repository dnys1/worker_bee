import 'dart:core';

import 'package:e2e_test/e2e_worker.dart';
import 'package:e2e_test/e2e_worker_pool.dart';

/// The JS implementation of [E2EWorkerPool].
class E2EWorkerPoolImpl extends E2EWorkerPool {
  @override
  String get name => 'E2EWorkerPool';
  @override
  String get jsEntrypoint => 'main.dart.js';
  @override
  E2EWorker Function() get factory => E2EWorker.create;
}
