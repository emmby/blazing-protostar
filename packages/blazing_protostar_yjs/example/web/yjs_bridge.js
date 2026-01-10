import * as Y from 'https://esm.sh/yjs@13.6.29';
import * as sync from 'https://esm.sh/y-protocols@1.0.6/sync';
import * as encoding from 'https://esm.sh/lib0@0.2.88/encoding';
import * as decoding from 'https://esm.sh/lib0@0.2.88/decoding';

const { Doc, UndoManager, encodeStateAsUpdate } = Y;

/**
 * Registry of active clients. 
 * Maps clientId (string) -> { doc, text, undoManager, isOnline, callback }
 */
const clients = new Map();

/**
 * BroadcastChannel for P2P synchronization.
 */
const bc = new BroadcastChannel('blazing-protostar-sync');

/**
 * Generates a deterministic integer hash from a string.
 */
const hashCode = (str) => {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0; // Convert to 32bit integer
  }
  return Math.abs(hash);
};

/**
 * Broadcasts a binary payload to all participants.
 */
const broadcast = (data) => {
  bc.postMessage(data);
  handleMessage({ data });
};

/**
 * Initiates the Yjs synchronization protocol.
 */
const sendSyncStep1 = (clientId, context) => {
  const encoder = encoding.createEncoder();
  sync.writeSyncStep1(encoder, context.doc);
  sync.writeUpdate(encoder, encodeStateAsUpdate(context.doc));
  broadcast({ senderId: clientId, payload: encoding.toUint8Array(encoder) });
};

/**
 * Main cross-client message handler.
 */
const handleMessage = (event) => {
  try {
    const { senderId, payload } = event.data;
    if (!payload) return;
    
    const payloadData = payload instanceof Uint8Array ? payload : new Uint8Array(payload);
    
    for (const [clientId, context] of clients) {
      if (context.isOnline && clientId !== senderId) {
        const decoder = decoding.createDecoder(payloadData);
        const encoder = encoding.createEncoder();
        let changed = false;
        
        while (decoding.hasContent(decoder)) {
          // readSyncMessage handles Step 1 (writes Step 2 to encoder), Step 2, and Updates.
          sync.readSyncMessage(decoder, encoder, context.doc, 'remote');
        }

        if (encoding.length(encoder) > 0) {
          broadcast({ senderId: clientId, payload: encoding.toUint8Array(encoder) });
        }
      }
    }
  } catch (err) {
    console.error(`[Bridge] Sync error:`, err);
  }
};

bc.onmessage = handleMessage;

/**
 * Bridge interface exposed to Flutter.
 */
window.YjsBridge = {
  registerClient: (clientId, callback) => {
    if (clients.has(clientId)) {
      clients.get(clientId).doc.destroy();
    }

    const doc = new Doc();
    // Deterministic clientID prevents clock collisions in tests.
    doc.clientID = hashCode(clientId);
    
    const text = doc.getText('markdown');
    const undoManager = new UndoManager(text, { trackedOrigins: new Set([clientId]) });
    
    const context = { doc, text, undoManager, isOnline: true, callback };
    clients.set(clientId, context);

    text.observe((event, transaction) => {
      if (transaction.origin === 'remote') {
        callback(text.toString());
      }
    });

    doc.on('update', (update, origin) => {
      if (context.isOnline && origin === clientId) {
        const encoder = encoding.createEncoder();
        sync.writeUpdate(encoder, update);
        broadcast({ senderId: clientId, payload: encoding.toUint8Array(encoder) });
      }
    });

    sendSyncStep1(clientId, context);
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
      console.log(`[Bridge] ${clientId} reconnected`);
      sendSyncStep1(clientId, context);
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
