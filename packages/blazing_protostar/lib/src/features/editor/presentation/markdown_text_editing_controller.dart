import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/domain/parsing/markdown_parser.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/block_state.dart';
import 'package:blazing_protostar/src/features/editor/domain/backends/document_backend.dart';
import 'package:blazing_protostar/src/features/editor/domain/backends/in_memory_backend.dart';
import 'node_renderer.dart';
import 'renderers/render_context.dart';
import 'renderers/header_node_renderer.dart';
import 'renderers/bold_node_renderer.dart';
import 'renderers/italic_node_renderer.dart';
import 'renderers/link_node_renderer.dart';
import 'renderers/escape_node_renderer.dart';
import 'renderers/directive_node_renderer.dart';
import 'renderers/element_node_renderer.dart';
import 'renderers/text_node_renderer.dart';

class MarkdownTextEditingController extends TextEditingController {
  final MarkdownParser _parser;
  final DocumentBackend _backend;
  final Map<Type, NodeRenderer> nodeBuilders;

  /// Combined map of node renderers (defaults + custom overrides)
  late final Map<Type, NodeRenderer> _nodeRenderers;

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

  /// Ghost text to display at cursor position for autocomplete suggestions.
  /// Set to null or empty string to hide.
  String? _ghostText;

  /// Public getter for ghost text
  String? get ghostText => _ghostText;

  DocumentNode? _lastParsedDocument;

  MarkdownTextEditingController({
    String? text,
    MarkdownParser parser = const MarkdownParser(),
    DocumentBackend? backend,
    Duration throttleDuration = const Duration(milliseconds: 16),
    this.isWysiwygMode = true,
    this.nodeBuilders = const {},
  }) : _parser = parser,
       _backend = backend ?? InMemoryBackend(initialText: text ?? ''),
       super(text: text ?? backend?.text) {
    _blocks = _splitIntoBlocks(_backend.text);
    _backend.addListener(_onBackendChanged);
    addListener(_updateActiveStyles);

    // Initialize _nodeRenderers with defaults, then apply custom overrides
    _nodeRenderers = {..._getDefaultRenderers(), ...nodeBuilders};
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
    else if (type == 'header') {
      // Find current heading level at cursor line
      final lineStart = _getLineStart(selection.baseOffset);
      final lineEnd = _getLineEnd(selection.baseOffset);
      final lineText = text.substring(lineStart, lineEnd);
      final headerMatch = RegExp(r'^(#{1,6})[ \t]+').firstMatch(lineText);
      final currentLevel = headerMatch?.group(1)?.length ?? 0;

      // Cycle: 0 -> 1 -> 2 -> 0
      final newLevel = currentLevel >= 2 ? 0 : currentLevel + 1;
      applyHeadingLevel(newLevel);
    } else if (type == 'list') {
      const prefix = '- ';
      // Find start of line
      final lineStart = _getLineStart(selection.baseOffset);

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

  /// Inserts [text] at the current cursor position or replaces the current selection.
  void insertAtCursor(String text) {
    if (selection.baseOffset < 0) return;

    final newText = this.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );

    final newOffset = selection.start + text.length;

    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );
  }

  int _getLineStart(int offset) {
    if (offset <= 0) return 0;
    if (offset > text.length) return text.length;
    final start = text.lastIndexOf('\n', offset - 1);
    return start == -1 ? 0 : start + 1;
  }

  /// Returns the end index of the line containing [offset].
  int _getLineEnd(int offset) {
    if (offset >= text.length) {
      return text.length;
    }
    final end = text.indexOf('\n', offset);
    return end == -1 ? text.length : end;
  }

