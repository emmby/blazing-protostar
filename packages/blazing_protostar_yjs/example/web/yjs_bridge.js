import { Doc, UndoManager } from 'https://cdn.jsdelivr.net/npm/yjs@13.6.29/+esm';

const ydoc = new Doc();
const ytext = ydoc.getText('markdown');

// Create UndoManager for undo/redo support
// Track 'local' origin so we only undo user's own changes (not synced changes)
const undoManager = new UndoManager(ytext, { trackedOrigins: new Set(['local']) });

// Use BroadcastChannel for cross-tab sync (no server needed)
const bc = new BroadcastChannel('blazing-protostar-sync');

// Listen for updates from other tabs
bc.onmessage = (event) => {
  const update = new Uint8Array(event.data);
  import('https://cdn.jsdelivr.net/npm/yjs@13.6.29/+esm').then(Y => {
    Y.applyUpdate(ydoc, update, 'broadcast');
  });
};

// Broadcast local updates to other tabs
ydoc.on('update', (update, origin) => {
  if (origin !== 'broadcast') {
    bc.postMessage(update);
  }
});

let dartCallback = null;

// Observe ytext for non-local changes
ytext.observe((event, transaction) => {
  if (transaction.origin !== 'local' && dartCallback) {
    dartCallback(ytext.toString());
  }
});

window.YjsBridge = {
  getText: () => ytext.toString(),
  insert: (position, text) => {
    ydoc.transact(() => {
      ytext.insert(position, text);
    }, 'local');
  },
  delete: (position, count) => {
    ydoc.transact(() => {
      ytext.delete(position, count);
    }, 'local');
  },
  onUpdate: (callback) => {
    dartCallback = callback;
  },
  undo: () => {
    undoManager.undo();
    // Notify Dart that content changed
    if (dartCallback) {
      dartCallback(ytext.toString());
    }
  },
  redo: () => {
    undoManager.redo();
    // Notify Dart that content changed
    if (dartCallback) {
      dartCallback(ytext.toString());
    }
  },
  canUndo: () => undoManager.canUndo(),
  canRedo: () => undoManager.canRedo()
};
