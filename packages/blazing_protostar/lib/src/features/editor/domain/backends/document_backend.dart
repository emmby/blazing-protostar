import 'package:flutter/foundation.dart';

/// An abstract interface for document storage and synchronization.
///
/// This allows the [MarkdownTextEditingController] to remain agnostic
/// of the underlying storage mechanism (e.g., local string, Y.js CRDT).
abstract class DocumentBackend extends ChangeNotifier {
  /// The current full text of the document.
  String get text;

  /// Insert [text] at the given [position].
  void insert(int position, String text);

  /// Delete [count] characters starting at [position].
  void delete(int position, int count);

  /// Closes any resources held by the backend.
  @override
  void dispose() {
    super.dispose();
  }
}