  /// Applies a heading level (1-6) to the current line.
  /// If [level] is 0, removes any existing heading prefix (makes it "Normal").
  void applyHeadingLevel(int level) {
    if (selection.baseOffset < 0) return;

    final lineStart = _getLineStart(selection.baseOffset);
    final lineEnd = _getLineEnd(selection.baseOffset);
    final lineText = text.substring(lineStart, lineEnd);

    // Check for existing header prefix
    final headerMatch = RegExp(r'^(#{1,6})[ \t]+').firstMatch(lineText);
    final oldPrefixLength = headerMatch?.end ?? 0;

    // Build new prefix
    final newPrefix = level > 0 ? '${'#' * level} ' : '';

    // Replace old prefix with new
    final contentStart = lineStart + oldPrefixLength;
    final newText = text.replaceRange(lineStart, contentStart, newPrefix);

    // Adjust cursor
    final cursorAdjustment = newPrefix.length - oldPrefixLength;
    final newOffset = selection.baseOffset + cursorAdjustment;

    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newOffset.clamp(0, newText.length),
      ),
      composing: TextRange.empty,
    );
  }

  /// Returns the current heading level (0-6) at the cursor position.
  /// 0 means "Normal" (no heading).
  int getCurrentHeadingLevel() {
    if (selection.baseOffset < 0) return 0;

    final lineStart = _getLineStart(selection.baseOffset);
    final lineEnd = _getLineEnd(selection.baseOffset);
    final lineText = text.substring(lineStart, lineEnd);

    final headerMatch = RegExp(r'^(#{1,6})[ \t]+').firstMatch(lineText);
    return headerMatch?.group(1)?.length ?? 0;
  }

  /// Sets ghost text for autocomplete suggestions.
  /// Input will be automatically sanitized (newlines/tabs replaced with spaces,
  /// control characters stripped).
  void setGhostText(String? text) {
    if (text == null || text.isEmpty) {
      clearGhostText();
      return;
    }
    _ghostText = _sanitizeGhostText(text);
    notifyListeners();
  }

  /// Clears the current ghost text.
  void clearGhostText() {
    if (_ghostText == null) return;
    _ghostText = null;
    notifyListeners();
  }

  /// Sanitizes ghost text by replacing newlines and tabs with spaces,
  /// and stripping control characters.
  String _sanitizeGhostText(String text) {
    // Replace newlines and tabs with spaces
    var sanitized = text
        .replaceAll('\n', ' ')
        .replaceAll('\t', ' ')
        .replaceAll('\r', ' ');

    // Strip control characters (ASCII 0-31 except space) but preserve unicode/emoji
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F]'), '');

    return sanitized;
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
    final baseInlineSpan = _renderNode(
      context,
      document,
      style ?? const TextStyle(),
      null,
    );

    final TextSpan baseSpan;
    if (baseInlineSpan is TextSpan) {
      baseSpan = baseInlineSpan;
    } else {
      baseSpan = TextSpan(children: [baseInlineSpan]);
    }

    // 3. If ghost text exists, inject it at cursor position
    if (_ghostText != null &&
        _ghostText!.isNotEmpty &&
        selection.isValid &&
        selection.isCollapsed) {
      return _injectGhostText(context, baseSpan, style);
    }

    return baseSpan;
  }

  /// Injects ghost text at the cursor position by walking the TextSpan tree.
  TextSpan _injectGhostText(
    BuildContext context,
    TextSpan baseSpan,
    TextStyle? baseStyle,
  ) {
    final cursorOffset = selection.baseOffset;

    // Calculate ghost text style: theme-based color with 0.4 opacity
    final defaultColor =
        baseStyle?.color ??
        DefaultTextStyle.of(context).style.color ??
        Colors.black;
    final ghostStyle = (baseStyle ?? const TextStyle()).copyWith(
      // ignore: deprecated_member_use
      color: defaultColor.withOpacity(0.4),
    );

    // Walk the TextSpan tree and inject ghost text at cursor position
    return _injectGhostTextRecursive(baseSpan, cursorOffset, ghostStyle, 0);
  }

  /// Recursively walks TextSpan tree to find cursor position and inject ghost text.
  TextSpan _injectGhostTextRecursive(
    TextSpan span,
    int targetOffset,
    TextStyle ghostStyle,
    int currentOffset,
  ) {
    if (span.text != null) {
      // Handle text span (leaf node with text)
      final textLength = span.text!.length;
      final textEnd = currentOffset + textLength;

      if (targetOffset >= currentOffset && targetOffset <= textEnd) {
        final children = <InlineSpan>[];

        // Split text
        final beforeText = span.text!.substring(
          0,
          targetOffset - currentOffset,
        );
        final afterText = span.text!.substring(targetOffset - currentOffset);

        if (beforeText.isNotEmpty) {
          children.add(TextSpan(text: beforeText, style: span.style));
        }

        children.add(TextSpan(text: _ghostText, style: ghostStyle));

        if (afterText.isNotEmpty) {
          children.add(TextSpan(text: afterText, style: span.style));
        }

        if (span.children != null) {
          children.addAll(span.children!);
        }

        return TextSpan(children: children, style: span.style);
      }
      // If not in this text range, return unmodified
      return span;
    }

    // Handle container span
    final children = span.children ?? const [];
    final newChildren = <InlineSpan>[];
    int offset = currentOffset;
    bool injected = false;

    for (final child in children) {
      if (injected) {
        newChildren.add(child);
        continue;
      }

      if (child is TextSpan) {
        final childLen = _calculateSpanLength(child);
        final childEnd = offset + childLen;

        // Try to inject if cursor is covering this child
        if (targetOffset >= offset && targetOffset <= childEnd) {
          newChildren.add(
            _injectGhostTextRecursive(child, targetOffset, ghostStyle, offset),
          );
          injected = true;
          offset = childEnd;
          continue;
        }

        offset = childEnd;
        newChildren.add(child);
      } else {
        // WidgetSpan or other
        newChildren.add(child);
        // Assume length 1 for non-TextSpan (placeholder)
        // Adjust if your parser handles length differently for embedded widgets
        offset += 1;
      }
    }

    // Capture the case where cursor is at the very end of this container
    if (!injected && targetOffset == offset) {
      newChildren.add(TextSpan(text: _ghostText, style: ghostStyle));
      injected = true;
    }

    if (injected) {
      return TextSpan(children: newChildren, style: span.style);
    }

    return span;
  }

  /// Calculates the total text length of a TextSpan (including children).
  int _calculateSpanLength(TextSpan span) {
    int length = span.text?.length ?? 0;

    if (span.children != null) {
      for (final child in span.children!) {
        if (child is TextSpan) {
          length += _calculateSpanLength(child);
        }
      }
    }

    return length;
  }

  /// Checks if the node should be revealed based on cursor proximity.
  bool _shouldRevealNode(Node node) {
    // If no valid selection, don't reveal (unless we want some default behavior)
    if (selection.baseOffset == -1) return false;

    final cursor = selection.baseOffset;

    // Simple proximity: cursor within node boundaries
    // We might want to expand this slightly (e.g. +/- 1 char) in the future
    return cursor >= node.start && cursor <= node.end;
  }

  /// Instantiates and returns default node renderers.
  Map<Type, NodeRenderer> _getDefaultRenderers() {
    // Instantiate default renderer classes
    const headerRenderer = HeaderNodeRenderer();
    const boldRenderer = BoldNodeRenderer();
    const italicRenderer = ItalicNodeRenderer();
    const linkRenderer = LinkNodeRenderer();
    const escapeRenderer = EscapeNodeRenderer();
    const directiveRenderer = DirectiveNodeRenderer();
    const elementRenderer = ElementNodeRenderer();
    const textRenderer = TextNodeRenderer();

    // Return map with renderer calls that will receive context at render time
    // We'll wrap these to inject the RenderContext dynamically
    return {
      HeaderNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return headerRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      BoldNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return boldRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      ItalicNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return italicRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      LinkNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return linkRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      EscapeNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return escapeRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      InlineDirectiveNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return directiveRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      ParagraphNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return elementRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      UnorderedListNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return elementRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      OrderedListNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return elementRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      ListItemNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return elementRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      DocumentNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return elementRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
      TextNode: (context, node, style, isRevealed, [parent]) {
        final renderContext = _createRenderContext(context);
        return textRenderer.render(
          context,
          node,
          style,
          isRevealed,
          renderContext,
          parent: parent,
        );
      },
    };
  }

  /// Creates a RenderContext for the current render operation.
  RenderContext _createRenderContext(BuildContext context) {
    return RenderContext(
      text: text,
      isWysiwygMode: isWysiwygMode,
      renderChild: (node, style, parent) =>
          _dispatchRender(context, node, style, parent),
      shouldRevealNode: _shouldRevealNode,
    );
  }

  /// Main dispatcher that routes nodes to their registered renderers.
  /// This replaces the old _renderNode logic.
  InlineSpan _dispatchRender(
    BuildContext context,
    Node node,
    TextStyle currentStyle,
    Node? parent,
  ) {
    // Look up renderer for this node type
    final shouldRevealSelf = _shouldRevealNode(node);
    final renderer = _nodeRenderers[node.runtimeType];

    if (renderer != null) {
      return renderer(context, node, currentStyle, shouldRevealSelf, parent);
    }

    // Fallback for unknown node types
    return TextSpan(
      text: '[Unknown Node: ${node.runtimeType}]',
      style: currentStyle.copyWith(color: Colors.red),
    );
  }

  /// Public entry point for rendering nodes.
  /// Dispatches to the appropriate registered renderer.
  InlineSpan _renderNode(
    BuildContext context,
    Node node,
    TextStyle currentStyle,
    Node? parent,
  ) {
    return _dispatchRender(context, node, currentStyle, parent);
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
