# Phase 1: Core Editor Implementation Plan

## Goal
Implement a valid CommonMark lexer and a custom `TextEditingController` that renders styled markdown.

## Checklist

### 1. Setup & Foundations
- [ ] Initialize Project Structure (`lib/src/features/editor/...`)
- [ ] Define Custom AST Nodes (`TextNode`, `ElementNode`, `HeaderNode`, etc.) with `start`/`end` offsets.
- [ ] Download `spec_tests.json` into `test/assets/`.

### 2. Lexer Implementation (The Core)
- [ ] Implement `BlockParser` (Phase 1: Line scanning)
    - [ ] Identify Headers
    - [ ] Identify Lists
    - [ ] Identify Paragraphs
- [ ] Implement `InlineParser` (Phase 2: Text scanning)
    - [ ] Bold (`**`, `__`)
    - [ ] Italic (`*`, `_`)
    - [ ] Links (`[...] (...)`)
- [ ] Implement `MarkdownParser` (Facade that runs Block -> Inline).

### 3. Testing Harness
- [ ] Create `AstToHtmlRenderer` (Test utility).
- [ ] Create `spec_test.dart` that reads `test/assets/spec_tests.json` and runs the relevant cases.

### 4. UI Integration
- [ ] Create `MarkdownTextEditingController`.
- [ ] Override `buildTextSpan` to traverse our AST and apply styles.
- [ ] Implement "Strict Styling" logic (no partial matching).

### 5. Verification
- [ ] Pass >90% of CommonMark spec tests for supported features.
- [ ] Manual smoke test in the app.
