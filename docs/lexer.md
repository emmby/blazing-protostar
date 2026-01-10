# Lexer Implementation Plan

## Overview
This document outlines the technical design for the Lexer/Scanner based Markdown parsing strategy.

## Goal
To replace the regex-based parsing with a robust, state-aware Lexer that supports:
- Efficient styling (MVP)
- Scalability for future features (Code blocks, nested lists, etc.)
- A custom `TextEditingController` implementation.

## Architecture: Strict CommonMark Compliance
We have chosen to adhere to **Strict CommonMark Compliance**. This ensures our editor handles edge cases (nesting, precedence, ambiguioty) correctly and predictably, matching other standard editors.

### Two-Phase Parsing Strategy
To achieve strict compliance, we will adopt the standard two-phase strategy:
1.  **Block Parsing (Phase 1)**:
    -   **Approach: Incremental-Friendly (Line-Based)**
    -   We scans the document as a list of lines, maintaining state for each line.
    -   *Benefit*: Allows for future optimization where we only re-parse lines affected by an edit, rather than the entire document.
    -   Output: A tree of Block Nodes.
    -   *Key detail*: In this phase, inline text is kept as raw strings.
2.  **Inline Parsing (Phase 2)**:
    -   Walk through the leaf Block Nodes (like Paragraphs).
    -   Parse the raw text for "Inline" structures (Bold, Italic, Links, Code Spans).
    -   Output: A fully populated Abstract Syntax Tree (AST).

## Data Structure: Custom "Editor-First" AST
We will define our own AST nodes rather than wrapping an existing library.
-   **Reason**: Standard ASTs are often "lossy" (converting markdown to HTML) and discard whitespace or source positions.
-   **Requirement**: deep integration with `TextEditingController` requires exact `TextRange(start, end)` for *every* token, including syntax characters (like `**` or `#`).
-   **Node Structure**:
    ```dart
    abstract class Node {
      final int start;
      final int end;
      // ...
    }
    ```

## Testing Strategy
We will leverage the official **CommonMark Spec Tests**.
-   **Source**: `spec_tests.json` (approx. 600+ test cases).
-   **Method**:
    1.  Download `spec_tests.json` to `test/assets/`.
    2.  Implement a `AstToHtmlRenderer` (test-only) that converts our Custom AST back to HTML string.
    3.  Run data-driven tests: `expect(astToHtml(parse(input)), equals(output))`.
