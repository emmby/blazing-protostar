# Blazing Protostar Yjs Example

This example demonstrates real-time collaborative Markdown editing using the `blazing_protostar_yjs` package with Y.js as the CRDT backend.

## Features

-   **Multi-Editor Sync**: Two editors on the same page that sync in real-time.
-   **Cross-Tab Sync**: Changes sync across browser tabs via `BroadcastChannel`.
-   **Offline Support**: Editors can go "offline" and sync changes when reconnected.
-   **Undo/Redo**: Integrated with Yjs `UndoManager` for collaborative undo.

## Running the Example

```bash
cd packages/blazing_protostar_yjs/example
flutter run -d chrome --web-port=8080
```

## Testing

Navigate to `http://localhost:8080/#/dual_editor_test` to run the convergence fuzz test, which verifies that concurrent edits across two editors always converge to the same state.
