// Import vendored xterm libraries
import '../vendor/xterm.js';
import '../vendor/xterm-addon-fit.js';
import '../vendor/xterm-addon-web-links.js';

export const TerminalHook = {
  mounted() {
    console.log("Terminal hook mounted");
    this.terminal = new Terminal({
      cursorBlink: true,
      fontSize: 14,
      fontFamily: 'Menlo, Monaco, "Courier New", monospace',
      theme: {
        background: '#1a1a1a',
        foreground: '#d4d4d4',
        cursor: '#d4d4d4',
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
      }
    });

    // Add addons
    this.fitAddon = new FitAddon.FitAddon();
    this.terminal.loadAddon(this.fitAddon);
    this.terminal.loadAddon(new WebLinksAddon.WebLinksAddon());

    // Open terminal in the container
    const terminalElement = document.getElementById('terminal');
    console.log("Terminal element:", terminalElement);
    
    if (!terminalElement) {
      console.error("Terminal element not found!");
      return;
    }
    
    this.terminal.open(terminalElement);
    this.fitAddon.fit();
    
    // Focus the terminal after a small delay to ensure DOM is ready
    setTimeout(() => {
      console.log("Focusing terminal...");
      this.terminal.focus();
    }, 100);
    
    // Add click handler to focus terminal
    this.el.addEventListener('click', () => {
      console.log("Terminal clicked, focusing...");
      this.terminal.focus();
    });

    // Get initial size
    const cols = this.terminal.cols;
    const rows = this.terminal.rows;

    // Connect to backend
    this.pushEvent("connect", { cols, rows });

    // Handle input
    this.terminal.onData(data => {
      console.log("Terminal input:", data);
      this.pushEvent("input", { data });
    });

    // Handle resize
    this.resizeObserver = new ResizeObserver(() => {
      this.fitAddon.fit();
      const cols = this.terminal.cols;
      const rows = this.terminal.rows;
      this.pushEvent("resize", { cols, rows });
    });
    this.resizeObserver.observe(this.el);

    // Handle output from server
    this.handleEvent("terminal_output", ({ data }) => {
      console.log("Terminal output received:", data);
      // Data comes as a string, not an array
      this.terminal.write(data);
    });

    this.handleEvent("terminal_exit", ({ code }) => {
      this.terminal.write(`\r\n[Process exited with code ${code}]\r\n`);
    });

    this.handleEvent("terminal_closed", () => {
      this.terminal.write('\r\n[Terminal closed]\r\n');
    });
  },

  destroyed() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
    if (this.terminal) {
      this.terminal.dispose();
    }
  }
};