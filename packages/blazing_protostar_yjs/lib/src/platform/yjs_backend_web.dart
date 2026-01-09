import 'dart:js_interop';
import 'package:blazing_protostar/blazing_protostar.dart';

@JS('YjsBridge')
external JSObject? get _yjsBridgeGlobal;

@JS('YjsBridge')
extension type _YjsBridge._(JSObject _) implements JSObject {
  external String getText();
  external void updateText(String text);
  external void onUpdate(JSFunction callback);
}

class YjsDocumentBackend extends DocumentBackend {
  final _YjsBridge _bridge;

  YjsDocumentBackend(this._bridge) {
    _bridge.onUpdate(
      ((JSString text) {
        notifyListeners();
      }).toJS,
    );
  }

  @override
  String get text => _bridge.getText();

  @override
  void updateText(String newText) {
    if (text == newText) return;
    _bridge.updateText(newText);
  }
}

DocumentBackend createYjsBackend() {
  final bridge = _yjsBridgeGlobal;
  if (bridge == null) {
    throw StateError(
      'YjsBridge not found. Did you forget to include yjs_bridge.js in your index.html?',
    );
  }
  return YjsDocumentBackend(bridge as _YjsBridge);
}
