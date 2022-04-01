import 'dart:core';

import 'package:e2e_test/e2e_worker_void_result.dart';

class E2EWorkerVoidResultImpl extends E2EWorkerVoidResult {
  @override
  String get name => 'E2EWorkerVoidResult';
  @override
  String get jsEntrypoint => 'main.dart.js';
}
