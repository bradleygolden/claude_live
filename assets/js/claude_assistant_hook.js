import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';

const ClaudeAssistantTerminal = {
  mounted() {
    this.terminal = new Terminal({
      cursorBlink: true,
      fontSize: 14,
      fontFamily: 'Menlo, Monaco, "Courier New", monospace',
      theme: {
        background: '#000000',
        foreground: '#ffffff',
        cursor: '#ffffff',
        black: '#000000',
        red: '#cd3131',
        green: '#0dbc79',
        yellow: '#e5e510',
        blue: '#2472c8',
        magenta: '#bc3fbc',
        cyan: '#11a8cd',
        white: '#e5e5e5',
        brightBlack: '#666666',
        brightRed: '#f14c4c',
        brightGreen: '#23d18b',
        brightYellow: '#f5f543',
        brightBlue: '#3b8eea',
        brightMagenta: '#d670d6',
        brightCyan: '#29b8db',
        brightWhite: '#e5e5e5'
      },
      allowTransparency: true,
      convertEol: true,
      scrollback: 5000
    });

    this.fitAddon = new FitAddon();
    this.terminal.loadAddon(this.fitAddon);

    // Open terminal
    this.terminal.open(this.el);
    
    // Fit terminal to container and initialize
    setTimeout(() => {
      this.fitAddon.fit();
      const dimensions = this.fitAddon.proposeDimensions();
      if (dimensions) {
        // Initialize terminal
        this.pushEvent('init', {
          cols: dimensions.cols,
          rows: dimensions.rows
        });
      }
      // Focus the terminal
      this.terminal.focus();
    }, 50);

    // Handle terminal input
    this.terminal.onData((data) => {
      this.pushEvent('input', { data });
    });

    // Handle terminal output from server
    this.handleEvent('output', ({ data }) => {
      this.terminal.write(data);
    });

    // Handle resize
    const resizeObserver = new ResizeObserver(() => {
      if (this.fitAddon) {
        this.fitAddon.fit();
        const dimensions = this.fitAddon.proposeDimensions();
        if (dimensions) {
          this.pushEvent('terminal-resize', {
            cols: dimensions.cols,
            rows: dimensions.rows
          });
        }
      }
    });
    resizeObserver.observe(this.el);
    this.resizeObserver = resizeObserver;

    // Click to focus
    this.el.addEventListener('click', () => {
      this.terminal.focus();
      this.terminal.scrollToBottom();
    });
  },

  destroyed() {
    if (this.terminal) {
      this.terminal.dispose();
    }
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
  }
};

export default ClaudeAssistantTerminal;