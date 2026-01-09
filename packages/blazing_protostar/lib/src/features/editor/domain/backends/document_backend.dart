import 'package:flutter/foundation.dart';

/// An abstract interface for document storage and synchronization.
///
/// This allows the [MarkdownTextEditingController] to remain agnostic
/// of the underlying storage mechanism (e.g., local string, Y.js CRDT).
abstract class DocumentBackend extends ChangeNotifier {
  /// The current full text of the document.
  String get text;

  /// Updates the entire document text.
  void updateText(String newText);

  /// Updates the local user's selection in the backend for awareness.
  void updateSelection(int anchor, int head) {}

  /// Closes any resources held by the backend.
  @override
  void dispose() {
    super.dispose();
  }
}
