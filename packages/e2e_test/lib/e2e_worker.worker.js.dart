import 'dart:core';

import 'package:e2e_test/e2e_worker.dart';

class E2EWorkerImpl extends E2EWorker {
  @override
  String get name => 'E2EWorker';
  @override
  String get jsEntrypoint => 'main.dart.js';
}
