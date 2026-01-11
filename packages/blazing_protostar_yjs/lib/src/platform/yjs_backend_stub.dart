import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:blazing_protostar_yjs/src/yjs_types.dart';

/// Stub class for non-web platforms.
///
/// On web, the real implementation is in `yjs_backend_web.dart`.
class YjsDocumentBackend extends DocumentBackend {
  /// Creates a backend bound to the given [doc].
  YjsDocumentBackend(YDoc doc, {String fieldName = 'content'}) {
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
}

/// Helper to create backend - kept for API compatibility.
DocumentBackend createYjsBackend({String? clientId}) {
  throw UnsupportedError(
    'YjsDocumentBackend is not supported on this platform.',
  );
}
