import * as Y from 'https://cdn.jsdelivr.net/npm/yjs@13.6.29/+esm';

const ydoc = new Y.Doc();
const ytext = ydoc.getText('markdown');

window.YjsBridge = {
  getText: () => ytext.toString(),
  updateText: (text) => {
    // Basic sync for prototype: replace all.
    // Real implementation should use yjs-lib0's diffing.
    ydoc.transact(() => {
        const current = ytext.toString();
        if (current === text) return;
        ytext.delete(0, current.length);
        ytext.insert(0, text);
    });
  },
  onUpdate: (callback) => {
    ytext.observe(() => {
        callback(ytext.toString());
    });
  }
};
