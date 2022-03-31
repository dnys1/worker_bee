import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:worker_bee/worker_bee.dart';

part 'log_message.g.dart';

/// Log levels, mirroring those in `package:logging`.
class LogLevel extends EnumClass {
  /// Log level `ALL`
  static const LogLevel ALL = _$ALL;

  /// Log level `OFF`
  static const LogLevel OFF = _$OFF;

  /// Log level `SHOUT`
  static const LogLevel SHOUT = _$SHOUT;

  /// Log level `SEVERE`
  static const LogLevel SEVERE = _$SEVERE;

  /// Log level `WARNING`
  static const LogLevel WARNING = _$WARNING;

  /// Log level `INFO`
  static const LogLevel INFO = _$INFO;

  /// Log level `CONFIG`
  static const LogLevel CONFIG = _$CONFIG;

  /// Log level `FINE`
  static const LogLevel FINE = _$FINE;

  /// Log level `FINER`
  static const LogLevel FINER = _$FINER;

  /// Log level `FINEST`
  static const LogLevel FINEST = _$FINEST;

  const LogLevel._(String name) : super(name);

  /// All [LogLevel] values.
  static BuiltSet<LogLevel> get values => _$values;

  /// The [LogLevel] corresponding to [name].
  static LogLevel valueOf(String name) => _$valueOf(name);

  /// The [LogLevel] serializer.
  static Serializer<LogLevel> get serializer => _$logLevelSerializer;

  @override
  String toString() => name;
}

/// {@template worker_bee.log_message}
/// A message logged by a worker bee.
/// {@endtemplate}
abstract class LogMessage implements Built<LogMessage, LogMessageBuilder> {
  /// {@macro worker_bee.log_message}
  factory LogMessage([void Function(LogMessageBuilder) updates]) = _$LogMessage;
  LogMessage._();

  /// Creates a [LogMessage] from a `package:logging` record.
  factory LogMessage.fromRecord(
    String workerName,
    LogRecord record, {
    required bool local,
  }) =>
      LogMessage(
        (b) => b
          ..workerName = workerName
          ..message = record.message
          ..local = local
          ..level = LogLevel.valueOf(record.level.name)
          ..error = record.error?.toString()
          ..stackTrace = record.stackTrace,
      );

  /// The name of the worker that produced the log.
  String get workerName;

  /// The message of the log.
  String get message;

  /// Whether the log was produced locally or not.
  bool get local;

  /// The log level.
  LogLevel get level;

  /// The error associated with this log, if any.
  Object? get error;

  /// The stack trace associated with [error], if any.
  StackTrace? get stackTrace;

  /// The [LogMessage] serializer, for use in built_value.
  static Serializer<LogMessage> get serializer => _$logMessageSerializer;
}

// ignore_for_file: constant_identifier_names
