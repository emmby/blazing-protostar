import 'package:blazing_protostar/blazing_protostar.dart';

/// Creates a [DocumentBackend] that syncs with Y.js.
///
/// Platform-specific implementations handle the bridge to the JS engine.
DocumentBackend createYjsBackend() {
  throw UnsupportedError(
    'YjsDocumentBackend is not supported on this platform.',
  );
}
