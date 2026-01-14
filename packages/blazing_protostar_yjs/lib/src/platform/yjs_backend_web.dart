import 'dart:js_interop';
import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:blazing_protostar_yjs/src/yjs_types.dart';

/// A [DocumentBackend] implementation that syncs via a [YDoc].
class YjsDocumentBackend extends DocumentBackend {
  late final YText _yText;

  // We keep track of the observer callback to unobserve later
  JSFunction? _observer;

  /// Creates a backend bound to the given [yText].
  YjsDocumentBackend(this._yText) {
    // Set up observer
    _observer = ((JSAny events, JSAny transaction) {
      notifyListeners();
    }).toJS;

    _yText.observe(_observer!);
  }

  @override
  String get text => _yText.jsToString();

  @override
  void insert(int position, String text) {
    _yText.insert(position, text);
  }

  @override
  void delete(int position, int count) {
    if (count <= 0) return;
    _yText.delete(position, count);
  }

  @override
  void dispose() {
    if (_observer != null) {
      _yText.unobserve(_observer!);
    }
    super.dispose();
  }
}

/// Helper to create backend.
DocumentBackend createYjsBackend(YText yText) {
  return YjsDocumentBackend(yText);
}
