import 'dart:js_interop';
import 'package:blazing_protostar/blazing_protostar.dart';

@JS('YjsBridge')
external JSObject? get _yjsBridgeGlobal;

@JS('YjsBridge')
extension type _YjsBridge._(JSObject _) implements JSObject {
  external String getText();
  external void insert(int position, String text);
  external void delete(int position, int count);
  external void onUpdate(JSFunction callback);
}

/// A [DocumentBackend] implementation that syncs via Y.js BroadcastChannel.
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
  void insert(int position, String text) {
    if (text.isEmpty) return;
    _bridge.insert(position, text);
  }

  @override
  void delete(int position, int count) {
    if (count <= 0) return;
    _bridge.delete(position, count);
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
