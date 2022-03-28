// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_worker_exception.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<WebWorkerException> _$webWorkerExceptionSerializer =
    new _$WebWorkerExceptionSerializer();

class _$WebWorkerExceptionSerializer
    implements StructuredSerializer<WebWorkerException> {
  @override
  final Iterable<Type> types = const [WebWorkerException, _$WebWorkerException];
  @override
  final String wireName = 'WebWorkerException';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, WebWorkerException object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'error',
      serializers.serialize(object.error,
          specifiedType: const FullType(String)),
    ];
    Object? value;
    value = object.filename;
    if (value != null) {
      result
        ..add('filename')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.lineNo;
    if (value != null) {
      result
        ..add('lineNo')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
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
  WebWorkerException deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new WebWorkerExceptionBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'filename':
          result.filename = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'lineNo':
          result.lineNo = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int?;
          break;
        case 'error':
          result.error = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
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

class _$WebWorkerException extends WebWorkerException {
  @override
  final String? filename;
  @override
  final int? lineNo;
  @override
  final String error;
  @override
  final StackTrace? stackTrace;

  factory _$WebWorkerException(
          [void Function(WebWorkerExceptionBuilder)? updates]) =>
      (new WebWorkerExceptionBuilder()..update(updates)).build();

  _$WebWorkerException._(
      {this.filename, this.lineNo, required this.error, this.stackTrace})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(error, 'WebWorkerException', 'error');
  }

  @override
  WebWorkerException rebuild(
          void Function(WebWorkerExceptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WebWorkerExceptionBuilder toBuilder() =>
      new WebWorkerExceptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WebWorkerException &&
        filename == other.filename &&
        lineNo == other.lineNo &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, filename.hashCode), lineNo.hashCode), error.hashCode),
        stackTrace.hashCode));
  }
}

class WebWorkerExceptionBuilder
    implements
        Builder<WebWorkerException, WebWorkerExceptionBuilder>,
        WorkerBeeExceptionBuilder {
  _$WebWorkerException? _$v;

  String? _filename;
  String? get filename => _$this._filename;
  set filename(covariant String? filename) => _$this._filename = filename;

  int? _lineNo;
  int? get lineNo => _$this._lineNo;
  set lineNo(covariant int? lineNo) => _$this._lineNo = lineNo;

  String? _error;
  String? get error => _$this._error;
  set error(covariant String? error) => _$this._error = error;

  StackTrace? _stackTrace;
  StackTrace? get stackTrace => _$this._stackTrace;
  set stackTrace(covariant StackTrace? stackTrace) =>
      _$this._stackTrace = stackTrace;

  WebWorkerExceptionBuilder();

  WebWorkerExceptionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _filename = $v.filename;
      _lineNo = $v.lineNo;
      _error = $v.error;
      _stackTrace = $v.stackTrace;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant WebWorkerException other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$WebWorkerException;
  }

  @override
  void update(void Function(WebWorkerExceptionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$WebWorkerException build() {
    final _$result = _$v ??
        new _$WebWorkerException._(
            filename: filename,
            lineNo: lineNo,
            error: BuiltValueNullFieldError.checkNotNull(
                error, 'WebWorkerException', 'error'),
            stackTrace: stackTrace);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
