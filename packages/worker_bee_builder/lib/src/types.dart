import 'dart:core' as core;
import 'dart:async';
import 'dart:convert' as convert;
import 'dart:isolate' as isolate_lib;
import 'dart:typed_data';

import 'package:async/async.dart' as async;
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart' as meta;
import 'package:stream_channel/stream_channel.dart' as stream_channel;
import 'package:stream_channel/isolate_channel.dart' as isolate_channel;
import 'package:stream_transform/stream_transform.dart' as stream_transform;
import 'package:worker_bee/worker_bee.dart' as worker_bee;

/// Common type references used throughout code generation.
abstract class DartTypes {
  DartTypes._();

  /// `dart:core` types.
  static const core = _Core();

  /// `dart:async` types.
  static const async = _Async();

  /// `dart:convert` types.
  static const convert = _Convert();

  /// `dart:html` types.
  static const html = _Html();

  /// `dart:html_common` types.
  static const htmlCommon = _HtmlCommon();

  /// `dart:isolate` types.
  static const isolate = _Isolate();

  /// `package:js` types.
  static const js = _Js();

  /// `package:meta` types.
  static const meta = _Meta();

  /// `package:async` types
  static const pkgAsync = _PkgAsync();

  /// `package:stream_channel` types.
  static const streamChannel = _StreamChannel();

  /// `package:stream_transform` types.
  static const streamTransform = _StreamTransform();

  /// `dart:typed_data` types.
  static const typedData = _TypedData();

  /// `package:worker_bee` types.
  static const workerBee = _WorkerBee();
}

/// `dart:core` types
class _Core {
  const _Core();

  static const _url = 'dart:core';

  /// Creates a [core.BigInt] reference.
  Reference get bigInt => const Reference('BigInt', _url);

  /// Creates a [core.bool] reference.
  Reference get bool => const Reference('bool', _url);

  /// Creates a [core.DateTime] reference.
  Reference get dateTime => const Reference('DateTime', _url);

  /// Creates a [core.Deprecated] reference.
  Reference get deprecated => const Reference('Deprecated', _url);

  /// Creates a [core.double] reference.
  Reference get double => const Reference('double', _url);

  /// Creates a [core.Function] reference.
  Reference get function => const Reference('Function', _url);

  /// Creates an [core.int] reference.
  Reference get int => const Reference('int', _url);

  /// Creates a [core.Iterable] reference.
  Reference iterable([Reference? ref]) => TypeReference(
        (t) => t
          ..symbol = 'Iterable'
          ..url = _url
          ..types.addAll([
            if (ref != null) ref,
          ]),
      );

  /// Creates a [core.List] reference.
  Reference list([Reference? ref]) => TypeReference(
        (t) => t
          ..symbol = 'List'
          ..url = _url
          ..types.addAll([
            if (ref != null) ref,
          ]),
      );

  /// Creates a [core.Map] reference.
  Reference map(Reference key, Reference value) => TypeReference(
        (t) => t
          ..symbol = 'Map'
          ..url = _url
          ..types.add(key)
          ..types.add(value),
      );

  /// Creates an [core.MapEntry] reference.
  Reference get mapEntry => const Reference('MapEntry', _url);

  /// Creates a [core.Null] reference.
  Reference get null$ => const Reference('Null', _url);

  /// Creates an [core.Object] reference.
  Reference get object => const Reference('Object', _url);

  /// Creates a [core.override] reference.
  Reference get override => const Reference('override', _url);

  /// Creates a [core.RegExp] reference.
  Reference get regExp => const Reference('RegExp', _url);

  /// Creates a [core.Set] reference.
  Reference set(Reference ref) => TypeReference(
        (t) => t
          ..symbol = 'Set'
          ..url = _url
          ..types.add(ref),
      );

  /// Create a [core.StateError] reference.
  Reference get stateError => const Reference('StateError', _url);

  /// Creates a [core.String] reference.
  Reference get string => const Reference('String', _url);

  /// Creates a [core.Type] reference.
  Reference get type => const Reference('Type', _url);

  /// Creates a [core.Uri] reference.
  Reference get uri => const Reference('Uri', _url);

  /// Creates a `void` reference.
  Reference get void$ => const Reference('void');
}

/// `dart:async` types
class _Async {
  const _Async();

  static const _url = 'dart:async';

  /// Creates an [EventSink] reference.
  Reference get eventSink => const Reference('EventSink', _url);

  /// Creates a [Future] reference.
  Reference future(Reference ref) => TypeReference(
        (t) => t
          ..symbol = 'Future'
          ..url = _url
          ..types.add(ref),
      );

  /// Creates a [Stream] reference.
  Reference stream([Reference? ref]) => TypeReference(
        (t) => t
          ..symbol = 'Stream'
          ..url = _url
          ..types.addAll([
            if (ref != null) ref,
          ]),
      );

  /// Creates a [StreamController] reference.
  Reference streamController([Reference? ref]) => TypeReference(
        (t) => t
          ..symbol = 'StreamController'
          ..url = _url
          ..types.addAll([
            if (ref != null) ref,
          ]),
      );
}

