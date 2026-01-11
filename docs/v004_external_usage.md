# External Usage & Yjs Integration

## Goal
Enable `blazing-protostar` to be easily embedded in other Flutter applications and facilitate connection to a Yjs backend via `blazing_protostar_yjs`.

## Requirements
- [x] **Public API**: Expose `MarkdownEditor` and `MarkdownTextEditingController` with clean, documented exports.
- [x] **Configuration**: Ensure `MarkdownEditor` accepts configuration for toolbar, WYSIWYG settings, etc., matching internal capabilities.
- [x] **State Management**: Ensure `MarkdownTextEditingController` provides standard Flutter state listening (text, selection, isDirty).
- [x] **Yjs Integration**:
    - [x] Implement `blazing_protostar_yjs` as a sidecar package.
    - [x] Create `YjsDocumentBackend` that implements `DocumentBackend` from core.
    - [x] Expose `attachToDoc(YDoc doc)` in `blazing_protostar_yjs`.
    - [x] Ensure decoupling: Host app manages `YDoc` and Provider (Provider-Agnostic).

## Interview Questions & Answers
**1. Usage Context**
*   **Q:** How do you envision "other apps" consuming the editor?
*   **A:** Standard Flutter package import. The editor should be a widget library usable by any Flutter app, following standard Flutter conventions.

**2. Configuration**
*   **Q:** What kind of configuration options should be exposed to the host app?
*   **A:** Expose existing internal capabilities such as toolbar customization and WYSIWYG settings. The goal is to make current internal features available to the consuming package.

**3. Backend Connection**
*   **Q:** How should the editor connect to a Yjs backend?
*   **A:** **Provider-Agnostic**. The host app is responsible for creating the `Y.Doc` and connecting it to a provider (e.g., WebSocket, WebRTC). The `blazing_protostar_yjs` package will expose a method like `attachToDoc(YDoc doc)`, keeping the editor decoupled from the network layer.

**4. State Management**
*   **Q:** How should the editor expose its state to the parent app?
*   **A:** **Standard Flutter Patterns**. Use `TextEditingController` (specifically `MarkdownTextEditingController`) for state and listeners. No complex external state management (like Riverpod) should be forced on the host app.

