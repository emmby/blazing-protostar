import 'package:flutter/foundation.dart';

/// An abstract interface for document storage and synchronization.
///
/// This allows the [MarkdownTextEditingController] to remain agnostic
/// of the underlying storage mechanism (e.g., local string, Y.js CRDT).
abstract class DocumentBackend extends ChangeNotifier {
  /// The current full text of the document.
  String get text;

  /// Updates the entire document text.
  ///
  /// This is typically called when the local user types in the editor.
  void updateText(String newText);

  /// Closes any resources held by the backend.
  @override
  void dispose() {
    super.dispose();
  }
}
