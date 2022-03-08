@TestOn('browser')

import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('E2E', () {
    test(
      'dart2Js',
      () => testWorker(
        jsEntrypoint: 'packages/e2e_test/workers.js',
      ),
    );

    test(
      'dart2Js (m, O4)',
      () => testWorker(
        jsEntrypoint: 'packages/e2e_test/workers.min.js',
      ),
    );
  });
}
