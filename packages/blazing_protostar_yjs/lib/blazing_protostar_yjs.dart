/// Library export for the Yjs collaboration plugin.
library blazing_protostar_yjs;

import 'package:blazing_protostar/blazing_protostar.dart';
import 'src/platform/yjs_backend_stub.dart'
    if (dart.library.js_interop) 'src/platform/yjs_backend_web.dart';

export 'src/platform/yjs_backend_stub.dart'
    if (dart.library.js_interop) 'src/platform/yjs_backend_web.dart'
    show YjsDocumentBackend;

/// A [DocumentBackend] implementation that syncs with Y.js.
///
/// This class provides a clean Dart API, hiding the underlying JS interop
/// details from the consumer.
abstract class YjsBackend {
  /// Creates a [DocumentBackend] instance that uses Y.js for storage.
  ///
  /// On Web, this requires `yjs_bridge.js` to be loaded in the page.
  static DocumentBackend create() => createYjsBackend();
}
