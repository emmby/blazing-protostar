# Generic Directives Requirements

**Context:** We are building a collaborative markdown editor. We need to extend the markdown parser to support **Generic Inline Directives** (specifically "Text Directives"). This is required to support a new "Relationships" feature in the consuming app (resonant-bohr), where users will type `:child[123-id]` to link commitments.

**Goal:** Implement support for parsing and rendering Text Directives in the `blazing_protostar` package.

## Specification Checklist

### 1. Syntax & args
- **Decision:** Full Spec Compliance.
- **Format:** `:name[content](args){attributes}`
- **Detail:** The parser **MUST** parse `(args)` (like a link destination/title) and `{attributes}` (key-value pairs) if present.
  - Even if the MVP only renders the content, the AST node must capture these fields to avoid breaking changes later.
  - *Previous Constraint Overridden:* We are strictly supporting the full syntax pattern, not just the content form.

### 2. Content Parsing
- **Decision:** Follow the Spec.
- **Detail:** The content inside the brackets `:name[content]` must be **parsed as Inline Markdown**.
  - Example: `:child[**bold**]` -> `DirectiveNode(name: 'child', children: [BoldNode(...)])`.
  - This matches standard directive specifications (e.g., Talk.CommonMark, remark-directive).

### 3. Scope
- **Decision:** Inline Only (MVP).
- **Detail:** Support only **Text Directives** (single colon `:`).
  - Leaf Blocks (`::`) and Container Blocks (`:::`) are **OUT OF SCOPE** for this phase.
  - The parser should strictly look for the single colon syntax used inline.

### 4. Testing & Validation
- **Requirement:** Incorporate official test cases.
- **Action:** Find test cases for the generic directive extension and incorporate them into `test/assets/spec_tests.json` (or a sidebar file).
- **Goal:** Ensure strictly verified conformance.
- *Critical:* We must find test cases for the generic directive extension and incorporate them into our test suite.

## Implementation Phases

### Phase 1: Parsing Logic
**Goal:** Deeply integrate directive parsing into `InlineParser` and `InlineLexer`.
- [ ] **Lexer Update:** Add generic directive lexing to `InlineLexer`.
    - Recognize `:` trigger.
    - Parse `:name` (alphanumeric/hyphen/underscore).
    - Parse `[content]` (balanced brackets).
    - Parse `(args)` (balanced parens) - optional.
    - Parse `{attributes}` (balanced braces) - optional.
- [ ] **Parser Update:** Update `InlineParser` to handle the new tokens.
    - Recursively parse `[content]` as markdown nodes.
- [ ] **AST Node:** Create `InlineDirectiveNode`.
    - Fields: `name` (String), `children` (List<Node>), `args` (String?), `attributes` (Map/String?).
- **Acceptance Criteria:**
    - Test: `:foo[bar]` parses as `Directive(name='foo', children=[Text('bar')])`.
    - Test: `:foo[**bar**]` parses as `Directive(name='foo', children=[Bold('bar')])`.
    - Test: `:foo[bar](url){k=v}` parses gracefully (args/attrs captured).
    - Test: `::foo` or `:::foo` are treated as text (or ignored/fail gracefully).

### Phase 2: Widget Rendering
**Goal:** Allow consumers to render custom widgets for directives.
- [ ] **Builder Interface:** Define `DirectiveBuilder = Widget Function(BuildContext, DirectiveNode)`.
- [ ] **Registry:** Add `directiveBuilders` map to `MarkdownText` / `MarkdownEditor`.
- [ ] **Default Rendering:** If no builder is found, render the content children as standard inline markdown.
- **Acceptance Criteria:**
    - App can register `{'child': (ctx, node) => Chip(label: node.text)}`.
    - Rendering `:child[123]` displays the Chip.
    - Unregistered directives fall back to displaying their content text naturally.