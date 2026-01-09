# CRDT & Y.js Integration Requirements

## Topic: Enabling Collaborative Editing via Y.js Bindings

This document tracks the requirements and implementation phases for adding CRDT support (specifically Y.js) to the Flutter Markdown Editor.

---

## Technical Discussion & Decisions

### [Question 1: Target Y.js Implementation]
- **Status**: Research Required
- **Question**: Do you intend to use a native Dart CRDT implementation (like the `y_crdt` package which uses WASM) or bridge to JavaScript?
- **User Feedback**: Open to either, but noted previous difficulties with `y_crdt` regarding memory management (likely FFI/WASM disposal).
- **Decision**: We will investigate `y_crdt`'s current state and memory lifecycle requirements. If friction remains high, we may explore a JS-bridge or a pure-Dart alternative.

### [Question 2: Sync Granularity & Structure]
- **Status**: Decided (Structured Tree)
- **Question**: Should the CRDT sync the raw Markdown source string or a structured semantic representation?
- **Decision**: **Structured Tree**. We will sync block-level nodes (paragraphs, headers, lists) as separate entities (likely `Y.Map` inside a `Y.Array` or `Y.XmlFragment`).

### [Question 3: Remote Presence & Awareness]
- **Status**: Decided
- **Question**: How should remote user presence (cursors and selections) be rendered given that markdown syntax is visible?
- **Decision**: 
    - **Cursor**: Free movement (can be inside syntax markers).
    - **Selection**: Highlights cover syntax markers as well.
    - **Styling**: Colored vertical bars for cursors; light colored backgrounds for selections.

### [Question 4: Delta API / State Architecture]
- **Status**: Decided (Block-Aware Controller)
- **Question**: Given the **Structured Tree** sync model, how should the internal state be managed?
- **Decision**: **Option 2 (Block-Aware)**. The `MarkdownTextEditingController` will maintain a list of `BlockState` objects. Each maps to a `Y.Map` in the `YDoc`.

### [Question 5: Markdown-to-Y.js Mapping]
- **Status**: Pending (Proposed)
- **Question**: How do we sync Markdown syntax (like `> ` or `- `) with CRDT block types?
- **Proposal**: 
    - The `YDoc` represents the document as a `Y.Array<Y.Map>`.
    - Each `Y.Map` contains:
        - `text`: `Y.Text` (The raw characters, including syntax like `##` or `> `).
        - `type`: (String metadata like "header", "blockquote").
- **Decision**: **Text-as-Canonical-Source**. The raw string content in Y.js `text` properties is the source of truth for the parser. The `type` field is an optimization.

### [Question 6: Undo/Redo Strategy]
- **Status**: Decided
- **Question**: Y.js provides its own `UndoManager` which is CRDT-aware. Flutter's `TextField` also has built-in undo/redo. How should we handle this?
- **Decision**: **Intercept and Override**. We will disable Flutter's native undo/redo stack and map keyboard shortcuts (Cmd+Z / Cmd+Shift+Z) to the Y.js `UndoManager`.

### [Question 7: Inline Style Representation]
- **Status**: Decided (Option 1: Raw Sync)
- **Question**: Within a `Y.Text` block, should we use Y.js formatting attributes or rely solely on character sync?
- **Decision**: **Option 1: Raw Sync Only**.
    - **Rationale**: Since our editor keeps markdown syntax (e.g., `**`) visible and the Lexer uses these markers as the source of truth for styling, adding Y.js formatting attributes would create a "Dual Truth" problem. If the CRDT attributes and the text markers desync, the UI would become unpredictable.
    - **Risk Mitigation**: "Syntax shredding" (where concurrent edits break a marker pair) will be handled by the user re-typing the marker, or by future refinement of the diffing algorithm.

### [Question 8: Optionality & Architecture]
- **Status**: Decided
- **Question**: How do we ensure users who don't need CRDT aren't burdened by its complexity?
- **Decision**: **Bridge/Plugin Architecture**. The `MarkdownTextEditingController` will use an abstract `DocumentBackend` (or similar interface). The default backend will be a simple `String` buffer. CRDT support will be provided via a `YjsDocumentBackend` that users can optionally pass to the controller.

---

---

## Implementation Phases

### Phase 1: Controller Refactor (Block-Awareness)
- **Goal**: Transition from a single string source to a block-list-backed controller.
- **Acceptance Criteria**: 
    - [ ] `MarkdownTextEditingController` manages an internal list of `MarkdownBlock` objects.
    - [ ] The `text` property is dynamically computed from these blocks.
    - [ ] Selection and Cursor logic correctly maps from flat indices to block + local-offset.
    - [ ] Unit tests verify that normal typing/editing behaves identically to the current flat implementation.

### Phase 2: Bridge Architecture (Optionality)
- **Goal**: Introduce the `DocumentBackend` abstraction.
- **Acceptance Criteria**:
    - [ ] Define `abstract class DocumentBackend` with methods for `insert`, `delete`, `updateType`.
    - [ ] Implement `InMemoryDocumentBackend` (default).
    - [ ] Refactor formatting actions (`applyFormat`) to use the backend instead of direct string manipulation.

### Phase 3: Y.js Integration (The YjsBackend)
- **Goal**: Implement the Y.js bridge.
- **Acceptance Criteria**:
    - [ ] Research/Implement `YjsDocumentBackend` (using `y_crdt` or JS-bridge).
    - [ ] Remote operations from `YDoc` update the Controller's blocks without losing local focus.
    - [ ] Local operations update the `YDoc`.
    - [ ] Verification via a hidden "Collaborative Debug View" (two editors side-by-side).

### Phase 4: Presence & Presence UI
- **Goal**: Synchronize cursors and render them.
- **Acceptance Criteria**:
    - [ ] `Y.Awareness` state is integrated into the backend.
    - [ ] `MarkdownEditor` renders custom painters for remote cursors and selections.
    - [ ] User identifications (colors/names) appear correctly.

### Phase 5: Undo/Redo & Polish
- **Goal**: Hook into Y.js UndoManager and refine performance.
- **Acceptance Criteria**:
    - [ ] `ShortcutManager` intercepts Cmd+Z and routes to `backend.undo()`.
    - [ ] Performance testing on 100+ blocks in a collaborative session.