/// `dart:convert` types
class _Convert {
  const _Convert();

  static const _url = 'dart:convert';

  /// Creates a [convert.base64Decode] reference.
  Reference get base64Decode => const Reference('base64Decode', _url);

  /// Creates a [convert.base64Encode] reference.
  Reference get base64Encode => const Reference('base64Encode', _url);

  /// Creates a [convert.jsonEncode] reference.
  Reference get jsonEncode => const Reference('jsonEncode', _url);

  /// Creates a [convert.jsonDecode] reference.
  Reference get jsonDecode => const Reference('jsonDecode', _url);

  /// Creates a [convert.utf8] reference.
  Reference get utf8 => const Reference('utf8', _url);
}

/// `dart:html` types
class _Html {
  const _Html();

  static const _url = 'dart:html';

  /// Creates a `DedicatedWorkerGlobalScope` reference.
  Reference get dedicatedWorkerGlobalScope =>
      const Reference('DedicatedWorkerGlobalScope', _url);

  /// Creates a `ErrorEvent` reference.
  Reference get errorEvent => const Reference('ErrorEvent', _url);

  /// Creates a `Event` reference.
  Reference get event => const Reference('Event', _url);

  /// Creates a `MessageEvent` reference.
  Reference get messageEvent => const Reference('MessageEvent', _url);

  /// Creates a `Worker` reference.
  Reference get worker => const Reference('Worker', _url);
}

/// `dart:html_common` types
class _HtmlCommon {
  const _HtmlCommon();

  static const _url = 'dart:html_common';

  Reference get dartToNative => const Reference(
        'convertDartToNative_SerializedScriptValue',
        _url,
      );

  Reference get nativeToDart => const Reference(
        'convertNativeToDart_SerializedScriptValue',
        _url,
      );
}

/// `dart:isolate` types
class _Isolate {
  const _Isolate();

  static const _url = 'dart:isolate';

  /// Creates an [isolate_lib.Isolate] reference.
  Reference get isolate => const Reference('Isolate', _url);

  /// Creates an [isolate_lib.ReceivePort] reference.
  Reference get receivePort => const Reference('ReceivePort', _url);

  /// Creates an [isolate_lib.SendPort] reference.
  Reference get sendPort => const Reference('SendPort', _url);

  /// Creates an [isolate_lib.TransferableTypedData] reference.
  Reference get transferableTypedData =>
      const Reference('TransferableTypedData', _url);
}

/// `package:js` types
class _Js {
  const _Js();

  static const _url = 'package:js/js.dart';

  /// Creates a `@anonymous` reference.
  Reference get anonymous => const Reference('anonymous', _url);

  /// Creates a `@JS` reference.
  Reference get js => const Reference('JS', _url);
}

/// `package:meta` types.
class _Meta {
  const _Meta();

  static const _url = 'package:meta/meta.dart';

  /// Creates a [meta.experimental] reference.
  Reference get experimental => const Reference('experimental', _url);

  /// Creates a [meta.internal] reference.
  Reference get internal => const Reference('internal', _url);

  /// Creates a [meta.immutable] reference.
  Reference get immutable => const Reference('immutable', _url);
}

/// `package:async` types
class _PkgAsync {
  const _PkgAsync();

  static const _url = 'package:worker_bee/worker_bee.dart';

  /// Creates an [async.StreamSinkTransformer] reference.
  Reference get streamSinkTranformer =>
      const Reference('StreamSinkTransformer', _url);
}

/// `dart:typed_data` types
class _TypedData {
  const _TypedData();

  static const _url = 'dart:typed_data';

  /// Creates a [Uint8List] reference.
  Reference get uint8List => const Reference('Uint8List', _url);
}

/// `package:stream_channel` types
class _StreamChannel {
  const _StreamChannel();

  static const _url = 'package:worker_bee/worker_bee.dart';

  /// Creates an [isolate_channel.IsolateChannel] reference.
  Reference get isolateChannel => const Reference('IsolateChannel', _url);

  /// Creates a [stream_channel.StreamChannel] reference.
  Reference get streamChannel => const Reference('StreamChannel', _url);

  /// Creates a [stream_channel.StreamChannelController] reference.
  Reference get streamChannelController =>
      const Reference('StreamChannelController', _url);
}

/// `package:stream_transform` types
class _StreamTransform {
  const _StreamTransform();

  static const _url = 'package:worker_bee/worker_bee.dart';
}

/// `package:worker_bee` types
class _WorkerBee {
  const _WorkerBee();

  static const _url = 'package:worker_bee/worker_bee.dart';

  /// Creates a [worker_bee.WebWorkerException] reference.
  Reference get webWorkerException =>
      const Reference('WebWorkerException', _url);
}

extension ReferenceUtil on Reference {
  TypeReference get typeRef =>
      (this is TypeReference ? this : type) as TypeReference;

  TypeReference get nullable => typeRef.rebuild((t) => t.isNullable = true);

  TypeReference get nonNull => typeRef.rebuild((t) => t.isNullable = false);
}
