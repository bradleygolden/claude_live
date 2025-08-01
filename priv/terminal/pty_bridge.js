#!/usr/bin/env node

const pty = require('node-pty');
const readline = require('readline');

// Create readline interface for communication with Elixir
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

let ptyProcess = null;

// Handle commands from Elixir
rl.on('line', (line) => {
  try {
    const command = JSON.parse(line);
    
    switch(command.type) {
      case 'spawn':
        if (ptyProcess) {
          ptyProcess.kill();
        }
        
        ptyProcess = pty.spawn(command.shell || process.env.SHELL || 'bash', [], {
          name: 'xterm-color',
          cols: command.cols || 80,
          rows: command.rows || 24,
          cwd: command.cwd || process.env.HOME,
          env: { ...process.env, ...command.env }
        });
        
        ptyProcess.onData(data => {
          process.stdout.write(JSON.stringify({
            type: 'data',
            data: Buffer.from(data).toString('base64')
          }) + '\n');
        });
        
        ptyProcess.onExit(({ exitCode, signal }) => {
          process.stdout.write(JSON.stringify({
            type: 'exit',
            exitCode,
            signal
          }) + '\n');
        });
        
        process.stdout.write(JSON.stringify({
          type: 'spawned',
          pid: ptyProcess.pid
        }) + '\n');
        break;
        
      case 'write':
        if (ptyProcess) {
          ptyProcess.write(Buffer.from(command.data, 'base64').toString());
        }
        break;
        
      case 'resize':
        if (ptyProcess) {
          ptyProcess.resize(command.cols, command.rows);
        }
        break;
        
      case 'kill':
        if (ptyProcess) {
          ptyProcess.kill();
          ptyProcess = null;
        }
        break;
    }
  } catch (e) {
    process.stderr.write(`Error: ${e.message}\n`);
  }
});

// Clean up on exit
process.on('exit', () => {
  if (ptyProcess) {
    ptyProcess.kill();
  }
});