const ResizeHandle = {
  mounted() {
    let startY = 0;
    let startHeight = 0;
    let isDragging = false;
    
    const terminalContainer = this.el.parentElement;
    
    const handleMouseDown = (e) => {
      isDragging = true;
      startY = e.clientY;
      startHeight = terminalContainer.offsetHeight;
      document.body.style.cursor = 'ns-resize';
      document.body.style.userSelect = 'none';
      e.preventDefault();
    };
    
    const handleMouseMove = (e) => {
      if (!isDragging) return;
      
      const deltaY = startY - e.clientY;
      const newHeight = startHeight + deltaY;
      
      // Clamp between 200 and 800 pixels
      const clampedHeight = Math.max(200, Math.min(800, newHeight));
      
      // Update the height locally for smooth dragging
      terminalContainer.style.height = `${clampedHeight}px`;
    };
    
    const handleMouseUp = (e) => {
      if (!isDragging) return;
      
      isDragging = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      
      // Send the final height to the server
      const deltaY = startY - e.clientY;
      const newHeight = startHeight + deltaY;
      const clampedHeight = Math.max(200, Math.min(800, newHeight));
      
      this.pushEvent('resize', { height: clampedHeight });
    };
    
    // Add event listeners
    this.el.addEventListener('mousedown', handleMouseDown);
    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    
    // Store cleanup function
    this.cleanup = () => {
      this.el.removeEventListener('mousedown', handleMouseDown);
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  },
  
  destroyed() {
    if (this.cleanup) {
      this.cleanup();
    }
  }
};

export default ResizeHandle;