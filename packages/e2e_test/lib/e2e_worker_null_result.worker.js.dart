import 'dart:core';

import 'package:e2e_test/e2e_worker_null_result.dart';

class E2EWorkerNullResultImpl extends E2EWorkerNullResult {
  @override
  String get name => 'E2EWorkerNullResult';
  @override
  String get jsEntrypoint => 'main.dart.js';
}
