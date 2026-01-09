# Phase 1: Core Editor Implementation Plan

## Goal
Implement a valid CommonMark lexer and a custom `TextEditingController` that renders styled markdown.

## Checklist

### 1. Setup & Foundations
- [x] Initialize Project Structure (`lib/src/features/editor/...`)
- [x] Define Custom AST Nodes (`TextNode`, `ElementNode`, `HeaderNode`, etc.) with `start`/`end` offsets.
- [x] Download `spec_tests.json` into `test/assets/`.

### 2. Lexer Implementation (The Core)
- [x] Implement `BlockParser` (Phase 1: Line scanning)
    - [x] Identify Headers
    - [x] Identify Lists
    - [x] Identify Paragraphs
- [x] Implement `InlineParser` (Phase 2: Text scanning)
    - [x] Bold (`**`, `__`)
    - [x] Italic (`*`, `_`)
    - [x] Links (`[...] (...)`)
    - [x] Escapes (`\`)
- [x] Implement `MarkdownParser` (Facade that runs Block -> Inline).

### 3. Testing Harness
- [x] Create `AstToHtmlRenderer` (Test utility).
- [x] Create `spec_test.dart` that reads `test/assets/spec_tests.json` and runs the relevant cases.

### 4. UI Integration
- [x] Create `MarkdownTextEditingController`.
- [x] Override `buildTextSpan` to traverse our AST and apply styles.
- [x] Implement "Strict Styling" logic (no partial matching).
- [x] Implement "Gap Filling" for visible syntax.

### 5. Verification
- [x] Pass >90% of CommonMark spec tests for supported features.
- [x] Manual smoke test in the app.

## Phase 2: Toolbar & Integration
*Goal: Add interactive controls.*

### 1. Controller Logic (Selection & Formatting)
- [ ] **Reactive Selection**: Update `MarkdownTextEditingController` to expose active styles.
- [ ] **Formatting Logic**: Implement methods to apply Bold/Italic/etc. (Wrap/Insert).
- [ ] **Unit Tests**: Verify selection detection and formatting helpers.

### 2. UI Components
- [ ] **MarkdownButton Widget**: Reusable, selectable button.
- [ ] **MarkdownToolbar Widget**: Row of buttons consuming the Controller.
- [ ] **Widget Tests**: Verify toolbar highlights based on Controller state.

### 3. Integration
- [ ] **Main Screen**: Assemble `Column(Editor, Toolbar)`.
- [ ] **Manual Verification**: Test touch interactions on simulator/web.
