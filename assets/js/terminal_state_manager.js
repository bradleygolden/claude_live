const TerminalStateManager = {
  mounted() {
    // Handle loading state from localStorage
    this.handleEvent("load-terminal-state", () => {
      const savedState = localStorage.getItem('claude-terminal-state');
      
      if (savedState) {
        try {
          const state = JSON.parse(savedState);
          // Send the restored state back to the server
          this.pushEvent('restore-state', {
            expanded: state.expanded || false,
            height: state.height || 400,
            fullscreen: state.fullscreen || false
          });
        } catch (e) {
          console.error('Failed to parse terminal state:', e);
          // Send default state
          this.pushEvent('restore-state', {
            expanded: false,
            height: 400,
            fullscreen: false
          });
        }
      } else {
        // No saved state, use defaults
        this.pushEvent('restore-state', {
          expanded: false,
          height: 400,
          fullscreen: false
        });
      }
    });
    
    // Handle saving state to localStorage
    this.handleEvent("save-terminal-state", (state) => {
      try {
        localStorage.setItem('claude-terminal-state', JSON.stringify({
          expanded: state.expanded,
          height: state.height,
          fullscreen: state.fullscreen
        }));
      } catch (e) {
        console.error('Failed to save terminal state:', e);
      }
    });
  }
};

export default TerminalStateManager;