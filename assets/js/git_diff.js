export class DiffViewer {
  constructor() {
    this.container = null;
  }

  init(container) {
    this.container = container;
  }

  renderDiff(diff, fileName) {
    if (!this.container) return;
    
    const lines = diff.split('\n');
    const html = lines.map(line => this.formatDiffLine(line)).join('\n');
    
    this.container.innerHTML = `
      <div class="diff-viewer">
        <div class="diff-header text-xs text-gray-400 mb-2 pb-2 border-b border-gray-800">
          <span class="font-mono">${this.escapeHtml(fileName)}</span>
        </div>
        <pre class="text-xs font-mono overflow-x-auto">${html}</pre>
      </div>
    `;
  }

  formatDiffLine(line) {
    const escaped = this.escapeHtml(line);
    
    if (line.startsWith('+++') || line.startsWith('---')) {
      return `<span class="text-gray-500">${escaped}</span>`;
    } else if (line.startsWith('@@')) {
      return `<span class="text-cyan-500 font-bold">${escaped}</span>`;
    } else if (line.startsWith('+')) {
      return `<span class="text-green-400 bg-green-900/20">${escaped}</span>`;
    } else if (line.startsWith('-')) {
      return `<span class="text-red-400 bg-red-900/20">${escaped}</span>`;
    } else {
      return `<span class="text-gray-300">${escaped}</span>`;
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  clear() {
    if (this.container) {
      this.container.innerHTML = '';
    }
  }
}

export const DiffViewerHook = {
  mounted() {
    this.viewer = new DiffViewer();
    this.viewer.init(this.el);
    
    this.handleEvent("show_diff", ({ diff, file }) => {
      this.viewer.renderDiff(diff, file);
    });
  },
  
  destroyed() {
    if (this.viewer) {
      this.viewer.clear();
    }
  }
};