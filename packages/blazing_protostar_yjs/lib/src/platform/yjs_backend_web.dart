import 'dart:js_interop';
import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:blazing_protostar_yjs/src/yjs_types.dart';

/// A [DocumentBackend] implementation that syncs via a [YDoc].
class YjsDocumentBackend extends DocumentBackend {
  final YDoc _doc;
  late final YText _yText;

  // We keep track of the observer callback to unobserve later
  JSFunction? _observer;

  /// Creates a backend bound to the given [doc] and specific [fieldName].
  ///
  /// The [fieldName] defaults to 'content'.
  YjsDocumentBackend(this._doc, {String fieldName = 'content'}) {
    _yText = _doc.getText(fieldName);

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

/// Helper to create backend - kept for API compatibility if needed,
/// though we encourage direct instantiation now.
DocumentBackend createYjsBackend({String? clientId}) {
  // This is the old "batteries included" way - we might deprecate or remove it
  // since we can't magically summon a YDoc without context now.
  // For now, let's create a standalone YDoc for testing/local use.
  final doc = YDoc();
  return YjsDocumentBackend(doc);
}
