# dclaude — Dockerized Claude Code

[![CI/CD](https://github.com/alanbem/dclaude/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/alanbem/dclaude/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Pulls](https://img.shields.io/docker/pulls/alanbem/dclaude)](https://hub.docker.com/r/alanbem/dclaude)
[![npm](https://img.shields.io/npm/v/@alanbem/dclaude)](https://www.npmjs.com/package/@alanbem/dclaude)

Run Claude Code CLI in Docker — no local installation needed. Full MCP support, persistent sessions, and seamless host integration.

## Why dclaude?

**Claude Code CLI is powerful, but installing it locally means:**
- MCP servers needing specific Python/Node setups
- Different behavior across machines
- Claude has access to your entire filesystem

**dclaude solves this by running Claude in a container that feels native:**
- **Safer `--dangerously-skip-permissions`** - container isolation means Claude can only access your project, not your whole system
- Your files appear at the same paths (no `/app` or `/workspace` confusion)
- Docker commands work (socket is mounted)
- SSH keys and git config just work
- Homebrew included - easy migration from local macOS setup
- Works on Linux, macOS, and Windows

## Quick Start

> **Prerequisite:** [Docker](https://docs.docker.com/get-docker/) must be installed and running.

### Install via NPM (Recommended)

```bash
npm install -g @alanbem/dclaude
dclaude
```

### Install from source

```bash
# Clone and install
git clone https://github.com/alanbem/dclaude.git ~/tools/dclaude
sudo ln -s ~/tools/dclaude/dclaude /usr/local/bin/dclaude

# Run (pulls image from Docker Hub automatically)
dclaude
```

> **First run:** The Docker image (~1GB) is pulled automatically on first launch. You'll be prompted to authenticate with your Anthropic account.

## Basic Usage

**dclaude passes all arguments directly to Claude CLI** - use it exactly as you would use `claude`:

```bash
# Start Claude interactively
dclaude

# Run with a prompt
dclaude "fix the bug in main.js"

# All Claude CLI flags work
dclaude --version
dclaude -p "explain this code"
dclaude --model sonnet
dclaude --resume

# Execute commands in the container
dclaude exec npm install
dclaude exec brew install ripgrep
```

## How It Works

dclaude creates a container that mirrors your host environment:

1. **Path Mirroring**: Your current directory is mounted at the *same path*
   ```
   Host:      /Users/alice/projects/myapp ──mount──> Container: /Users/alice/projects/myapp
   ```
   No `/app` or `/workspace` confusion — all your file paths just work

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

dclaude warns you if no keys are loaded and suggests `dclaude ssh keys` to load them automatically (see also [SSH Key and Server Management](#ssh-key-and-server-management)).

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

### Git Configuration

SSH agent forwarding provides authentication for git, but git also needs your identity (name/email) for commits. Use `dclaude git` to configure this:

```bash
dclaude git                       # Configure git name/email in container
```

This reads your host's `~/.gitconfig` and offers to copy the identity into the container's persistent volume.

### SSH Key and Server Management

Load SSH keys and start SSH server for JetBrains Gateway, VS Code Remote, or any SSH client (see also [SSH Authentication](#ssh-authentication)):

```bash
dclaude ssh                       # Load keys + start SSH server
dclaude ssh keys                  # Load SSH keys into agent
dclaude ssh server                # Start SSH server, shows port
dclaude ssh server --stop         # Stop SSH server
# Connect: ssh claude@localhost -p <port>
# Password: claude
```

### Chrome DevTools Integration

Control Chrome via MCP for browser automation. Chrome runs on the host with remote debugging; Claude connects from the container:

```bash
dclaude chrome                    # Launch Chrome with DevTools + create .mcp.json
dclaude chrome --port=9223        # Use custom debugging port
dclaude chrome --setup-only       # Create .mcp.json without launching Chrome
dclaude                           # Claude can now interact with the browser
```

Chrome profiles are stored per-project in `.dclaude.d/chrome/profiles/`. Customize with `DCLAUDE_CHROME_PROFILE`, `DCLAUDE_CHROME_PORT`, `DCLAUDE_CHROME_BIN`, and `DCLAUDE_CHROME_FLAGS`.

### AWS CLI Integration

AWS CLI v2 is pre-installed in the container. Configure how AWS credentials are provided:

```bash
# Auto (default): mounts ~/.aws from host if it exists, otherwise no config
dclaude

# Mount host's ~/.aws directory (read-write, shared with host)
DCLAUDE_AWS_CLI=mount dclaude

# Use isolated Docker volume (persists across container recreations)
DCLAUDE_AWS_CLI=volume dclaude

# No AWS config mounting
DCLAUDE_AWS_CLI=none dclaude
```

**Volume mode** provides isolated AWS config per namespace:

```bash
dclaude aws configure                  # Copy ~/.aws/config (profiles, regions) into container
dclaude aws login                      # Run 'aws login' in container
dclaude aws login --profile staging    # Login with specific profile
```

### iTerm2 Shell Integration

If you use iTerm2 on macOS, dclaude automatically enables [iTerm2 Shell Integration](https://iterm2.com/documentation-shell-integration.html):

- **Click URLs in output** - Opens in your Mac's browser
- **imgcat** - Display images inline in terminal
- **it2copy** - Copy to Mac clipboard from inside container
- **Marks** - Navigate between command prompts

This only activates when running in iTerm2. To disable:

```bash
DCLAUDE_ITERM2=false dclaude
```

### System Context

dclaude automatically tells Claude about its container environment so it can give better suggestions:

- **Network mode** - Whether `localhost` works or needs `host.docker.internal`
- **Docker access** - Whether Docker commands are available
- **SSH auth method** - How git authentication is configured
- **AWS CLI** - Whether and how AWS credentials are configured
- **Path mirroring** - That file paths match the host

This helps Claude understand its environment without you explaining it. Disable if needed:

```bash
DCLAUDE_SYSTEM_CONTEXT=false dclaude
```

## Container Management

```bash
# Session management
dclaude new                       # Start a new Claude session
dclaude attach <session>          # Reattach to a named tmux session
DCLAUDE_TMUX_SESSION=reviewer dclaude  # Start a named session

# Container lifecycle
dclaude stop                      # Stop container for current directory
dclaude rm                        # Remove container (add -f to force)

# Maintenance
dclaude pull                      # Pull latest Docker image
dclaude update                    # Update Claude CLI inside container
dclaude shell                     # Open a bash shell (alias for exec)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DCLAUDE_RM` | `false` | Remove container on exit (ephemeral mode) |
| `DCLAUDE_TAG` | `latest` | Docker image tag |
| `DCLAUDE_NAMESPACE` | (none) | Namespace for isolated credentials/config |
| `DCLAUDE_NETWORK` | `auto` | Network mode: `auto`, `host`, `bridge` |
| `DCLAUDE_GIT_AUTH` | `auto` | SSH auth: `auto`, `agent-forwarding`, `key-mount`, `none` |
| `DCLAUDE_MOUNT_ROOT` | (working dir) | Mount parent directory for sibling access |
| `DCLAUDE_DEBUG` | `false` | Enable debug output |
| `DCLAUDE_QUIET` | `false` | Suppress info messages |
| `DCLAUDE_NO_UPDATE` | `false` | Skip image update check |
| `DCLAUDE_SYSTEM_CONTEXT` | `true` | Inform Claude about container environment |
| `DCLAUDE_AWS_CLI` | `auto` | AWS config: `auto`, `mount`, `volume`, `none` |
| `DCLAUDE_TMUX_SESSION` | `claude-TIMESTAMP` | Custom tmux session name for concurrent sessions |
| `DCLAUDE_ITERM2` | `true` | Enable iTerm2 shell integration (only affects iTerm2) |

## Configuration File

Create a `.dclaude` file at your project root to configure dclaude for that directory tree:

```bash
# ~/projects/mycompany/.dclaude
NAMESPACE=mycompany
NETWORK=host
DEBUG=true
```

dclaude walks up the directory tree to find `.dclaude` files. Any dclaude session started from that directory or any subdirectory will use these settings.

**Supported variables:**

| Variable | Description |
|----------|-------------|
| `NAMESPACE` | Isolate credentials/config (see Namespace Isolation) |
| `NETWORK` | Network mode (`host`, `bridge`) |
| `GIT_AUTH` | Git auth mode |
| `MOUNT_ROOT` | Mount directory (relative to config file, or absolute path) |
| `DEBUG` | Enable debug output (`true`, `false`) |
| `CHROME_PORT` | Chrome DevTools port |
| `AWS_CLI` | AWS config mode (`mount`, `volume`, `none`) |

Config file variables are the unprefixed equivalents of `DCLAUDE_*` environment variables (e.g., `NAMESPACE` in `.dclaude` = `DCLAUDE_NAMESPACE` env var).

**Precedence:** Environment variables override `.dclaude` file settings.

## Namespace Isolation

Use namespaces to maintain completely separate environments with different credentials and settings.

**Use case:** You have both a personal Anthropic subscription and a company subscription. You want to keep them completely separate.

**Option 1: Using `.dclaude` file (recommended)**
```bash
# Create config at company project root
echo "NAMESPACE=mycompany" > ~/projects/mycompany/.dclaude

# Now any dclaude in that tree uses company credentials
cd ~/projects/mycompany/api/src
dclaude  # Uses mycompany namespace automatically
```

**Option 2: Using environment variable**
```bash
DCLAUDE_NAMESPACE=mycompany dclaude
```

**Option 3: Shell alias**
```bash
# Add to ~/.bashrc or ~/.zshrc
alias dclaude-work='DCLAUDE_NAMESPACE=mycompany dclaude'
```

Each namespace gets its own:
- Claude credentials and API key
- Claude settings and preferences
- Git configuration
- Container instance

## Mount Root (Parent Directory Access)

By default, dclaude only mounts the current working directory. Use `MOUNT_ROOT` to mount a parent directory, enabling access to sibling directories.

**Use case:** You're working in a subdirectory but need access to related projects:

```text
/Users/alan/projects/mycompany/
├── shared-libs/          # Common libraries
├── api-service/          # API backend
├── web-app/              # Frontend
└── infrastructure/
    └── terraform/        # ← You're here, but need access to siblings
```

**Option 1: Using `.dclaude` file (recommended)**
```bash
# Create config at the directory you want as mount root
echo "MOUNT_ROOT=." > ~/projects/mycompany/.dclaude

# Relative paths are resolved from config file's directory
echo "MOUNT_ROOT=.." > ~/projects/mycompany/subdir/.dclaude  # mounts mycompany/
```

**Option 2: Using environment variable**
```bash
# Relative path (from working directory)
DCLAUDE_MOUNT_ROOT=../.. dclaude

# Absolute path
DCLAUDE_MOUNT_ROOT=/Users/alan/projects/mycompany dclaude
```

Now Claude can see and work with all sibling directories while your working directory remains `terraform/`.

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
| Windows | Full support | Requires WSL2; host networking with Docker Desktop beta features |

## What's Included

The container includes:
- **Ubuntu 24.04 LTS** base
- **Claude Code CLI** (latest, AMD64 and ARM64/Apple Silicon)
- **Node.js 20+**, **Python 3** with pip
- **Homebrew/Linuxbrew** for package management
- **Docker CLI** and **Docker Compose**
- **Git**, **GitHub CLI** (`gh`), common dev tools
- **tmux** for session management
- **AWS CLI v2** for cloud operations
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

**Directories appear empty inside container? (OrbStack)**

This is a [known OrbStack 2.0.x bug](https://github.com/orbstack/orbstack/issues/2103) where VirtioFS caches stale directory entries. Directories that existed before upgrading to OrbStack 2.0 may appear empty inside the container.

```bash
# Fix: rename the directory to clear the cache
mv problematic-dir problematic-dir.tmp && mv problematic-dir.tmp problematic-dir

# Or restart OrbStack completely (clears all caches)
```

Upgrading to the latest OrbStack version may also help.

## Shell Completions

Tab completion is available for bash and zsh:

```bash
# Bash — add to ~/.bashrc
source "$(npm root -g)/@alanbem/dclaude/completions/dclaude.bash"

# Zsh — add to ~/.zshrc
source "$(npm root -g)/@alanbem/dclaude/completions/dclaude.zsh"

# Source install — use the repo path directly
source ~/tools/dclaude/completions/dclaude.bash
```

## Project Structure

```text
.
├── dclaude                 # Launcher script (runs on host)
├── docker/
│   ├── Dockerfile          # Container image definition
│   ├── README.md           # Docker Hub documentation
│   ├── usr/local/bin/
│   │   ├── docker-entrypoint.sh
│   │   ├── claude-launcher.sh
│   │   └── tmux-wrapper.sh
│   └── home/claude/
│       └── .tmux.conf
├── .github/workflows/      # CI/CD (lint, scan, publish)
├── completions/            # Shell completions (bash, zsh)
├── Makefile                # Development commands
└── package.json            # NPM package config
```

## Development

Want to modify dclaude? Build and test locally:

```bash
# Build local image
make build                    # Creates alanbem/dclaude:local

# Test
make test

# Use your local image
DCLAUDE_TAG=local dclaude
```

## Contributing

Contributions welcome! Submit a Pull Request.

## License

MIT - see [LICENSE](LICENSE)

## Links

- [Docker Hub](https://hub.docker.com/r/alanbem/dclaude)
- [npm](https://www.npmjs.com/package/@alanbem/dclaude)
- [Issues](https://github.com/alanbem/dclaude/issues)
- [Discussions](https://github.com/alanbem/dclaude/discussions)
