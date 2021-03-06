// ignore_for_file: prefer_void_to_null

@JS()
@internal
library aws_http.js.common;

import 'dart:async';
import 'dart:js_util' as js_util;

import 'package:js/js.dart';
import 'package:meta/meta.dart';
import 'package:worker_bee/src/recase.dart';

/// The JS `undefined`.
///
/// Marked as `dynamic` so that this can be used in place of `null` in
/// strongly-typed APIs of type `T?`.
@JS()
external Null get undefined;

/// An [Enum] representing a nullable JS value.
mixin JSEnum on Enum {
  /// The JS representation of `this`.
  ///
  /// Default values are represented as `undefined`, as opposed to `null` which
  /// can be interpreted incorrectly by DOM APIs. Non-default values are
  /// representated as the parameter-cased [name].
  dynamic get jsValue {
    switch (name) {
      case r'default$':
        return undefined;
      default:
        return name.paramCase;
    }
  }
}

/// Refers to either [window] or the worker's global scope, depending on the
/// program's execution context.
@JS()
external GlobalScope get self;

/// The window object of the current context.
@JS()
external Window? get window;

/// The Window interface represents a window containing a DOM document.
@JS()
@staticInterop
abstract class Window implements GlobalScope {}

/// A function which handles DOM events.
typedef EventHandler<T extends Event> = void Function(T event);

/// {@template amplify_secure_storage_dart.event}
/// The Event interface represents an event which takes place in the DOM.
/// {@endtemplate}
@JS()
@staticInterop
abstract class Event {}

/// {@macro amplify_secure_storage_dart.event}
extension PropsEvent on Event {
  /// A reference to the object onto which this event was dispatched.
  external EventTarget? get target;
}

/// {@template worker_bee.js.interop.event_target}
/// The EventTarget interface is implemented by objects that can receive events
/// and may have listeners for them.
/// {@endtemplate}
@JS()
@staticInterop
abstract class EventTarget {}

/// {@macro worker_bee.js.interop.event_target}
extension PropsEventTarget on EventTarget {
  /// Registers [listener] as a callback for events of type [type].
  void addEventListener<T extends Event>(
    String type,
    EventHandler<T> listener,
  ) =>
      js_util.callMethod(this, 'addEventListener', [
        type,
        allowInterop(listener),
        false,
      ]);

  /// Removes [listener] as a callback for events of type [type].
  void removeEventListener<T extends Event>(
    String type,
    EventHandler<T> listener,
  ) =>
      js_util.callMethod(this, 'removeEventListener', [
        type,
        allowInterop(listener),
        false,
      ]);
}

Object? _convertToJs(Object? o) {
  if (o == null || o is! Map || o is! Iterable) return o;
  return js_util.jsify(o);
}

/// {@template worker_bee.js.interop.global_scope}
/// The global execution context, referred to by [self].
///
/// Either a [Window] object or a [WorkerGlobalScope] object.
/// {@endtemplate}
@JS()
@staticInterop
class GlobalScope extends EventTarget {}

/// {@macro worker_bee.js.interop.global_scope}
extension PropsGlobalScope on GlobalScope {
  /// A [Location] object with information about the current location of the
  /// document.
  external Location get location;

  /// When called on a [WorkerGlobalScope], this sends a message to the main
  /// thread that spawned it.
  ///
  /// When called on a [Window], this sends a message to the parent window
  /// object.
  void postMessage(
    Object? o, [
    List<Object>? transfer,
  ]) =>
      js_util.callMethod(this, 'postMessage', [
        _convertToJs(o),
        transfer?.map(_convertToJs).toList(),
      ]);
}

/// {@template worker_bee.js.interop.message_event}
/// The MessageEvent interface represents a message received by a target object.
/// {@endtemplate}
@JS()
@staticInterop
class MessageEvent extends Event {}

/// {@macro worker_bee.js.interop.message_event}
extension PropsMessageEvent on MessageEvent {
  /// The data sent by the message emitter.
  Object? get data {
    final Object? data = js_util.getProperty(this, 'data');
    return dartify(data);
  }

  /// An array of [MessagePort] objects representing the ports associated with
  /// the channel the message is being sent through.
  List<MessagePort> get ports {
    final Object ports = js_util.getProperty(this, 'ports');
    return (dartify(ports, recursive: false) as List).cast<MessagePort>();
  }
}

/// {@template worker_bee.js.interop.message_port}
/// The MessagePort interface of the Channel Messaging API represents one of the
/// two ports of a [MessageChannel], allowing messages to be sent from one port
/// and listening out for them arriving at the other.
/// {@endtemplate}
@JS()
@staticInterop
class MessagePort extends EventTarget {}

/// {@macro worker_bee.js.interop.message_port}
extension PropsMessagePort on MessagePort {
  /// Fired when a MessagePort object receives a message.
  Stream<MessageEvent> get onMessage {
    final StreamController<MessageEvent> _controller = StreamController();
    addEventListener<MessageEvent>('message', _controller.add);
    addEventListener<MessageEvent>('messageerror', ((event) {
      _controller.addError(event);
      _controller.close();
    }));
    scheduleMicrotask(start);
    return _controller.stream;
  }

  /// Sends a message from the port, and optionally, transfers ownership of
  /// objects to other browsing contexts.
  void postMessage(
    Object? o, [
    List<Object>? transfer,
  ]) =>
      js_util.callMethod(this, 'postMessage', [
        _convertToJs(o),
        transfer?.map(_convertToJs).toList(),
      ]);

  /// Starts the sending of messages queued on the port.
  ///
  /// Only needed when using `EventTarget.addEventListener`; it is implied when
  /// using [onMessage].
  external void start();

