import 'dart:js_interop';
import 'dart:math';
import 'package:blazing_protostar/blazing_protostar.dart';

@JS('YjsBridge')
external JSObject? get _yjsBridgeGlobal;

@JS('YjsBridge')
extension type _YjsBridge._(JSObject _) implements JSObject {
  external String getText(String clientId);
  external void registerClient(String clientId, JSFunction callback);
  external void unregisterClient(String clientId);
  external void setClientOnline(String clientId, bool online);
  external void insert(String clientId, int position, String text);
  external void delete(String clientId, int position, int count);
  external void undo(String clientId);
  external void redo(String clientId);
  external bool canUndo(String clientId);
  external bool canRedo(String clientId);
}

/// Generates a unique client ID for each backend instance.
String _generateClientId() {
  final random = Random();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// A [DocumentBackend] implementation that syncs via Y.js BroadcastChannel.
///
/// Each instance gets a unique client ID, enabling multiple editors in the
/// same page to sync properly while also syncing across browser tabs.
///
/// Includes undo/redo support via Y.js UndoManager.
class YjsDocumentBackend extends DocumentBackend {
  final _YjsBridge _bridge;
  final String _clientId;
  bool _isOnline = true;

  YjsDocumentBackend._(this._bridge, this._clientId) {
    _bridge.registerClient(
      _clientId,
      ((JSString text) {
        notifyListeners();
      }).toJS,
    );
  }

  /// Creates a new [YjsDocumentBackend] with a unique client ID.
  factory YjsDocumentBackend(JSObject bridge, {String? clientId}) {
    final id = clientId ?? _generateClientId();
    return YjsDocumentBackend._(bridge as _YjsBridge, id);
  }

  /// Sets whether this backend is currently "online" (syncing changes).
  void setOnline(bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    _bridge.setClientOnline(_clientId, online);
    notifyListeners();
  }

  /// Whether this backend is currently online.
  bool get isOnline => _isOnline;

  @override
  String get text => _bridge.getText(_clientId);

  @override
  void insert(int position, String text) {
    if (text.isEmpty) return;
    _bridge.insert(_clientId, position, text);
  }

  @override
  void delete(int position, int count) {
    if (count <= 0) return;
    _bridge.delete(_clientId, position, count);
  }

  /// Undo the last local operation.
  void undo() => _bridge.undo(_clientId);

  /// Redo the last undone operation.
  void redo() => _bridge.redo(_clientId);

  /// Whether there are operations that can be undone.
  bool get canUndo => _bridge.canUndo(_clientId);

  /// Whether there are operations that can be redone.
  bool get canRedo => _bridge.canRedo(_clientId);

  @override
  void dispose() {
    _bridge.unregisterClient(_clientId);
    super.dispose();
  }
}

DocumentBackend createYjsBackend({String? clientId}) {
  final bridge = _yjsBridgeGlobal;
  if (bridge == null) {
    throw StateError(
      'YjsBridge not found. Did you forget to include yjs_bridge.js in your index.html?',
    );
  }
  return YjsDocumentBackend(bridge, clientId: clientId);
}
