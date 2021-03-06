import 'dart:core';

import 'package:e2e_test/e2e_worker.dart';

/// The JS implementation of [E2EWorker].
class E2EWorkerImpl extends E2EWorker {
  @override
  String get name => 'E2EWorker';
  @override
  String get jsEntrypoint => 'main.dart.js';
  @override
  List<String> get fallbackUrls => const [];
}