  /// Disconnects the port, so it is no longer active.
  external void close();
}

/// {@template worker_bee.js.interop.location}
/// The Location interface represents the location (URL) of the object it is
/// linked to.
/// {@endtemplate}
@JS()
@staticInterop
abstract class Location {}

/// {@macro worker_bee.js.interop.location}
extension PropsLocation on Location {
  /// The entire URL.
  external String get href;
}

/// {@template worker_bee.js.interop.worker_init}
/// An object containing option properties that can be set when creating a
/// [Worker] instance.
/// {@endtemplate}
@JS()
@anonymous
@staticInterop
class WorkerInit {
  /// {@macro worker_bee.js.interop.worker_init}
  external factory WorkerInit({
    String? type,
  });
}

/// {@template worker_bee.js.interop.worker}
/// The Worker interface of the Web Workers API represents a background task
/// that can be created via script, which can send messages back to its creator.
/// {@endtemplate}
@JS()
@staticInterop
class Worker extends EventTarget {
  /// {@macro worker_bee.js.interop.worker}
  external factory Worker(String url, [WorkerInit? init]);
}

/// {@macro worker_bee.js.interop.worker}
extension PropsWorker on Worker {
  /// The error event of the Worker interface fires when an error occurs in the
  /// worker.
  set onError(EventHandler listener) {
    js_util.setProperty(this, 'onerror', allowInterop(listener));
  }

  /// The `message` event is fired on a Worker object when the worker's parent
  /// receives a message from its worker.
  set onMessage(EventHandler<MessageEvent> listener) {
    js_util.setProperty(this, 'onmessage', allowInterop(listener));
  }

  /// Sends a message to the worker's inner scope.
  external void postMessage(Object? o, [List<Object?>? transfer]);

  /// Immediately terminates the Worker.
  ///
  /// This does not offer the worker an opportunity to finish its operations;
  /// it is stopped at once.
  external void terminate();
}

/// {@template worker_bee.js.interop.error_event}
/// The ErrorEvent interface represents events providing information related to
/// errors in scripts or in files.
/// {@endtemplate}
@JS()
@staticInterop
class ErrorEvent extends Event {}

/// {@macro worker_bee.js.interop.error_event}
extension PropsErrorEvent on ErrorEvent {
  /// The error object associated with the event.
  external Object? get error;

  /// A string containing a human-readable error message describing the problem.
  external String? get message;
}

/// {@template worker_bee.js.interop.message_channel}
/// The MessageChannel interface of the Channel Messaging API allows us to
/// create a new message channel and send data through it via its two
/// [MessagePort] properties.
/// {@endtemplate}
@JS()
@staticInterop
class MessageChannel {
  /// {@macro worker_bee.js.interop.message_channel}
  external factory MessageChannel();
}

/// {@macro worker_bee.js.interop.message_channel}
extension PropsMessageChannel on MessageChannel {
  /// Port 1 of the channel.
  external MessagePort get port1;

  /// Port 2 of the channel.
  external MessagePort get port2;
}

/// {@template worker_bee.js.interop.js_object}
/// The base class for all JavaScript objects.
/// {@endtemplate}
@JS('Object')
@staticInterop
class JSObject {
  /// Returns an array of a given [object]'s own enumerable property names,
  /// iterated in the same order that a normal loop would.
  external static List<String> keys(Object object);

  /// Returns the prototype (i.e. the value of the internal `[[Prototype]]`
  /// property) of the specified [object].
  external static Object? getPrototypeOf(Object? object);

  /// The prototype of the JS `Object` class.
  external static Object get prototype;
}

/// Returns `true` if a given object is a simple JavaScript object.
bool isJavaScriptSimpleObject(Object? value) {
  final Object? proto = JSObject.getPrototypeOf(value);
  return proto == null || proto == JSObject.prototype;
}

Object? _getConstructor(String constructorName) =>
    js_util.getProperty(self, constructorName);

/// Like [js_util.instanceof] only takes a [String] for the object name instead
/// of a constructor object.
bool instanceOfString(Object? element, String objectType) {
  Object? constructor = _getConstructor(objectType);
  return constructor != null && js_util.instanceof(element, constructor);
}

/// Returns `true` if a given object is a JavaScript array.
bool isJavaScriptArray(Object? value) => instanceOfString(value, 'Array');

/// Effectively the inverse of [js_util.jsify], [dartify] Takes a JavaScript
/// object, and converts it to a Dart based object. Only JS primitives, arrays,
/// or 'map' like JS objects are supported.
Object? dartify(Object? o, {bool recursive = true}) {
  if (o == null) return null;
  if (isJavaScriptSimpleObject(o)) {
    Map<Object?, Object?> dartObject = {};
    List<Object?> originalKeys = JSObject.keys(o);
    List<Object?> dartKeys = [];
    for (Object? key in originalKeys) {
      dartKeys.add(recursive ? dartify(key) : key);
    }
    for (int i = 0; i < originalKeys.length; i++) {
      Object? jsKey = originalKeys[i];
      Object? dartKey = dartKeys[i];
      if (jsKey != null) {
        final Object? jsValue = js_util.getProperty(o, jsKey);
        dartObject[dartKey] = recursive ? dartify(jsValue) : jsValue;
      }
    }
    return dartObject;
  }
  if (isJavaScriptArray(o)) {
    List<Object?> dartObject = [];
    int length = js_util.getProperty(o, 'length');
    for (int i = 0; i < length; i++) {
      final Object? jsValue = js_util.getProperty(o, i);
      dartObject.add(recursive ? dartify(jsValue) : jsValue);
    }
    return dartObject;
  }
  return o;
}
