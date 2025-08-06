import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';
import { WebLinksAddon } from '@xterm/addon-web-links';

export class TerminalManager {
  constructor() {
    this.terminals = {};
    this.activeTerminalId = null;
    this.pushEvent = null;
  }

  setEventHandler(pushEventFn) {
    this.pushEvent = pushEventFn;
  }

  initTerminal(terminalId) {
    console.log('initTerminal called with:', terminalId);
    const container = document.getElementById(`terminal-${terminalId}`);
    if (!container) {
      console.error(`Terminal container not found for ${terminalId}`);
      return false;
    }

    // Clean up existing terminal
    if (this.terminals[terminalId]) {
      this.terminals[terminalId].dispose();
      delete this.terminals[terminalId];
    }

    // Create new terminal
    const terminal = new Terminal({
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

    // Add addons
    const fitAddon = new FitAddon();
    const webLinksAddon = new WebLinksAddon();
    
    terminal.loadAddon(fitAddon);
    terminal.loadAddon(webLinksAddon);

    // Open terminal
    console.log('Opening terminal in container:', container);
    terminal.open(container);
    console.log('Terminal opened successfully');
    
    // Store references
    this.terminals[terminalId] = terminal;
    terminal.fitAddon = fitAddon;

    // Set up event handlers
    terminal.onData((data) => {
      if (this.pushEvent) {
        this.pushEvent('input', { data, terminal_id: terminalId });
      }
    });

    terminal.onResize(({ cols, rows }) => {
      if (this.pushEvent) {
        this.pushEvent('resize', { cols, rows, terminal_id: terminalId });
      }
    });

    // Fit terminal to container
    fitAddon.fit();

    // Set up resize observer
    const resizeObserver = new ResizeObserver(() => {
      fitAddon.fit();
    });
    resizeObserver.observe(container);
    terminal.resizeObserver = resizeObserver;

    // Send connect event to server
    const cols = terminal.cols;
    const rows = terminal.rows;
    if (this.pushEvent) {
      this.pushEvent('connect', { cols, rows, terminal_id: terminalId });
    }

    setTimeout(() => {
      terminal.focus();
      terminal.scrollToBottom();
    }, 100);

    return true;
  }

  writeToTerminal(terminalId, data) {
    if (this.terminals[terminalId]) {
      const terminal = this.terminals[terminalId];
      if (terminal && !terminal.disposed) {
        terminal.write(data);
        terminal.scrollToBottom();
      }
    } else {
      console.warn(`Terminal ${terminalId} not found for output`);
    }
  }

  switchTerminal(terminalId, retryCount = 0) {
    console.log('switchTerminal called with:', terminalId, 'retry:', retryCount);
    
    // Hide all terminal containers
    document.querySelectorAll('.terminal-container').forEach(el => {
      el.style.display = 'none';
    });

    // Find or create the terminal container
    let containerDiv = document.getElementById(`terminal-container-${terminalId}`);
    
    if (!containerDiv) {
      console.log('Creating new terminal container:', terminalId);
      // Create the container if it doesn't exist
      const terminalsContainer = document.getElementById('terminals-container');
      if (terminalsContainer) {
        containerDiv = document.createElement('div');
        containerDiv.id = `terminal-container-${terminalId}`;
        containerDiv.className = 'terminal-container absolute inset-0';
        containerDiv.style.display = 'block';
        
        const terminalElement = document.createElement('div');
        terminalElement.id = `terminal-${terminalId}`;
        terminalElement.className = 'h-full w-full';
        
        containerDiv.appendChild(terminalElement);
        terminalsContainer.appendChild(containerDiv);
        
        console.log('Terminal container created successfully');
      } else {
        console.error('terminals-container not found!');
        return;
      }
    } else {
      containerDiv.style.display = 'block';
    }

    // Initialize terminal if it doesn't exist
    if (!this.terminals[terminalId]) {
      console.log('Initializing new terminal:', terminalId);
      this.initTerminal(terminalId);
    } else {
      console.log('Focusing existing terminal:', terminalId);
      // Fit existing terminal
      const terminal = this.terminals[terminalId];
      if (terminal.fitAddon) {
        terminal.fitAddon.fit();
      }
      terminal.focus();
    }

    this.activeTerminalId = terminalId;
  }

  closeTerminal(terminalId) {
    const terminal = this.terminals[terminalId];
    if (terminal) {
      // Clean up resize observer
      if (terminal.resizeObserver) {
        terminal.resizeObserver.disconnect();
      }
      
      // Dispose terminal
      terminal.dispose();
      delete this.terminals[terminalId];
    }
  }

  handleTerminalExit(terminalId) {
    const terminal = this.terminals[terminalId];
    if (terminal) {
      terminal.write('\r\n[Terminal exited]');
    }
  }

  handleTerminalClosed(terminalId) {
    const terminal = this.terminals[terminalId];
    if (terminal) {
      terminal.write('\r\n[Terminal closed]');
    }
  }

  destroy() {
    // Clean up all terminals
    Object.keys(this.terminals).forEach(terminalId => {
      this.closeTerminal(terminalId);
    });
    this.terminals = {};
    this.activeTerminalId = null;
  }
}