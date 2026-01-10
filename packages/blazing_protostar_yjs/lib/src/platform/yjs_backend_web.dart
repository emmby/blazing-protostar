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
  external void undo();
  external void redo();
  external bool canUndo();
  external bool canRedo();
}

/// A [DocumentBackend] implementation that syncs via Y.js BroadcastChannel.
///
/// Includes undo/redo support via Y.js UndoManager.
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

  /// Undo the last local operation.
  void undo() => _bridge.undo();

  /// Redo the last undone operation.
  void redo() => _bridge.redo();

  /// Whether there are operations that can be undone.
  bool get canUndo => _bridge.canUndo();

  /// Whether there are operations that can be redone.
  bool get canRedo => _bridge.canRedo();
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
