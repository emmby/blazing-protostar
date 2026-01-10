import { Doc, UndoManager, applyUpdate, encodeStateAsUpdate } from 'https://cdn.jsdelivr.net/npm/yjs@13.6.29/+esm';

// Map of clientId -> { doc, text, undoManager, isOnline, callback }
const clients = new Map();

// Use BroadcastChannel for cross-client sync
const bc = new BroadcastChannel('blazing-protostar-sync');

// Helper to broadcast state
const broadcast = (data, transferable = []) => {
  // BroadcastChannel does not deliver to the same window.
  // We manually dispatch to our own onmessage handler to support 
  // multiple clients on the same page (Dual Editor test).
  bc.postMessage(data, transferable);
  
  // Create a fake event object to match bc.onmessage expectation
  handleMessage({ data });
};

const broadcastUpdate = (senderId, update) => {
  broadcast({ type: 'update', senderId, update: update.buffer }, [update.buffer]);
};

const broadcastSyncRequest = (senderId) => {
  broadcast({ type: 'sync-request', senderId });
};

// Listen for updates from other clients/tabs
const handleMessage = (event) => {
  const { type, senderId, update } = event.data;
  
  if (type === 'update') {
    const updateData = new Uint8Array(update);
    for (const [clientId, context] of clients) {
      if (context.isOnline && clientId !== senderId) {
        applyUpdate(context.doc, updateData, 'broadcast');
      }
    }
  } else if (type === 'sync-request') {
    // Someone wants our state. If we have online clients, send our full state.
    for (const [clientId, context] of clients) {
      if (context.isOnline && clientId !== senderId) {
        const state = encodeStateAsUpdate(context.doc);
        broadcastUpdate(clientId, state);
      }
    }
  }
};

bc.onmessage = handleMessage;

window.YjsBridge = {
  // Register a client with its own independent Doc
  registerClient: (clientId, callback) => {
    const doc = new Doc();
    const text = doc.getText('markdown');
    const undoManager = new UndoManager(text, { trackedOrigins: new Set([clientId]) });
    
    const context = {
      doc,
      text,
      undoManager,
      isOnline: true,
      callback
    };
    
    clients.set(clientId, context);

    // Initial sync: request state from anyone else
    broadcastSyncRequest(clientId);

    // Observe changes and notify Flutter
    text.observe((event, transaction) => {
      // If the change came from a remote sync (broadcast/initial-sync), notify Flutter
      if (transaction.origin === 'broadcast' || transaction.origin === 'initial-sync') {
        callback(text.toString());
      }
    });

    // Handle local updates -> Broadcast
    doc.on('update', (update, origin) => {
      // Only broadcast if we are online and it's a local transaction
      if (context.isOnline && origin === clientId) {
        broadcastUpdate(clientId, update);
      }
    });
  },

  unregisterClient: (clientId) => {
    const context = clients.get(clientId);
    if (context) {
      context.doc.destroy();
      clients.delete(clientId);
    }
  },

  setClientOnline: (clientId, isOnline) => {
    const context = clients.get(clientId);
    if (!context) return;
    
    const wasOffline = !context.isOnline;
    context.isOnline = isOnline;

    if (isOnline && wasOffline) {
      // Reconnected! 
      // 1. Request state from others
      broadcastSyncRequest(clientId);
      // 2. Broadcast our own state so others can merge OUR offline changes
      const state = encodeStateAsUpdate(context.doc);
      broadcastUpdate(clientId, state);
      
      // Also notify Flutter to refresh
      context.callback(context.text.toString());
    }
  },

  getText: (clientId) => {
    const context = clients.get(clientId);
    return context ? context.text.toString() : '';
  },

  insert: (clientId, position, text) => {
    const context = clients.get(clientId);
    if (!context) return;
    context.doc.transact(() => {
      context.text.insert(position, text);
    }, clientId);
  },

  delete: (clientId, position, count) => {
    const context = clients.get(clientId);
    if (!context) return;
    context.doc.transact(() => {
      context.text.delete(position, count);
    }, clientId);
  },

  undo: (clientId) => {
    const context = clients.get(clientId);
    if (!context) return;
    context.undoManager.undo();
    context.callback(context.text.toString());
  },

  redo: (clientId) => {
    const context = clients.get(clientId);
    if (!context) return;
    context.undoManager.redo();
    context.callback(context.text.toString());
  },

  canUndo: (clientId) => {
    const context = clients.get(clientId);
    return context ? context.undoManager.canUndo() : false;
  },

  canRedo: (clientId) => {
    const context = clients.get(clientId);
    return context ? context.undoManager.canRedo() : false;
  }
};
