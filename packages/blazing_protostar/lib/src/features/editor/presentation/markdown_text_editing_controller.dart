import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/domain/parsing/markdown_parser.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/block_state.dart';
import 'package:blazing_protostar/src/features/editor/domain/backends/document_backend.dart';
import 'package:blazing_protostar/src/features/editor/domain/backends/in_memory_backend.dart';

class MarkdownTextEditingController extends TextEditingController {
  final MarkdownParser _parser;
  final DocumentBackend _backend;

  /// Flag to prevent re-entrancy when applying remote updates.
  bool _isApplyingRemoteUpdate = false;

  /// The internal list of blocks that make up the document.
  /// This is the source of truth for structured sync (CRDT).
  List<MarkdownBlock> _blocks = [];

  // Reactive State for the Toolbar
  final ValueNotifier<Set<String>> activeStyles = ValueNotifier({});

  /// WYSIWYG mode: when true, control characters (**, _, #, etc.) are hidden.
  /// This can be toggled at runtime.
  bool isWysiwygMode;

  DocumentNode? _lastParsedDocument;

  MarkdownTextEditingController({
    String? text,
    MarkdownParser parser = const MarkdownParser(),
    DocumentBackend? backend,
    Duration throttleDuration = const Duration(milliseconds: 16),
    this.isWysiwygMode = false,
  }) : _parser = parser,
       _backend = backend ?? InMemoryBackend(initialText: text ?? ''),
       super(text: text ?? backend?.text) {
    _blocks = _splitIntoBlocks(_backend.text);
    _backend.addListener(_onBackendChanged);
    addListener(_updateActiveStyles);
  }

  void _onBackendChanged() {
    // Sync text from backend to controller (remote update)
    if (value.text != _backend.text) {
      _isApplyingRemoteUpdate = true;
      _blocks = _splitIntoBlocks(_backend.text);
      value = value.copyWith(
        text: _backend.text,
        // Preserve selection or handle incoming remote selection in Phase 4
      );
      _isApplyingRemoteUpdate = false;
    }
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = value.text;
    super.value = newValue;

    // Only update backend if this is a LOCAL change
    if (newValue.text != oldText && !_isApplyingRemoteUpdate) {
      _blocks = _splitIntoBlocks(newValue.text);
      _applyDeltaToBackend(oldText, newValue.text);
    }
  }

  /// Computes a simple diff between [oldText] and [newText] and applies
  /// the minimal insert/delete operations to the backend.
  void _applyDeltaToBackend(String oldText, String newText) {
    // Find common prefix
    int commonPrefixLength = 0;
    final minLength = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (commonPrefixLength < minLength &&
        oldText[commonPrefixLength] == newText[commonPrefixLength]) {
      commonPrefixLength++;
    }

    // Find common suffix (after the prefix)
    int commonSuffixLength = 0;
    while (commonSuffixLength < (oldText.length - commonPrefixLength) &&
        commonSuffixLength < (newText.length - commonPrefixLength) &&
        oldText[oldText.length - 1 - commonSuffixLength] ==
            newText[newText.length - 1 - commonSuffixLength]) {
      commonSuffixLength++;
    }

    // Calculate the range that changed
    final deleteCount =
        oldText.length - commonPrefixLength - commonSuffixLength;
    final insertText = newText.substring(
      commonPrefixLength,
      newText.length - commonSuffixLength,
    );

    // Apply delete first, then insert
    if (deleteCount > 0) {
      _backend.delete(commonPrefixLength, deleteCount);
    }
    if (insertText.isNotEmpty) {
      _backend.insert(commonPrefixLength, insertText);
    }
  }

  /// Returns a read-only view of the current blocks.
  List<MarkdownBlock> get blocks => List.unmodifiable(_blocks);

  @override
  void dispose() {
    _backend.removeListener(_onBackendChanged);
    removeListener(_updateActiveStyles);
    activeStyles.dispose();
    super.dispose();
  }

  void _updateActiveStyles() {
    // 1. If we have no document, we can't check styles.
    if (_lastParsedDocument == null) return;

    // 2. Identify active styles at the current cursor position
    final newStyles = <String>{};
    final currentOffset = selection.baseOffset;

    if (currentOffset < 0) {
      if (activeStyles.value.isNotEmpty) activeStyles.value = {};
      return;
    }

    // Traverse the AST to find nodes spanning this offset.
    // Optimization: BlockParser sorts nodes by offset.
    // We can do a simple search.
    for (final node in _lastParsedDocument!.children) {
      if (node.start <= currentOffset && node.end >= currentOffset) {
        _collectStyles(node, currentOffset, newStyles);
        break; // Found the block, no need to check others (usually)
      }
    }

    // Update Notifier if changed
    // Sets equality check manually or rely on ValueNotifier?
    // ValueNotifier uses ==. Set equality defaults to Identity in Dart.
    // matchesCheck needed.
    if (!_areSetsEqual(activeStyles.value, newStyles)) {
      activeStyles.value = newStyles;
    }
  }

