import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';

import 'stream_serializer_io.dart'
    if (dart.library.js) 'stream_serializer_js.dart';

/// {@template worker_bee.serializers.stream_serializer}
/// Serializes [Stream]s in a platform-dependent manner.
///
/// Can only serialize streams of type `Object?`. When the type is known, they
/// should be cast to the typed value. For example, to have a `Stream<int>`
/// in your built_value type:
///
/// ```dart
/// abstract class MyType implements Built<MyType, MyTypeBuilder> {
///   // ...
///
///   Stream<Object?> get uncastStreamOfInts;
///   Stream<int> get streamOfInts => uncastStreamOfInts.cast();
/// }
/// ```
/// {@endtemplate}
@internal
abstract class StreamSerializer
    implements PrimitiveSerializer<Stream<Object?>> {
  /// {@macro worker_bee.serializers.stream_serializer}
  const factory StreamSerializer() = StreamSerializerImpl;

  /// {@macro worker_bee.serializers.stream_serializer}
  ///
  /// Private constructor for subclasses.
  @protected
  const StreamSerializer.protected();

  @override
  Iterable<Type> get types => [Stream];

  @override
  String get wireName => 'Stream';
}
