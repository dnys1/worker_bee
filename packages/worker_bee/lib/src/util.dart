/// Prints [o] in debug-mode only.
void safePrint(Object? o) {
  var isDebugMode = false;
  assert(() {
    return isDebugMode = true;
  }());
  if (isDebugMode) {
    print(o);
  }
}

// ignore_for_file: avoid_print, prefer_asserts_with_message
