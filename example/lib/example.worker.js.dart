import 'dart:core';

import 'package:example/example.dart';

class MyWorkerImpl extends MyWorker {
  @override
  String get name => 'MyWorker';
  @override
  String get jsEntrypoint => 'main.dart.js';
}