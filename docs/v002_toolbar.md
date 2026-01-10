# Phase 2: Toolbar & Interactivity ✅

**Goal**: Add interactive formatting controls and ensure flexible placement (Top/Bottom/Keyboard Accessory).

## 1. Requirement Gathering (Interview)

### Question 1: Toolbar Architecture
**Status**: Decided (Decoupled).
**Decision**: We will decouple the Toolbar from the Editor.
-   `MarkdownTextEditingController` will be the source of truth.
-   We will create a separate `MarkdownToolbar` widget that consumes the controller.
-   This allows `MarkdownToolbar` to be placed anywhere (e.g. `Column(children: [Expanded(Editor), Toolbar()])`).

### Question 2: Selection State & Button Highlighting
**Status**: Decided (Reactive).
**Decision**: The Controller will implement `ValueListenable<Set<MarkdownType>>` (or similar) to notify listeners of active styles. This ensures the Toolbar updates efficiently.

### Question 3: Insertion Logic (Empty Selection)
**Status**: Decided (Immediate Syntax).
**Decision**: Actions will immediately insert characters (e.g. `****`) and move cursor to the center.

### Question 4: Keyboard Shortcuts
**Status**: Decided (No).
**Decision**: Shortcuts are out of scope for Phase 2. We focus on touch interactions first.

## 2. Requirements Specification

### Architecture
-   **Decoupled**: `MarkdownToolbar` is a separate widget.
-   **State Management**: `MarkdownTextEditingController` exposes `ValueListenable<Set<MarkdownType>> selectionStats`.

### Features
1.  **Format Actions**:
    -   **Bold** (`**text**`)
    -   **Italic** (`*text*`)
    -   **Strikethrough** (`~~text~~`) - *Wait, simple MVP usually skips Strike? Phase 1 didn't implement Strike in parser. I will stick to Header/Bold/Italic/Link/List.*
    -   **Header** (`# text`)
    -   **Link** (`[text](url)`)
    -   **List** (`- text`)

2.  **Interaction Logic**:
    -   **Selection**: If text selected -> Wrap it.
    -   **No Selection**: Insert empty wrapper (`****`) and move cursor to middle.
    -   **Toggle**: Button highlights if cursor is inside that style.

### Deliverables
-   `ToolbarControllerMixin` (or extensions on the existing Controller).
-   `MarkdownToolbar` widget.
-   `MarkdownButton` widget.
-   Integration example in `main.dart`.
