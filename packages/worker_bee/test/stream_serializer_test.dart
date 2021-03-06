import 'dart:async';

import 'package:built_value/serializer.dart';
import 'package:test/test.dart';
import 'package:worker_bee/src/serializers/serializers.dart';

import 'custom_type.dart';

void main() {
  final serializers =
      (workerBeeSerializers.toBuilder()..add(CustomType.serializer)).build();

  void serializerTest<T>(List<T> elements) {
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

  group('StreamSerializer', () {
    test('Stream<int>', () {
      const elements = [1, 2, 3, 4, 5];
      serializerTest(elements);
    });

    test('Stream<CustomType>', () {
      final elements = [
        CustomType((b) => b..customField = 'a'),
        CustomType((b) => b..customField = 'b'),
        CustomType((b) => b..customField = 'c'),
        CustomType((b) => b..customField = 'd'),
        CustomType((b) => b..customField = 'e'),
      ];
      serializerTest(elements);
    });
  });
}
