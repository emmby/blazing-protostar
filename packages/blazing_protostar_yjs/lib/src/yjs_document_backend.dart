import 'dart:js_interop';
import 'package:blazing_protostar/blazing_protostar.dart';

@JS('YjsBridge')
extension type YjsBridge._(JSObject _) implements JSObject {
  external String getText();
  external void updateText(String text);
  external void onUpdate(JSFunction callback);
}

/// A [DocumentBackend] implementation that syncs with Y.js.
///
/// This implementation currently targets Web via JS Interop.
class YjsDocumentBackend extends DocumentBackend {
  final YjsBridge _bridge;

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
    // Note: We don't notifyListeners here because the bridge will call
    // our onUpdate callback, which is the "Sync Loop" safe way.
  }
}
