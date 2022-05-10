import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/serializers/stream_serializer.dart';

/// {@template worker_bee.serializers.stream_serializer_impl}
/// VM implementation of [StreamSerializer].
/// {@endtemplate}
@internal
class StreamSerializerImpl extends StreamSerializer {
  /// {@macro worker_bee.serializers.stream_serializer_impl}
  const StreamSerializerImpl() : super.protected();

  @override
  Stream<Object?> deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return serialized as Stream<Object?>;
  }

  @override
  Object serialize(Serializers serializers, Stream<Object?> object,
      {FullType specifiedType = FullType.unspecified}) {
    return object;
  }
}
