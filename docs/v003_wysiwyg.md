# Phase 3: WYSIWYG Toggle Mode ✅

**Goal**: Implement a toggleable "Zen Mode" that hides Markdown control characters while preserving all applied styling, with intelligent reveal-on-proximity behavior.

## 1. Requirements Summary

### Core Behavior
-   **Default (WYSIWYG ON)**: Control characters are hidden; user sees styled text only.
-   **Reveal-on-Proximity**: Markers become visible when:
    1.  Cursor is **inside** a styled region (between opening/closing markers).
    2.  Cursor is **within 1-2 characters** outside a marker boundary.
-   **Paired Markers**: For `**...**`, `_..._`, `[text](url)`, etc., reveal *both* markers together.
-   **Block Elements**: For `#`, `-`, `1.`, reveal markers for the entire block while cursor is within.
-   **Nested Styles**: Reveal logic applies independently to each nesting level. Cursor inside inner style reveals inner + any enclosing outer styles.

### Toggle Mechanism
-   **API**: `MarkdownEditor(isWysiwygMode: bool)` or `ValueNotifier<bool>` for reactive control.
-   **Toolbar Button**: `code` icon with highlight/background when active (consistent with format buttons).
-   **State Ownership**: Editor widget owns state (presentation concern, not content).

### Editing Behavior
-   **Typing**: No escaping—Markdown parses naturally. Typing `**word**` creates bold.
-   **Boundary Behavior**: Solved by proximity reveal—user sees markers and positions cursor intentionally.
-   **Backspace/Delete**: Works naturally on visible characters.

### Selection & Clipboard
-   **Selection**: Dragging reveals any markers within the selection range (with fade animation).
-   **Copy**: Clipboard always contains raw Markdown (e.g., `**hello**`).

### Animation
-   Markers fade in/out over **~100-150ms** for a smooth, premium feel.

### Undo/Redo
-   Toggle is NOT undoable—purely a view preference.

---

## 2. Technical Architecture

### State Flow
```
┌─────────────────────────────────────────────────────────────┐
│                     MarkdownEditor                          │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │ isWysiwygMode   │───▶│ buildTextSpan() logic           │ │
│  │ (bool)          │    │ - Check cursor position vs AST  │ │
│  └─────────────────┘    │ - Render control chars zero-wd  │ │
│                         │ - Replace list markers w/ bullet│ │
│                         └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Technical Implementation Details (Updated)
- **Zero-Width Rendering**: Instead of filtering out control characters (which breaks cursor navigation and offsets), we render them with `fontSize: 0`, `letterSpacing: 0`, `wordSpacing: 0`, and `height: 0`. This keeps them in the render tree but invisible, ensuring `TextPainter` offsets match the buffer.
- **List Replacement**: For list markers (`- `, `1. `), we **replace** the marker text with a bullet string of the **exact same length** (e.g., `- ` becomes `• `). This is crucial for maintaining 1:1 buffer-to-visual mapping for cursor navigation.

### Key Components

1.  **`WysiwygState`** (or inline in Editor):
    -   Tracks `isWysiwygMode` boolean.
    -   Exposes `toggleWysiwyg()` method.
    -   Notifies listeners on change.

2.  **`buildTextSpan()` Enhancement**:
    -   Receives cursor position and AST.
    -   For each syntax node, determines visibility:
        -   If WYSIWYG OFF → always visible (current behavior).
        -   If WYSIWYG ON → check proximity/inside rules.
    -   Applies opacity animation for transitions.

3.  **`MarkerVisibilityCalculator`** (new helper):
    -   Input: cursor offset, AST nodes.
    -   Output: `Set<SyntaxNode>` of nodes whose markers should be visible.
    -   Logic: iterate all nodes, check if cursor is inside or within 1-2 chars of boundaries.

4.  **`MarkdownToolbar` Update**:
    -   Add WYSIWYG toggle button (code icon).
    -   Button receives `isWysiwygMode` state and `onToggle` callback.

---

## 3. MVP Scope

### Supported Elements (matching v001_core_editor.md)

| Category | Elements |
|----------|----------|
| **Inline** | Bold (`**`, `__`), Italic (`*`, `_`), Links (`[text](url)`) |
| **Block** | Headers (`#` to `######`), Lists (`-`, `1.`) |

