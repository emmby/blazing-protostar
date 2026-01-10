import { Doc, UndoManager } from 'https://cdn.jsdelivr.net/npm/yjs@13.6.29/+esm';

const ydoc = new Doc();
const ytext = ydoc.getText('markdown');

// Map of clientId -> callback for multi-editor support
const callbacks = new Map();

// Set of all registered clientIds (used by UndoManager to track local changes)
const localOrigins = new Set();

// Create UndoManager - will track all local origins dynamically
const undoManager = new UndoManager(ytext, { trackedOrigins: localOrigins });

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
  // Don't broadcast updates from other tabs
  if (origin !== 'broadcast') {
    bc.postMessage(update);
  }
});

// Observe ytext for changes and notify all callbacks EXCEPT the originator
ytext.observe((event, transaction) => {
  const originClientId = transaction.origin;
  for (const [clientId, callback] of callbacks) {
    // Notify this callback only if the change came from a different client
    if (originClientId !== clientId) {
      callback(ytext.toString());
    }
  }
});

window.YjsBridge = {
  getText: () => ytext.toString(),

  // Register a client with a unique ID and callback
  registerClient: (clientId, callback) => {
    callbacks.set(clientId, callback);
    localOrigins.add(clientId);
  },

  // Unregister a client when disposed
  unregisterClient: (clientId) => {
    callbacks.delete(clientId);
    localOrigins.delete(clientId);
  },

  // Insert with clientId as origin
  insert: (clientId, position, text) => {
    ydoc.transact(() => {
      ytext.insert(position, text);
    }, clientId);
  },

  // Delete with clientId as origin
  delete: (clientId, position, count) => {
    ydoc.transact(() => {
      ytext.delete(position, count);
    }, clientId);
  },

  undo: (clientId) => {
    undoManager.undo();
    // Notify all callbacks after undo
    for (const [id, callback] of callbacks) {
      callback(ytext.toString());
    }
  },

  redo: (clientId) => {
    undoManager.redo();
    // Notify all callbacks after redo
    for (const [id, callback] of callbacks) {
      callback(ytext.toString());
    }
  },

  canUndo: () => undoManager.canUndo(),
  canRedo: () => undoManager.canRedo()
};
