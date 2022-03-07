import 'dart:typed_data';

import 'package:built_value/serializer.dart';
import 'package:example/example.dart';

part 'serializers.g.dart';

@SerializersFor([
  MyMessage,
])
final Serializers serializers =
    (_$serializers.toBuilder()..add(const BlobSerializer())).build();

class BlobSerializer implements PrimitiveSerializer<Uint8List> {
  const BlobSerializer();

  @override
  Uint8List deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return Uint8List.fromList((serialized as List).cast<int>());
  }

  @override
  Object serialize(Serializers serializers, Uint8List object,
      {FullType specifiedType = FullType.unspecified}) {
    return object;
  }

  @override
  Iterable<Type> get types => [Uint8List, Uint8List(0).runtimeType];

  @override
  String get wireName => 'Uint8List';
}
