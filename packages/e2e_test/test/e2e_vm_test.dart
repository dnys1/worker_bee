@TestOn('vm')

import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('E2E', () {
    test('VM', () => testWorker());
  });
}
