import 'package:blazing_protostar/blazing_protostar.dart';

/// Creates a [DocumentBackend] that syncs with Y.js.
///
/// Platform-specific implementations handle the bridge to the JS engine.
DocumentBackend createYjsBackend() {
  throw UnsupportedError(
    'YjsDocumentBackend is not supported on this platform.',
  );
}

/// Stub class for non-web platforms.
///
/// On web, the real implementation is in `yjs_backend_web.dart`.
class YjsDocumentBackend extends DocumentBackend {
  YjsDocumentBackend._() {
    throw UnsupportedError(
      'YjsDocumentBackend is not supported on this platform.',
    );
  }

  @override
  String get text => throw UnsupportedError('Not supported');

  @override
  void insert(int position, String text) =>
      throw UnsupportedError('Not supported');

  @override
  void delete(int position, int count) =>
      throw UnsupportedError('Not supported');

  void undo() => throw UnsupportedError('Not supported');
  void redo() => throw UnsupportedError('Not supported');
  bool get canUndo => throw UnsupportedError('Not supported');
  bool get canRedo => throw UnsupportedError('Not supported');
}
