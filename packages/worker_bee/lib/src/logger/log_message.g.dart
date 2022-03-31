// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const LogLevel _$all = const LogLevel._('all');
const LogLevel _$off = const LogLevel._('off');
const LogLevel _$shout = const LogLevel._('shout');
const LogLevel _$severe = const LogLevel._('severe');
const LogLevel _$warning = const LogLevel._('warning');
const LogLevel _$info = const LogLevel._('info');
const LogLevel _$config = const LogLevel._('config');
const LogLevel _$fine = const LogLevel._('fine');
const LogLevel _$finer = const LogLevel._('finer');
const LogLevel _$finest = const LogLevel._('finest');

LogLevel _$valueOf(String name) {
  switch (name) {
    case 'all':
      return _$all;
    case 'off':
      return _$off;
    case 'shout':
      return _$shout;
    case 'severe':
      return _$severe;
    case 'warning':
      return _$warning;
    case 'info':
      return _$info;
    case 'config':
      return _$config;
    case 'fine':
      return _$fine;
    case 'finer':
      return _$finer;
    case 'finest':
      return _$finest;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<LogLevel> _$values = new BuiltSet<LogLevel>(const <LogLevel>[
  _$all,
  _$off,
  _$shout,
  _$severe,
  _$warning,
  _$info,
  _$config,
  _$fine,
  _$finer,
  _$finest,
]);

Serializer<LogLevel> _$logLevelSerializer = new _$LogLevelSerializer();
Serializer<LogMessage> _$logMessageSerializer = new _$LogMessageSerializer();

class _$LogLevelSerializer implements PrimitiveSerializer<LogLevel> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'all': 'ALL',
    'off': 'OFF',
    'shout': 'SHOUT',
    'severe': 'SEVERE',
    'warning': 'WARNING',
    'info': 'INFO',
    'config': 'CONFIG',
    'fine': 'FINE',
    'finer': 'FINER',
    'finest': 'FINEST',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ALL': 'all',
    'OFF': 'off',
    'SHOUT': 'shout',
    'SEVERE': 'severe',
    'WARNING': 'warning',
    'INFO': 'info',
    'CONFIG': 'config',
    'FINE': 'fine',
    'FINER': 'finer',
    'FINEST': 'finest',
  };

  @override
  final Iterable<Type> types = const <Type>[LogLevel];
  @override
  final String wireName = 'LogLevel';

  @override
  Object serialize(Serializers serializers, LogLevel object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  LogLevel deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      LogLevel.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$LogMessageSerializer implements StructuredSerializer<LogMessage> {
  @override
  final Iterable<Type> types = const [LogMessage, _$LogMessage];
  @override
  final String wireName = 'LogMessage';

  @override
  Iterable<Object?> serialize(Serializers serializers, LogMessage object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'workerName',
      serializers.serialize(object.workerName,
          specifiedType: const FullType(String)),
      'message',
      serializers.serialize(object.message,
          specifiedType: const FullType(String)),
      'local',
      serializers.serialize(object.local, specifiedType: const FullType(bool)),
      'level',
      serializers.serialize(object.level,
          specifiedType: const FullType(LogLevel)),
    ];
    Object? value;
    value = object.error;
    if (value != null) {
      result
        ..add('error')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(Object)));
    }
    value = object.stackTrace;
    if (value != null) {
      result
        ..add('stackTrace')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(StackTrace)));
    }
    return result;
  }

  @override
  LogMessage deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LogMessageBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'workerName':
          result.workerName = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'message':
          result.message = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'local':
          result.local = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'level':
          result.level = serializers.deserialize(value,
              specifiedType: const FullType(LogLevel)) as LogLevel;
          break;
        case 'error':
          result.error = serializers.deserialize(value,
              specifiedType: const FullType(Object));
          break;
        case 'stackTrace':
          result.stackTrace = serializers.deserialize(value,
              specifiedType: const FullType(StackTrace)) as StackTrace?;
          break;
      }
    }

    return result.build();
  }
}

class _$LogMessage extends LogMessage {
  @override
  final String workerName;
  @override
  final String message;
  @override
  final bool local;
  @override
  final LogLevel level;
  @override
  final Object? error;
  @override
  final StackTrace? stackTrace;

  factory _$LogMessage([void Function(LogMessageBuilder)? updates]) =>
      (new LogMessageBuilder()..update(updates)).build();

  _$LogMessage._(
      {required this.workerName,
      required this.message,
      required this.local,
      required this.level,
      this.error,
      this.stackTrace})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        workerName, 'LogMessage', 'workerName');
    BuiltValueNullFieldError.checkNotNull(message, 'LogMessage', 'message');
    BuiltValueNullFieldError.checkNotNull(local, 'LogMessage', 'local');
    BuiltValueNullFieldError.checkNotNull(level, 'LogMessage', 'level');
  }

  @override
  LogMessage rebuild(void Function(LogMessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LogMessageBuilder toBuilder() => new LogMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LogMessage &&
        workerName == other.workerName &&
        message == other.message &&
        local == other.local &&
        level == other.level &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, workerName.hashCode), message.hashCode),
                    local.hashCode),
                level.hashCode),
            error.hashCode),
        stackTrace.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LogMessage')
          ..add('workerName', workerName)
          ..add('message', message)
          ..add('local', local)
          ..add('level', level)
          ..add('error', error)
          ..add('stackTrace', stackTrace))
        .toString();
  }
}

class LogMessageBuilder implements Builder<LogMessage, LogMessageBuilder> {
  _$LogMessage? _$v;

  String? _workerName;
  String? get workerName => _$this._workerName;
  set workerName(String? workerName) => _$this._workerName = workerName;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  bool? _local;
  bool? get local => _$this._local;
  set local(bool? local) => _$this._local = local;

  LogLevel? _level;
  LogLevel? get level => _$this._level;
  set level(LogLevel? level) => _$this._level = level;

  Object? _error;
  Object? get error => _$this._error;
  set error(Object? error) => _$this._error = error;

  StackTrace? _stackTrace;
  StackTrace? get stackTrace => _$this._stackTrace;
  set stackTrace(StackTrace? stackTrace) => _$this._stackTrace = stackTrace;

  LogMessageBuilder();

  LogMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _workerName = $v.workerName;
      _message = $v.message;
      _local = $v.local;
      _level = $v.level;
      _error = $v.error;
      _stackTrace = $v.stackTrace;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LogMessage other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$LogMessage;
  }

  @override
  void update(void Function(LogMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$LogMessage build() {
    final _$result = _$v ??
        new _$LogMessage._(
            workerName: BuiltValueNullFieldError.checkNotNull(
                workerName, 'LogMessage', 'workerName'),
            message: BuiltValueNullFieldError.checkNotNull(
                message, 'LogMessage', 'message'),
            local: BuiltValueNullFieldError.checkNotNull(
                local, 'LogMessage', 'local'),
            level: BuiltValueNullFieldError.checkNotNull(
                level, 'LogMessage', 'level'),
            error: error,
            stackTrace: stackTrace);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
