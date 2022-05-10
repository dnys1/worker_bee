import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/exception/worker_bee_exception.dart';
import 'package:worker_bee/src/serializers/stack_trace_serializer.dart';
import 'package:worker_bee/src/serializers/stream_serializer.dart';
import 'package:worker_bee/worker_bee.dart';

part 'serializers.g.dart';

/// Serializers common to all worker bees.
@internal
@SerializersFor([
  WorkerBeeExceptionImpl,
  LogMessage,
])
final Serializers workerBeeSerializers = (_$workerBeeSerializers.toBuilder()
      ..add(const StackTraceSerializer())
      ..add(const StreamSerializer()))
    .build();
