import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';

import 'stream_serializer_io.dart'
    if (dart.library.js) 'stream_serializer_js.dart';

abstract class StreamSerializer implements PrimitiveSerializer<Stream> {
  const factory StreamSerializer() = StreamSerializerImpl;

  @protected
  const StreamSerializer.protected();

  @override
  Iterable<Type> get types => [Stream];

  @override
  String get wireName => 'Stream';
}
