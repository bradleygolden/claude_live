# Terminal PTY Bridge

This directory contains a Node.js script that bridges between Elixir and native PTY (pseudo-terminal) functionality.

## Setup

Before using the terminal feature, you need to install the node-pty dependency:

```bash
cd priv/terminal
npm install
```

## Dependencies

- `node-pty`: Provides native PTY bindings for creating terminal sessions

## How it works

The `pty_bridge.js` script communicates with Elixir via JSON messages over stdin/stdout, providing:
- Terminal spawning with configurable shell, size, and environment
- Data streaming between the PTY and Elixir
- Terminal resizing
- Process lifecycle management

This approach is necessary because PTY functionality requires native system calls that aren't available directly in the BEAM VM.