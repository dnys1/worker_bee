import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/serializers/stream_serializer.dart';

@internal
class StreamSerializerImpl extends StreamSerializer {
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
