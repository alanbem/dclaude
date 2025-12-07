# dclaude

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Hub](https://img.shields.io/docker/v/alanbem/dclaude?label=Docker%20Hub)](https://hub.docker.com/r/alanbem/dclaude)
[![npm](https://img.shields.io/npm/v/@alanbem/dclaude)](https://www.npmjs.com/package/@alanbem/dclaude)

Run Claude Code CLI in Docker - no local installation needed. Full MCP support, persistent sessions, and seamless host integration.

## Why dclaude?

**Claude Code CLI is powerful, but installing it locally means:**
- Node.js version conflicts
- Global npm packages cluttering your system
- MCP servers needing specific Python/Node setups
- Different behavior across machines

**dclaude solves this by running Claude in a container that feels native:**
- Your files appear at the same paths (no `/app` or `/workspace` confusion)
- Docker commands work (socket is mounted)
- SSH keys and git config just work
- Install tools with Homebrew - they persist across sessions
- Same experience on Linux, macOS, and Windows

## Quick Start

### Install via NPM (Recommended)

```bash
npm install -g @alanbem/dclaude
dclaude
```

### Build from source

```bash
git clone https://github.com/alanbem/dclaude.git
cd dclaude
docker build -t alanbem/dclaude:local docker
chmod +x dclaude
./dclaude
```

## Basic Usage

```bash
# Start Claude interactively
dclaude

# Run with a prompt
dclaude "fix the bug in main.js"

# All Claude CLI flags work
dclaude --version
dclaude -p "explain this code"

# Execute commands in the container
dclaude exec npm install
dclaude exec brew install ripgrep
```

## How It Works

dclaude creates a container that mirrors your host environment:

1. **Path Mirroring**: Your current directory is mounted at the *exact same path*
   - On host: `/Users/alice/projects/myapp`
   - In container: `/Users/alice/projects/myapp`
   - All your file paths just work

2. **Docker Access**: The Docker socket is mounted, so Claude can build images, run containers, and manage compose stacks

3. **Persistent Sessions**: Containers persist by default - installed tools and configuration survive across sessions

4. **Smart Networking**: Auto-detects whether host networking is available for localhost access

## Persistent vs Ephemeral Containers

**Persistent (default)** - Container survives between sessions:
```bash
dclaude                           # Uses existing container or creates new one
dclaude exec brew install fd      # Install tools - they persist
dclaude exec                      # Open a shell in the container
```

**Ephemeral** - Fresh container each time:
```bash
DCLAUDE_RM=true dclaude          # Container removed after exit
```

Use persistent for development (faster startup, tools persist). Use ephemeral for CI/CD or when you want a clean slate.

## Features

### SSH Authentication

dclaude automatically handles SSH for git operations:

```bash
# Auto-detect best method (default)
dclaude

# Force SSH agent forwarding (most secure)
DCLAUDE_GIT_AUTH=agent-forwarding dclaude

# Mount ~/.ssh directory (most compatible)
DCLAUDE_GIT_AUTH=key-mount dclaude
```

Make sure your SSH key is loaded: `ssh-add -l`

### Homebrew Support

Install tools that persist across sessions:

```bash
dclaude exec brew install ripgrep fd bat jq
dclaude exec brew install node@20 python@3.12
```

### GitHub CLI

Authenticate once, use everywhere:

```bash
dclaude gh                        # Interactive GitHub login
dclaude exec gh pr list           # Use gh commands
```

### SSH Server for IDEs

Connect JetBrains Gateway, VS Code Remote, or any SSH client:

```bash
dclaude ssh                       # Start SSH server, shows port
# Connect: ssh claude@localhost -p <port>
# Password: claude
```

### Chrome DevTools Integration

Control Chrome via MCP for browser automation:

```bash
dclaude chrome                    # Launch Chrome with DevTools
dclaude                           # Claude can now interact with the browser
```

### Config Mounting

Mount your host configs for seamless tool integration:

```bash
DCLAUDE_MOUNT_CONFIGS=true dclaude
```

This mounts (read-only): `.docker/`, `.gitconfig`, `.config/gh/`, `.npmrc`

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DCLAUDE_RM` | `false` | Remove container on exit (ephemeral mode) |
| `DCLAUDE_TAG` | `latest` | Docker image tag |
| `DCLAUDE_NETWORK` | `auto` | Network mode: `auto`, `host`, `bridge` |
| `DCLAUDE_GIT_AUTH` | `auto` | SSH auth: `auto`, `agent-forwarding`, `key-mount`, `none` |
| `DCLAUDE_MOUNT_CONFIGS` | `false` | Mount host config files |
| `DCLAUDE_DEBUG` | `false` | Enable debug output |
| `DCLAUDE_QUIET` | `false` | Suppress info messages |
| `DCLAUDE_NO_UPDATE` | `false` | Skip image update check |
| `DCLAUDE_SYSTEM_CONTEXT` | `true` | Inform Claude about container environment |

## Networking

dclaude auto-detects the best networking mode:

**Host mode** (when available):
- Direct `localhost` access to host services
- Works on: Linux, macOS with OrbStack/Docker Desktop beta, Windows with Docker Desktop beta

**Bridge mode** (fallback):
- Use `host.docker.internal` instead of `localhost`
- Standard Docker networking

Force a specific mode:
```bash
DCLAUDE_NETWORK=host dclaude
DCLAUDE_NETWORK=bridge dclaude
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Full support | Host networking available |
| macOS | Full support | Host networking with OrbStack or Docker Desktop beta |
| Windows | Full support | WSL2/Docker Desktop, host networking with beta features |

## What's Included

The container includes:
- **Ubuntu 24.04 LTS** base
- **Claude Code CLI** (latest)
- **Node.js 20+**, **Python 3** with pip
- **Homebrew/Linuxbrew** for package management
- **Docker CLI** and **Docker Compose**
- **Git**, **GitHub CLI** (`gh`), common dev tools
- **tmux** for session management
- **SSH server** for IDE integration

## Troubleshooting

**Docker not running?**
```bash
# Make sure Docker Desktop is running, or on Linux:
sudo systemctl start docker
```

**Permission denied on Docker socket?**
```bash
# Linux: Add yourself to the docker group
sudo usermod -aG docker $USER
# Then logout and login
```

**Can't access localhost services?**
```bash
# Check what network mode is being used
DCLAUDE_DEBUG=true dclaude

# Try forcing host mode
DCLAUDE_NETWORK=host dclaude

# Or use host.docker.internal in bridge mode
```

**SSH keys not working?**
```bash
# Make sure your key is loaded
ssh-add -l

# If empty, load your key
ssh-add ~/.ssh/id_ed25519
```

**Installed tools disappearing?**
```bash
# Make sure you're using persistent mode (default)
# If you set DCLAUDE_RM=true, tools won't persist
dclaude exec brew install <tool>  # This persists
```

## Project Structure

```
.
├── dclaude                 # Launcher script (runs on host)
├── docker/
│   ├── Dockerfile          # Container image definition
│   ├── README.md           # Docker Hub documentation
│   ├── usr/local/bin/
│   │   └── docker-entrypoint.sh
│   └── home/claude/
│       └── .tmux.conf
├── .github/workflows/      # CI/CD (lint, scan, publish)
├── completions/            # Shell completions (bash, zsh)
├── Makefile                # Development commands
└── package.json            # NPM package config
```

## Development

```bash
# Build locally
make build

# Test
make test

# Use local image
DCLAUDE_TAG=local ./dclaude
```

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## License

MIT - see [LICENSE](LICENSE)

## Links

- [Docker Hub](https://hub.docker.com/r/alanbem/dclaude)
- [npm](https://www.npmjs.com/package/@alanbem/dclaude)
- [Issues](https://github.com/alanbem/dclaude/issues)
- [Discussions](https://github.com/alanbem/dclaude/discussions)
