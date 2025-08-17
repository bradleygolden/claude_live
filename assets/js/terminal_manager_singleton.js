import { TerminalManager } from './terminal'

class TerminalManagerSingleton {
  constructor() {
    if (TerminalManagerSingleton.instance) {
      return TerminalManagerSingleton.instance
    }
    
    this.manager = new TerminalManager()
    this.activeTerminalId = null
    this.pushEventHandlers = {}
    
    TerminalManagerSingleton.instance = this
  }
  
  static getInstance() {
    if (!TerminalManagerSingleton.instance) {
      TerminalManagerSingleton.instance = new TerminalManagerSingleton()
    }
    return TerminalManagerSingleton.instance
  }
  
  registerPushEventHandler(terminalId, handler) {
    this.pushEventHandlers[terminalId] = handler
  }
  
  initTerminal(terminalId, pushEventHandler) {
    // Register the push event handler for this specific terminal
    this.registerPushEventHandler(terminalId, pushEventHandler)
    
    // Set the event handler to route to the correct push handler
    this.manager.setEventHandler((event, data) => {
      const handler = this.pushEventHandlers[data.terminal_id || terminalId]
      if (handler) {
        handler(event, data)
      }
    })
    
    // Initialize the terminal
    const success = this.manager.initTerminal(terminalId)
    
    return success
  }
  
  focusTerminal(terminalId) {
    console.log('Focusing terminal:', terminalId, 'Current active:', this.activeTerminalId)
    
    // If it's already the active terminal, just ensure it has focus
    if (this.activeTerminalId === terminalId) {
      const terminal = this.manager.terminals[terminalId]
      if (terminal && !terminal.disposed) {
        terminal.focus()
        return
      }
    }
    
    // First, blur ALL terminals including textareas
    Object.keys(this.manager.terminals).forEach(id => {
      const terminal = this.manager.terminals[id]
      if (terminal && !terminal.disposed && id !== terminalId) {
        console.log('Blurring terminal:', id)
        terminal.blur()
        // Also blur the textarea directly
        if (terminal.textarea) {
          terminal.textarea.blur()
        }
      }
    })
    
    // Also blur any other xterm textareas on the page
    document.querySelectorAll('.xterm-helper-textarea').forEach(textarea => {
      textarea.blur()
    })
    
    // Now focus the requested terminal
    const terminal = this.manager.terminals[terminalId]
    if (terminal && !terminal.disposed) {
      this.activeTerminalId = terminalId
      
      // Multiple attempts to ensure focus
      terminal.focus()
      
      // Try again after a brief delay
      setTimeout(() => {
        if (this.activeTerminalId === terminalId && terminal && !terminal.disposed) {
          terminal.focus()
          
          // Direct textarea focus
          if (terminal.textarea) {
            terminal.textarea.focus()
            console.log('Textarea focused for', terminalId, 'Active element:', document.activeElement)
          }
        }
      }, 100)
    }
  }
  
  writeToTerminal(terminalId, data) {
    this.manager.writeToTerminal(terminalId, data)
  }
  
  handleTerminalExit(terminalId) {
    this.manager.handleTerminalExit(terminalId)
  }
  
  handleTerminalClosed(terminalId) {
    this.manager.handleTerminalClosed(terminalId)
  }
  
  closeTerminal(terminalId) {
    this.manager.closeTerminal(terminalId)
    delete this.pushEventHandlers[terminalId]
    if (this.activeTerminalId === terminalId) {
      this.activeTerminalId = null
    }
  }
}

export default TerminalManagerSingleton