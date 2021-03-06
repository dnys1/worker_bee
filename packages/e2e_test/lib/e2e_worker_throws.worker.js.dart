import 'dart:core';

import 'package:e2e_test/e2e_worker_throws.dart';

/// The JS implementation of [E2EWorkerThrows].
class E2EWorkerThrowsImpl extends E2EWorkerThrows {
  @override
  String get name => 'E2EWorkerThrows';
  @override
  String get jsEntrypoint => 'main.dart.js';
  @override
  List<String> get fallbackUrls => const [];
}
