import 'dart:async';

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';
import 'package:worker_bee/src/js/interop/common.dart';
import 'package:worker_bee/src/serializers/serializers.dart';
import 'package:worker_bee/worker_bee.dart';

import 'custom_type.dart';

void main() {
  final serializers =
      (workerBeeSerializers.toBuilder()..add(CustomType.serializer)).build();

  void streamTest<T>(List<T> elements) {
    final stream = Stream.fromIterable(elements);
    final serialized = serializers.serialize(
      stream,
      specifiedType: const FullType(Stream),
    );
    final deserialized = serializers.deserialize(
      serialized,
      specifiedType: const FullType(Stream),
    );
    expect(deserialized, isA<Stream>());
    expect(deserialized, emitsInOrder(elements));
  }

  Future<void> streamPortTest<T extends Object>(List<T> elements) async {
    final stream = Stream.fromIterable(elements);
    final messageChannel = MessageChannel();
    final transfer = <Object>[];
    final serialized = runZoned(
      () => serializers.serialize(
        stream,
        specifiedType: const FullType(Stream),
      ),
      zoneValues: {
        #transfer: transfer,
      },
    );
    messageChannel.port1.postMessage(serialized, transfer);

    final List<CancelableOperation<void>> pendingOps = [];
    final message = await messageChannel.port2.onMessage.first;
    final deserialized = runZoned(
      () => serializers.deserialize(
        message.data,
        specifiedType: const FullType(Stream),
      ),
      zoneValues: {
        #addPendingOperation: pendingOps.add,
      },
    );
    await expectLater(
      deserialized,
      allOf([
        isA<Stream>(),
        emitsInOrder(<Object>[...elements, emitsDone]),
      ]),
    );
    expect(pendingOps, isNotEmpty);
    expect(
      Future.wait<void>(pendingOps.map((op) => op.valueOrCancellation())),
      completes,
    );
  }

  group('StreamSerializer', () {
    group('Stream<int>', () {
      const elements = [1, 2, 3, 4, 5];

      test('', () {
        streamTest(elements);
      });

      test('(channeled)', () {
        streamPortTest(elements);
      });
    });

    group('Stream<CustomType>', () {
      final elements = [
        CustomType((b) => b..customField = 'a'),
        CustomType((b) => b..customField = 'b'),
        CustomType((b) => b..customField = 'c'),
        CustomType((b) => b..customField = 'd'),
        CustomType((b) => b..customField = 'e'),
      ];

      test('', () {
        streamTest(elements);
      });

      test('(channeled)', () {
        streamPortTest(elements);
      });
    });
  });
}
