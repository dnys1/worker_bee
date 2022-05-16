@internal
library aws_http.js.promise;

import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:meta/meta.dart';

/// A [Promise] executor callback.
typedef Executor<T> = void Function(
  void Function(T) resolve,
  void Function(Object) reject,
);

/// {@template worker_bee.js.interop.promise}
/// The Promise object represents the eventual completion (or failure) of an
/// asynchronous operation and its resulting value.
/// {@endtemplate}
@JS()
@staticInterop
class Promise<T> {
  /// {@macro worker_bee.js.interop.promise}
  factory Promise(Executor<T> executor) => Promise._(allowInterop(executor));

  external factory Promise._(Executor<T> executor);

  /// Creates a Promise from a Dart [future].
  ///
  /// If [captureError] is `true`, all errors will be caught by the promise
  /// and not reported as unhandled errors in the current [Zone]. This can
  /// decrease the visibility of errors in Dart code depending on the level of
  /// integration with JS APIs and their error-handling specifics.
  factory Promise.fromFuture(
    Future<T> future, {
    bool captureError = false,
  }) {
    return Promise((resolve, reject) async {
      try {
        resolve(await future);
      } on Object catch (e) {
        reject(e);
        if (!captureError) {
          rethrow;
        }
      }
    });
  }
}

/// {@macro worker_bee.js.interop.promise}
extension PropsPromise<T> on Promise<T> {
  /// Resolves `this` as a Dart [Future].
  Future<T> get future => js_util.promiseToFuture(this);
}
