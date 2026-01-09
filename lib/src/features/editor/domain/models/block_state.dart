/// Represents a single block of text in the Markdown editor.
///
/// This model is used by the [MarkdownTextEditingController] to maintain
/// a structured representation of the document, facilitating easier
/// synchronization with CRDTs like Y.js.
class MarkdownBlock {
  /// The raw text content of the block (excluding the trailing newline).
  String text;

  /// The semantic type of the block (e.g., 'paragraph', 'header', 'unordered_list').
  String type;

  /// Optional metadata for specific block types (e.g., header level).
  Map<String, dynamic> metadata;

  MarkdownBlock({
    required this.text,
    required this.type,
    this.metadata = const {},
  });

  /// The length of the raw text in this block.
  int get length => text.length;

  /// Creates a copy of this block with provided overrides.
  MarkdownBlock copyWith({
    String? text,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return MarkdownBlock(
      text: text ?? this.text,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'MarkdownBlock(type: $type, text: "$text")';
}
