# CommonMark Editor for Flutter

A simple, clean CommonMark editor designed for Flutter. This project aims to provide a lightweight yet powerful editing experience with minimal dependencies.

## Key Features

1.  **Direct Markdown Editing (Default)**
    -   Users edit Markdown text directly.
    -   Control characters (e.g., `**`, `#`) are visible.
    -   **Live Styling**: Even with control characters visible, the text is styled (e.g., bold text appears bold).

2.  **Markdown Toolbar**
    -   Standard CommonMark operations (Bold, Header, Italic, List, Link).
    -   Actions insert appropriate control characters into the text stream.
    -   **Configurable Positioning**:
        -   Can be placed as a fixed header (Top).
        -   Can be placed as a keyboard accessory or footer (Bottom).

3.  **Collaborative Editing (Optional)**
    -   Support for real-time collaboration via **Y.js**.
    -   **Block-Aware Sync**: Synchronizes the document as a structured tree of blocks for robust conflict resolution.
    -   **Presence**: Shows remote cursors and selections.
    -   *Details*: See [crdt.md](crdt.md) for technical requirements.

4.  **WYSIWYG Toggle**
    -   A toggleable mode that hides control characters while preserving styling.
    -   Allows users to see the rendered output without distraction ("Zen Mode").

5.  **Read-Only Mode**
    -   Disables editing capabilities.
    -   Useful for previews or displaying static content.

## Technical Architecture

### Core: Custom TextEditingController
To achieve the requirements with minimal dependencies, we will rely on a customized `TextEditingController`.
-   **Mechanism**: Override the `buildTextSpan` method.
-   **Data Strategy (Block-Aware)**: 
    -   The controller maintains a list of semantic **Blocks** (Paragraphs, Headers, etc.).
    -   This allows for high-performance updates and perfectly aligns with CRDT/Y.js synchronization requirements.
-   **Parsing Strategy (Lexer/Scanner)**:
    -   We use a lightweight **Lexer** to scan text and produce an AST.
    -   **Design Specs**: See [lexer.md](lexer.md) for the detailed architecture.
-   **Collaboration Bridge**: 
    -   Abstract `DocumentBackend` allows the editor to function as a standalone flat-string editor OR as a collaborative client by plugging in a Y.js provider.

## Detailed Specifications
-   [Lexer Specification](lexer.md) - Deep dive into parsing and AST strategy.
-   [CRDT & Collaboration](crdt.md) - Requirements for Y.js integration and block-awareness.

## Implementation Phases

### Phase 1: Core Editor & Styling Engine
*Goal: Establish a text input that recognizes and styles Markdown syntax while keeping characters visible.*
- **Acceptance Criteria**:
    -   [ ] Basic text input works.
    -   [ ] Typing `**bold**` renders the text in bold font.
    -   [ ] Typing `# Header` renders as a large heading.
    -   [ ] Performance is smooth for medium-sized documents.

### Phase 2: Toolbar & Integration
*Goal: Add interactive controls and ensure flexible placement.*
- **Acceptance Criteria**:
    -   [ ] Toolbar widget created (decoupled from the editor).
    -   [ ] Editor widget accepts a toolbar builder or can be composed with the toolbar.

### Phase 3: Block-Aware Controller (CRDT Prep)
*Goal: Refactor internals to support structured synchronization.*
- **Acceptance Criteria**:
    -   [ ] Controller refactored to manage a list of `MarkdownBlock` objects.
    -   [ ] Backwards compatibility for single-string usage.
    -   [ ] No regressions in typing UX.

### Phase 4: Y.js Integration
*Goal: Implement the collaborative editing bridge.*
- **Acceptance Criteria**:
    -   [ ] `YjsDocumentBackend` implemented.
    -   [ ] Real-time sync between two editors.
    -   [ ] Remote cursor rendering.

### Phase 5: The WYSIWYG Toggle (Masking)
*Goal: Implement the logic to hide control characters on demand.*
- **Acceptance Criteria**:
    -   [ ] Toggle switch works.
    -   [ ] When enabled, `**` and `#` disappear visually but structure remains.

## Future Roadmap (Post-v1.0)
-   **Full Theme Customizability**:
    -   Developers consuming this package must be able to customize ALL visual styling decisions (colors, text styles, syntax visibility opacity) via a theme or configuration object.
    -   *Rationale*: Ensures the editor can adapt to any design system.
