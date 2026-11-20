import 'dart:js_interop';

@JS()
external JSObject get navigator;

extension on JSObject {
  @JS('vibrate')
  external JSAny? get _vibrateFn;

  @JS('vibrate')
  external bool _vibrate(JSNumber ms);
}

// Safari (every iPhone browser) and some desktops have no navigator.vibrate.
bool get _supported => navigator._vibrateFn != null;

void vibrate(int durationMs) {
  if (_supported) navigator._vibrate(durationMs.toJS);
}

void cancel() {
  if (_supported) navigator._vibrate(0.toJS);
}