  bool _areSetsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void _collectStyles(Node node, int offset, Set<String> collected) {
    if (node is ElementNode) {
      if (node is! DocumentNode && node is! ParagraphNode) {
        // Add this node's type (e.g. 'bold', 'header')
        // Note: HeaderNode type?
        if (node is HeaderNode) collected.add('header');
        if (node is BoldNode) collected.add('bold');
        if (node is ItalicNode) collected.add('italic');
        if (node is LinkNode) collected.add('link');
        if (node is UnorderedListNode ||
            node is OrderedListNode ||
            node is ListItemNode) {
          collected.add('list');
        }
      }

      // Recurse into children
      for (final child in node.children) {
        if (child.start <= offset && child.end >= offset) {
          _collectStyles(child, offset, collected);
        }
      }
    }
  }

  void applyFormat(String type) {
    if (selection.baseOffset < 0) return;

    // 1. Inline Styles (Bold, Italic)
    if (type == 'bold' || type == 'italic') {
      final syntax = type == 'bold' ? '**' : '_';
      final len = syntax.length;

      if (selection.isCollapsed) {
        // Insert empty syntax: "**|**"
        final newText = text.replaceRange(
          selection.baseOffset,
          selection.baseOffset,
          '$syntax$syntax',
        );
        final newOffset = selection.baseOffset + len;

        value = value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
          composing: TextRange.empty,
        );
      } else {
        // Wrap selection: "**selection**"
        final range = selection;
        final selectedText = text.substring(range.start, range.end);
        final newText = text.replaceRange(
          range.start,
          range.end,
          '$syntax$selectedText$syntax',
        );
        final newOffset = range.end + (len * 2);

        value = value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
          composing: TextRange.empty,
        );
      }
    }
    // 2. Line Styles (Header, List)
    else if (type == 'header' || type == 'list') {
      final prefix = type == 'header' ? '# ' : '- ';
      // Find start of line
      final start = text.lastIndexOf(
        '\n',
        selection.baseOffset - 1,
      ); // -1 to handle being AT the newline
      final lineStart = start == -1 ? 0 : start + 1;

      // Insert prefix at line start
      final newText = text.replaceRange(lineStart, lineStart, prefix);

      // Adjust cursor
      final newOffset = selection.baseOffset + prefix.length;

      value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
        composing: TextRange.empty,
      );
    }
    // 3. Link
    else if (type == 'link') {
      // [text](url)
      // Simple version: Insert `[]()` and put cursor in `[]`? Or wrap?
      // Wrap: `[selection](url)`

      if (selection.isCollapsed) {
        const insert = '[text](url)';
        final newText = text.replaceRange(
          selection.baseOffset,
          selection.baseOffset,
          insert,
        );
        // Select "text" so user can overwrite? Start: +1. End: +5.
        // Or just move to end?
        // Let's select "text".
        final newSelection = TextSelection(
          baseOffset: selection.baseOffset + 1,
          extentOffset: selection.baseOffset + 5,
        );

        value = value.copyWith(
          text: newText,
          selection: newSelection,
          composing: TextRange.empty,
        );
      } else {
        final range = selection;
        final selectedText = text.substring(range.start, range.end);
        final insert = '[$selectedText](url)';
        final newText = text.replaceRange(range.start, range.end, insert);

        // Select "url" so user can overwrite?
        // Offset = range.start + 1 + selectedText.length + 2 ("text](").
        final urlStart = range.start + 1 + selectedText.length + 2;
        final urlEnd = urlStart + 3; // "url"

        value = value.copyWith(
          text: newText,
          selection: TextSelection(baseOffset: urlStart, extentOffset: urlEnd),
          composing: TextRange.empty,
        );
      }
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 1. Parse the current text
    final document = _parser.parse(text);
    _lastParsedDocument = document; // Cache for selection tracking

    // 2. Convert AST to TextSpans with Styling
    // We pass the "default" style (likely from TextField) as the base.
    return _renderNode(document, style ?? const TextStyle(), null);
  }

  TextSpan _renderNode(Node node, TextStyle currentStyle, Node? parent) {
    // Handle TextNode - special case for list items
    if (node is TextNode) {
      // If parent is ListItemNode and WYSIWYG mode, handle the marker
      if (isWysiwygMode && parent is ListItemNode) {
        final nodeText = node.text;
        // Match the list marker at start of text (e.g., "- " or "* " or "+ ")
        final markerMatch = RegExp(r'^([*+-])[ \t]+').firstMatch(nodeText);
        if (markerMatch != null) {
          final markerLength = markerMatch.end;
          final markerText = nodeText.substring(0, markerLength);
          final contentText = nodeText.substring(markerLength);

          return TextSpan(
            children: [
              // Render marker as zero-width (for offset alignment)
              TextSpan(
                text: markerText,
                style: currentStyle.copyWith(
                  fontSize: 0,
                  color: Colors.transparent,
                ),
              ),
              // Add visible bullet
              TextSpan(
                text: '• ',
                style: currentStyle.copyWith(color: Colors.grey.shade600),
              ),
              // Render remaining content normally
              TextSpan(text: contentText, style: currentStyle),
            ],
          );
        }
      }
      return TextSpan(text: node.text, style: currentStyle);
    }

    if (node is ElementNode) {
      final childrenSpans = <InlineSpan>[];

      // Calculate new style based on Node Type
      var newStyle = currentStyle;

      if (node is HeaderNode) {
        // Headers scale based on level
        final size = 24.0 - (node.level * 2.0); // Simple scaling
        newStyle = newStyle.copyWith(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: Colors.black87, // Phase 1 theme hardcoded
        );
      } else if (node is BoldNode) {
        newStyle = newStyle.copyWith(fontWeight: FontWeight.bold);
      } else if (node is ItalicNode) {
        newStyle = newStyle.copyWith(fontStyle: FontStyle.italic);
      } else if (node is LinkNode) {
        newStyle = newStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );
      } else if (node is EscapeNode) {
        newStyle = newStyle.copyWith(color: Colors.grey);
      }

      int currentPos = node.start;

      for (final child in node.children) {
        if (child.start > currentPos) {
          final gapText = text.substring(currentPos, child.start);
          if (isWysiwygMode) {
            // Zero-width rendering for control chars
            childrenSpans.add(
              TextSpan(
                text: gapText,
                style: currentStyle.copyWith(
                  fontSize: 0,
                  color: Colors.transparent,
                ),
              ),
            );
          } else {
            // Normal mode: show control chars in grey
            childrenSpans.add(
              TextSpan(
                text: gapText,
                style: currentStyle.copyWith(color: Colors.grey),
              ),
            );
          }
        }

        childrenSpans.add(_renderNode(child, newStyle, node));
        currentPos = child.end;
      }

      if (currentPos < node.end) {
        final gapText = text.substring(currentPos, node.end);
        if (isWysiwygMode) {
          // Zero-width rendering: control chars are present but invisible
          childrenSpans.add(
            TextSpan(
              text: gapText,
              style: currentStyle.copyWith(
                fontSize: 0, // Truly zero-width
                color: Colors.transparent,
              ),
            ),
          );
        } else {
          // Normal mode: show control chars in grey
          childrenSpans.add(
            TextSpan(
              text: gapText,
              style: currentStyle.copyWith(color: Colors.grey),
            ),
          );
        }
      }

      return TextSpan(children: childrenSpans);
    }

    return const TextSpan(text: "");
  }

  // --- Block-Awareness Helpers ---

  List<MarkdownBlock> _splitIntoBlocks(String text) {
    if (text.isEmpty) {
      return [MarkdownBlock(text: '', type: 'paragraph')];
    }

    final lines = text.split('\n');
    return lines.map((line) {
      // 1. Check for ATX Header
      final headerMatch = RegExp(r'^(#{1,6})(?:[ \t]+|$)').firstMatch(line);
      if (headerMatch != null) {
        return MarkdownBlock(
          text: line,
          type: 'header',
          metadata: {'level': headerMatch.group(1)!.length},
        );
      }

      // 2. Check for List Item
      final ulMatch = RegExp(r'^([*+-])([ \t]+|$)').firstMatch(line);
      if (ulMatch != null) {
        return MarkdownBlock(text: line, type: 'unordered_list');
      }

      // 3. Fallback: Paragraph
      return MarkdownBlock(text: line, type: 'paragraph');
    }).toList();
  }

  /// Maps a global character offset (0 to text.length) to a block index and local offset.
  ///
  /// Returns a Record `(int blockIndex, int localOffset)`.
  (int blockIndex, int localOffset) mapGlobalToLocalOffset(int globalOffset) {
    if (_blocks.isEmpty) return (0, 0);

    int currentOffset = 0;
    for (int i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      final blockEnd = currentOffset + block.length;

      // The offset is within this block's boundaries.
      // We check <= blockEnd because a cursor can be at the very end of a block.
      if (globalOffset <= blockEnd) {
        return (i, globalOffset - currentOffset);
      }

      // If we are exactly AT the newline between this block and the next:
      if (globalOffset == blockEnd + 1 && i < _blocks.length - 1) {
        // We treat the newline as being at localOffset == block.length?
        // Actually, if we are AT the newline, we are technically AFTER the block content.
        // For Y.js purposes, it's often cleaner to map to the start of the next block.
        return (i + 1, 0);
      }

      currentOffset += block.length + 1; // +1 for the newline
    }

    // Fallback to the very end of the last block
    return (_blocks.length - 1, _blocks.last.length);
  }
}
