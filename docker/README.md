# dclaude

Docker image for [dclaude](https://github.com/alanbem/dclaude) - Dockerized Claude Code CLI.

## What's Inside

**Base:** Ubuntu 24.04 LTS

**Claude Code CLI** - The official Anthropic CLI for Claude

**Languages & Runtimes:**
- Node.js 20.x - Required for Claude CLI and Node-based MCP servers
- Python 3 - For Python-based MCP servers
- Homebrew/Linuxbrew - Package manager for additional tools

**Development Tools:**
- Git, GitHub CLI (`gh`)
- Docker CLI & Compose - Container management from within
- Build essentials (gcc, make, etc.)

**Session Management:**
- tmux - Terminal multiplexing for persistent sessions
- tini - Proper init system for zombie process reaping
- SSH server - Remote access for IDEs (JetBrains Gateway, VS Code Remote)

**Utilities:**
- curl, wget, jq, nano, socat, gosu

## Why These Choices

- **Ubuntu over Alpine**: Better compatibility with Node.js native modules and MCP servers
- **Homebrew included**: Allows installing additional tools without rebuilding the image
- **Non-root user**: Security - runs as `claude` user with docker group membership
- **tini as init**: Prevents zombie process accumulation in long-running containers

## Documentation

Full usage documentation: **[github.com/alanbem/dclaude](https://github.com/alanbem/dclaude)**

## License

MIT
