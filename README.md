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

3.  **WYSIWYG Toggle**
    -   A toggleable mode that hides control characters while preserving styling.
    -   Allows users to see the rendered output without distraction ("Zen Mode").

4.  **Read-Only Mode**
    -   Disables editing capabilities.
    -   Useful for previews or displaying static content.

## Technical Architecture

### Core: Custom TextEditingController
To achieve the requirements with minimal dependencies, we will rely on a customized `TextEditingController`.
-   **Mechanism**: Override the `buildTextSpan` method.
-   **Parsing Strategy (Lexer/Scanner)**:
    -   We will implement a lightweight **Lexer** to scan the text and produce a tailored stream of tokens (e.g., `Header`, `Bold`, `Text`, `CodeBlock`).
    -   **Why not Regex?**: While Regex is faster to start, it struggles with nested states (e.g., ignoring `**bold**` inside a code block). A Lexer allows us to maintain a simple state machine (`normal` -> `inCodeBlock` -> `normal`), ensuring robust handling of future complex elements.
-   **WYSIWYG Strategy**: When the toggle is active, we identify control characters (like `**`) and apply a style effectively hiding them (e.g., `fontSize: 0.1` or transparent color).
-   **Cursor Trade-off**: We accept that the cursor may "move blindly" over hidden characters for now.

## MVP Scope (Phase 1 & 2)

**Included Features:**
-   Headers (`#`, `##`, etc.)
-   Bold (`**`, `__`)
-   Italic (`*`, `_`)
-   Lists (Unordered `-`, `*` and Ordered `1.`)
-   Links (`[text](url)`)

**Excluded for MVP:**
-   Blockquotes (`>`)
-   Code Blocks (```)
-   Tables
-   Images (Inline rendering)

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
    -   [ ] Support for Top (Header) and Bottom (Footer/Accessory) placement.
    -   [ ] Buttons functioning: Bold, Italic, Header, List, Link.

### Phase 3: The WYSIWYG Toggle (Masking)
*Goal: Implement the logic to hide control characters on demand.*
- **Acceptance Criteria**:
    -   [ ] Toggle switch works.
    -   [ ] When enabled, `**` and `#` disappear visually but structure remains.
    -   [ ] Styling provided by `buildTextSpan` remains active.

### Phase 4: Read-Only & Polish
*Goal: Finalize modes and ensure stability.*
- **Acceptance Criteria**:
    -   [ ] Read-only mode prevents keyboard input.
    -   [ ] Editor can be embedded as a widget in other apps.
