# Phase 1: Core Editor & Styling Engine

## Goal
Establish a robust text editor that allows users to type Markdown and see "Live Styling" (syntax highlighting) while keeping all control characters (like `**`, `#`) visible.

## Scope
-   **Input**: A custom `TextEditingController` connected to a simpler Lexer.
-   **Output**: Rich Text with visible markdown syntax.
-   **Supported Elements (MVP)**:
    -   Headers (`#` to `######`)
    -   Bold (`**`, `__`)
    -   Italic (`*`, `_`)
    -   Links (`[text](url)`)
    -   Lists (`-`, `1.`)

## Key Technical Decisions
-   **Architecture**: Strict CommonMark compliance (Block -> Inline).
-   **Data Structure**: Custom "Editor-First" AST.
-   **State**: Incremental-friendly Line Parser.

## Styling Rules
-   **Intermediate States (Typing)**: **Strict**.
    -   Styling is ONLY applied when the syntax tag is fully closed and valid.
    -   *Rationale*: Prevents UI flickering and layout jumps while the user is actively thinking/typing.
-   **Syntax Visibility**: **Dimmed/Low Contrast**.
    -   Control characters (`**`, `#`, `[]`, `()`) will be rendered in a lower contrast color (e.g., `Colors.grey`) than the main content.
    -   *Rationale*: Reduces visual noise and emphasizes the content over the markup.
-   **Typography**: **Hybrid (Variable + Mono)**.
    -   **Body Text**: Variable width font (e.g., `Inter`, `Roboto`) for optimal reading flow.
    -   **Code/Technicals**: Monospace font (e.g., `JetBrains Mono`) for Code Blocks and Inline Code only.
    -   *Rationale*: Creates a premium "Writing App" feel rather than a "Text Editor" feel.

## Acceptance Criteria
1.  **Unit Tests (Correctness)**:
    -   The Parser passes >90% of relevant CommonMark spec tests (specifically for Headers, Emphasis, Links, and Lists).
    -   *Excluded*: HTML blocks and Images are out of scope for Phase 1.
2.  **Performance**:
    -   Typing latency is <16ms (60fps) on a 10,000 line document in Release mode.
3.  **Real-time Interaction**:
    -   User sees styles apply immediately upon typing the closing character of a tag (e.g., the final `*`).
4.  **Edge Cases**:
    -   Nested styles (e.g., `**bold _italic_**`) render correctly with proper precedence.