### Deferred
-   Strikethrough (`~~`)
-   Inline code (`` ` ``)
-   Blockquotes (`>`)
-   Code blocks (`` ``` ``)
-   Multi-format clipboard (rich text + Markdown)
-   Accessibility (ARIA labels for screen readers)

---

## 4. Acceptance Criteria

### Phase 3a: Core Toggle & Rendering ✅
-   [x] `MarkdownEditor` accepts `isWysiwygMode` parameter.
-   [x] When `isWysiwygMode: true`, control characters are hidden by default.
-   [x] When `isWysiwygMode: false`, all control characters are visible (existing behavior).
-   [x] **Unit Test**: `buildTextSpan()` produces correct spans with/without WYSIWYG mode.
-   [x] **Zero-Width Implementation**: Control characters rendered with `fontSize: 0` etc. to preserve offsets.
-   [x] **List Handling**: Markers replaced with bullets of equal length.
-   [x] **Web Compatibility**: Verified no visual artifacts (extra spacing) on Web.

### Phase 3b: Reveal-on-Proximity
-   [ ] Cursor inside styled region → markers visible.
-   [ ] Cursor within 1-2 chars outside marker → markers visible.
-   [ ] Paired markers revealed together.
-   [ ] Block elements reveal markers for entire block.
-   [ ] Nested styles reveal independently per nesting level.
-   [ ] **Unit Test**: `MarkerVisibilityCalculator` returns correct nodes for various cursor positions.

### Phase 3c: Animation
-   [ ] Markers fade in/out over ~100-150ms.
-   [ ] No flickering during rapid cursor movement.
-   [ ] **Visual Test**: Manual verification of smooth transitions.

### Phase 3d: Selection Behavior
-   [ ] Dragging selection reveals markers within range.
-   [ ] Copy produces raw Markdown in clipboard.
-   [ ] **Integration Test**: Select styled text, copy, paste—Markdown preserved.

### Phase 3e: Toolbar Integration ✅
-   [x] WYSIWYG toggle button in `MarkdownToolbar`.
-   [x] Icon: `code` with highlight when active.
-   [x] Clicking toggles `isWysiwygMode`.
-   [x] **Widget Test**: Button presence and toggle behavior.

### Performance
-   [ ] Typing latency remains <16ms on 10,000-line document in Release mode.
-   [ ] Full AST check for visibility (optimize later if needed).

---

## 5. Implementation Phases

### Phase 3a: Core Toggle (Completed)
1.  Add `isWysiwygMode` parameter to `MarkdownEditor`.
2.  Modify `buildTextSpan()` to hide control characters using zero-width rendering.
3.  Implement Lists replacement strategy.
4.  Basic unit tests.

### Phase 3b: Reveal-on-Proximity (Est. 3-4 days)
1.  Create `MarkerVisibilityCalculator` helper.
2.  Integrate with `buildTextSpan()` to selectively reveal markers.
3.  Handle paired markers and block elements.
4.  Handle nested styles.
5.  Unit tests for visibility logic.

### Phase 3c: Animation (Est. 1-2 days)
1.  Add opacity animation state for each marker group.
2.  Trigger fade on visibility change.
3.  Tune timing (~100-150ms).

### Phase 3d: Selection & Clipboard (Est. 1 day)
1.  Extend visibility logic to include selection range.
2.  Verify copy produces raw Markdown (likely works by default).

### Phase 3e: Toolbar Integration (Completed)
1.  Add toggle button to `MarkdownToolbar`.
2.  Wire up state and callback.
3.  Widget tests.

---

## 6. Open Questions (Deferred)

-   **Accessibility**: Should WYSIWYG mode expose Markdown structure via ARIA? Needs research.
-   **Multi-format Clipboard**: Rich text + Markdown for cross-app pasting. Future enhancement.
