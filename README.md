# Dockerized Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Status: Development](https://img.shields.io/badge/Status-Development-yellow)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)

Run Claude Code CLI in a Docker container with full MCP (Model Context Protocol) support and host environment emulation.

> **🚧 Development Status**: This project is in active development. NPM and Docker Hub publishing coming soon. Currently requires local building.

## Features

- 🐳 **Fully Containerized**: Run Claude CLI without local installation
- 🔧 **Docker Access**: Mount Docker socket for container management from Claude
- 📁 **Path Mirroring**: Seamless file access between host and container
- 🔌 **MCP Support**: Full Node.js and Python environments for MCP servers
- 🔒 **Isolated Environment**: Persistent data in Docker volumes
- 🌍 **Cross-Platform**: Works on Linux, macOS, and Windows (with Docker)
- 🚀 **Auto-Updates**: Automatic image updates on launch
- 🌐 **Smart Networking**: Auto-detects optimal networking mode for localhost access
- 🔑 **Config Mounting**: Optional mounting of host SSH keys, Git config, and tool authentication
- 🍺 **Homebrew Support**: Full Homebrew/Linuxbrew integration for package management
- 💾 **Persistent Containers**: Optional container persistence for development environments
- 🔌 **Direct Shell Access**: Execute commands directly in containers via exec subcommand

## Prerequisites

- Docker Desktop installed and running (Docker Engine 20.10+ recommended)
- Git (for cloning the repository)
- Claude API key (from [Anthropic Console](https://console.anthropic.com/))

## Quick Start

### Option 1: Build Locally (Currently Required)

```bash
# Clone the repository
git clone https://github.com/alanbem/dclaude.git
cd dclaude

# Build the Docker image
docker build -t alanbem/dclaude:latest .

# Make the launcher script executable
chmod +x dclaude

# Run dclaude
./dclaude

# (Optional) Install globally
sudo cp dclaude /usr/local/bin/
```

### Option 2: Install via NPM (Coming Soon)

```bash
# Note: Package will be published to NPM registry soon
npm install -g @alanbem/dclaude
dclaude
```

### Option 3: Use Docker Directly

```bash
# After building the image locally
docker run --rm -it \
  -v "$(pwd):$(pwd)" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w "$(pwd)" \
  alanbem/dclaude
```

## Usage

### Basic Commands

```bash
# Start Claude interactively (ephemeral)
dclaude

# Run Claude with a prompt
dclaude "fix the bug in main.js"

# All arguments pass directly to Claude CLI
dclaude --version  # Shows Claude's version
dclaude --help     # Shows Claude's help
dclaude -p "prompt" # Claude's print mode

# Enable debug mode
DCLAUDE_DEBUG=true dclaude

# Skip image updates (faster startup)
DCLAUDE_NO_UPDATE=true dclaude

# Force specific networking modes via environment
DCLAUDE_NETWORK=host dclaude   # Force host networking
DCLAUDE_NETWORK=bridge dclaude # Force bridge networking
```

### Persistent Containers

Create containers that persist between sessions:

```bash
# Create a persistent container
DCLAUDE_RM=false dclaude

# Reuse the same container (automatically detected)
DCLAUDE_RM=false dclaude

# Execute commands directly in the container
dclaude exec                    # Open bash shell
dclaude exec npm install        # Run npm command
dclaude exec brew install git   # Install tools with Homebrew

# Back to ephemeral mode (default)
dclaude
```

**When to use persistent containers:**
- Installing tools that should persist (Homebrew packages, global npm modules)
- Development environments that need setup (databases, services)
- Faster startup times (no container recreation)
- Preserving system-level changes

**Ephemeral vs Persistent:**
- **Ephemeral (default)**: `DCLAUDE_RM=true` - Container removed after exit
- **Persistent**: `DCLAUDE_RM=false` - Container reused across sessions

### How dclaude Works

#### Host Emulation
dclaude creates a containerized environment that closely emulates your host system:

1. **Path Mirroring**: Your current directory is mounted at the exact same path inside the container
   - If you're in `/Users/alice/projects/myapp` on the host
   - Claude sees and works in `/Users/alice/projects/myapp` inside the container
   - This preserves all relative and absolute path references

2. **Docker Access**: The container can control Docker on your host
   - Docker socket (`/var/run/docker.sock`) is mounted into the container
   - Claude can build images, run containers, and manage Docker Compose stacks
   - Example: `dclaude "build and run the Dockerfile in this directory"`

3. **Smart Network Detection**:
   - **Auto-Detection**: Automatically determines the best networking mode
   - **Host Mode**: Full localhost access when platform supports it
   - **Bridge Mode**: Fallback with limited localhost access
   - **Caching**: Network capability cached for 24 hours for faster startup
   - **Override Options**: Environment variables to force specific modes

4. **Persistent Data**: Configuration and cache stored in Docker volumes
   - `dclaude-claude`: Claude-specific data (API keys, session state)
   - Data persists between container runs regardless of mode

5. **Flexible Container Modes**: Choose between ephemeral or persistent containers
   - **Ephemeral (default)**: Fresh container each run, auto-removed on exit
     - Clean slate every time
     - System packages not preserved
     - Best for quick tasks and CI/CD
   - **Persistent** (`DCLAUDE_RM=false`): Reusable containers per directory
     - Container persists and can be restarted
     - Installed tools (Homebrew, npm packages) preserved
     - Faster startup (no container recreation)
     - Best for development environments

#### Path Mirroring Explained

The path mirroring system ensures seamless file access:

```bash
# Example: You're working on a project
cd /Users/alice/projects/website
dclaude "review index.html"

# What happens:
# 1. dclaude detects your current path: /Users/alice/projects/website
# 2. Mounts this directory at the same path in container
# 3. Sets container's working directory to /Users/alice/projects/website
# 4. Claude can access all files as if running natively
```

This means:
- All file paths work exactly as expected
- No need to translate paths between host and container
- Git commands work normally (sees correct paths)
- Build tools find dependencies in expected locations

#### Docker Host Access

dclaude can manage Docker on your host system:

```bash
# Claude can see your running containers
dclaude "list all running Docker containers"

# Claude can build and run Docker images
dclaude "create a Dockerfile for this Node.js app and run it"

# Claude can manage Docker Compose
dclaude "bring up the docker-compose stack and check for errors"

# Claude can debug container issues
dclaude "why is my nginx container failing to start?"
```

**Security Note**: Docker socket access grants significant privileges. Only use in trusted environments.

### Authentication Setup

To use Claude CLI, you need to authenticate:

1. Run dclaude for the first time:
   ```bash
   dclaude
   ```

2. When prompted, use the `/login` command to authenticate with your API key

3. Your credentials are securely stored in the `dclaude-claude` Docker volume and persist between sessions

### Networking Modes

dclaude automatically detects the best available networking mode for your platform, providing seamless localhost access when possible.

#### Auto-Detection Process

1. **Platform Detection**: Identifies your operating system
2. **Capability Testing**: Tests host networking support with ephemeral containers
3. **Caching**: Stores results for 24 hours to speed up future launches
4. **Fallback**: Uses bridge mode if host networking isn't available

#### Host Networking Mode

**When Available**: Linux (native), macOS (Docker Desktop beta/OrbStack), Windows (Docker Desktop beta)

**Benefits**:
- 🌐 Direct access to `localhost:PORT` services
- 🔗 Container-to-container communication via localhost
- ⚡ Better network performance
- 🎯 No port mapping required
- 📡 Full network stack sharing with host

**Example Use Cases**:
```bash
# Access your development database
dclaude "connect to the PostgreSQL database on localhost:5432"

# Test your web application
dclaude "check the API endpoints at localhost:3000"

# Debug microservices
dclaude "analyze the logs from the service running on localhost:8080"
```

#### Bridge Networking Mode

**When Used**: Fallback when host networking isn't supported

**Limitations**:
- ❌ Cannot access `localhost` services directly
- 🔄 Must use `host.docker.internal` instead of `localhost`
- 📦 Container has isolated network namespace
- 🚧 Some UDP services may not be accessible

**Workarounds**:
```bash
# Instead of localhost:8080, use:
host.docker.internal:8080

# Example for accessing host services:
dclaude "test the API at http://host.docker.internal:3000"
```

#### Command-Line Control

You can override auto-detection with environment variables:

```bash
# Force host networking (full localhost access)
DCLAUDE_NETWORK=host dclaude "test localhost:3000"

# Force bridge networking (isolated mode)
DCLAUDE_NETWORK=bridge dclaude "safer isolated development"

# Use auto-detection (default)
dclaude "let dclaude choose the best mode"
```

#### Environment Variable Control

```bash
# Set networking mode via environment variable
DCLAUDE_NETWORK=host dclaude
DCLAUDE_NETWORK=bridge dclaude
DCLAUDE_NETWORK=auto dclaude  # default
```

#### Platform-Specific Notes

**Linux**:
- Host networking works natively
- Full localhost access available
- No special configuration required

**macOS**:
- Host networking available with:
  - Docker Desktop with host networking beta feature enabled
  - OrbStack (recommended Docker Desktop alternative)
- Bridge mode fallback for standard Docker Desktop
- Check debug output with `DCLAUDE_DEBUG=true dclaude` for detection results

**Windows**:
- Host networking available with Docker Desktop beta features
- WSL2 may provide additional networking capabilities
- Bridge mode fallback for standard configurations

### Environment Variables

| Variable | Description | Default | Values |
|----------|-------------|---------|--------|
| `DCLAUDE_TAG` | Docker image tag to use | `latest` | Any valid tag |
| `DCLAUDE_RM` | Remove container on exit | `true` | `true`, `false` |
| `DCLAUDE_DEBUG` | Enable debug output | `false` | `true`, `false` |
| `DCLAUDE_NO_UPDATE` | Skip image update check | `false` | `true`, `false` |
| `DCLAUDE_DOCKER_SOCKET` | Docker socket path | `/var/run/docker.sock` | Valid socket path |
| `DCLAUDE_NETWORK` | Network mode | `auto` | `auto`, `host`, `bridge` |
| `DCLAUDE_REGISTRY` | Docker registry | `docker.io` | Registry URL |
| `CLAUDE_MODEL` | Claude model to use | (Claude's default) | Model name |
| **SSH Authentication** | | | |
| `DCLAUDE_SSH` | SSH authentication mode | `auto` | `auto`, `agent-forwarding`, `key-mount`, `none` |
| **Config Mounting** | | | |
| `DCLAUDE_MOUNT_CONFIGS` | Master switch to enable config mounting | `false` | `true`, `false` |
| `DCLAUDE_MOUNT_DOCKER` | Mount `.docker/` directory | `true`* | `true`, `false` |
| `DCLAUDE_MOUNT_GIT` | Mount `.gitconfig` file | `true`* | `true`, `false` |
| `DCLAUDE_MOUNT_GH` | Mount `.config/gh/` for GitHub CLI | `true`* | `true`, `false` |
| `DCLAUDE_MOUNT_NPM` | Mount `.npmrc` file | `true`* | `true`, `false` |

*When `DCLAUDE_MOUNT_CONFIGS=true`

### SSH Authentication

dclaude provides flexible SSH authentication options via the `DCLAUDE_SSH` environment variable:

#### Authentication Modes

- **`auto`** (default): Automatically detects the best method
  - Uses agent forwarding if SSH agent is running
  - Falls back to key mounting if agent not available
  - Prefers key mounting when `DCLAUDE_MOUNT_CONFIGS=true`

- **`agent-forwarding`**: Forward SSH agent socket to container
  - **Most secure** - private keys never leave host
  - Keys remain in agent memory only
  - **macOS**: Uses automatic socat proxy to handle permissions

- **`key-mount`**: Mount `~/.ssh` directory (read-only)
  - Works consistently across all platforms
  - Private keys accessible in container (read-only)
  - Compatible with existing workflows

- **`none`**: No SSH authentication

#### Usage Examples

```bash
# Use SSH agent forwarding (most secure, Linux works best)
DCLAUDE_SSH=agent-forwarding dclaude

# Use key mounting (most compatible)
DCLAUDE_SSH=key-mount dclaude

# Let dclaude choose the best method
dclaude  # or DCLAUDE_SSH=auto dclaude
```

#### Platform Notes

**Linux**: Agent forwarding works with direct socket mounting
**macOS**: Agent forwarding uses automatic socat proxy (adds ~0.5s startup)
**Windows**: Limited support; key-mount recommended

#### Loading SSH Keys (Agent Forwarding)

When using agent forwarding, your SSH keys must be loaded into your **host's SSH agent**. The container accesses keys through the agent, not by reading key files.

**Check if keys are loaded:**
```bash
# On your host machine
ssh-add -l
```

If you see `The agent has no identities`, you need to load your key:

**Load SSH key (one-time):**
```bash
# Load your SSH key
ssh-add ~/.ssh/id_ed25519

# Or load with macOS keychain (persists across reboots)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

**Make it permanent (macOS):**

Add to your `~/.ssh/config`:
```
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

This automatically loads your key when first used and stores the passphrase in macOS keychain.

**Manage loaded keys:**
```bash
# List loaded keys
ssh-add -l

# Remove specific key
ssh-add -d ~/.ssh/id_ed25519

# Remove all keys
ssh-add -D
```

#### How SSH Agent Forwarding Works

**Linux:**
- Direct socket mount: `$SSH_AUTH_SOCK` → `/tmp/ssh-agent` in container
- No additional containers needed
- Native performance

**macOS:**
- Docker Desktop has permission restrictions on the SSH agent socket
- dclaude automatically creates a proxy container (`dclaude-ssh-proxy-<uid>`)
- Uses `socat` to bridge permissions between host agent and container
- Proxy runs once and is reused across sessions
- Adds ~0.5s to first startup, then cached

**Windows:**
- Limited SSH agent support
- Recommend using `key-mount` mode instead

#### Testing SSH Access

```bash
# Verify keys are loaded on host first
ssh-add -l

# Test GitHub SSH authentication from container
dclaude exec ssh -T git@github.com
# Expected: "Hi username! You've successfully authenticated..."

# Test git operations
dclaude exec git clone git@github.com:private/repo.git

# Debug SSH connection issues
dclaude exec ssh -Tv git@github.com
```

#### Troubleshooting SSH Authentication

**"The agent has no identities":**
```bash
# Problem: No SSH keys loaded in host's SSH agent
# Solution: Load your key on the host
ssh-add ~/.ssh/id_ed25519

# Verify it worked
ssh-add -l
```

**"Permission denied (publickey)":**
```bash
# Check key is loaded
ssh-add -l

# Verify key has correct permissions on host
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Test connection with verbose output
dclaude exec ssh -Tv git@github.com
```

**Keys disappear after reboot (macOS):**
```bash
# Use keychain integration for persistence
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Or add to ~/.ssh/config (see "Make it permanent" above)
```

**Proxy container not starting (macOS):**
```bash
# Check if proxy container exists
docker ps -a | grep dclaude-ssh-proxy

# Remove stale proxy container
docker rm -f dclaude-ssh-proxy-$(id -u)

# Let dclaude recreate it on next run
dclaude
```

### Configuration Mounting

dclaude can optionally mount your host configuration files to enable seamless tool integration:

#### Enabling Config Mounting

```bash
# Enable all config mounting (for installed tools)
DCLAUDE_MOUNT_CONFIGS=true dclaude

# Selectively disable specific configs
DCLAUDE_MOUNT_CONFIGS=true DCLAUDE_MOUNT_NPM=false dclaude
```

#### What Gets Mounted

When `DCLAUDE_MOUNT_CONFIGS=true`, the following configurations are mounted (read-only) by default:

- **Docker Config** (`.docker/`): Access private Docker registries with your auth
- **Git Config** (`.gitconfig`): Your Git user settings and aliases
- **GitHub CLI** (`.config/gh/`): GitHub CLI authentication and settings
- **NPM Config** (`.npmrc`): NPM registry authentication (if present)

All mounts are **read-only** for security. Only configurations for tools installed in the container are mounted.

#### Security Considerations

- Config mounting is **disabled by default** for security
- All configuration mounts are **read-only**
- Contains sensitive data (SSH keys, auth tokens)
- Only enable in trusted environments
- Individual configs can be disabled via environment variables

#### Use Cases

```bash
# Clone private repositories using your SSH keys
DCLAUDE_MOUNT_CONFIGS=true dclaude "git clone git@github.com:private/repo.git"

# Use GitHub CLI with your existing authentication
DCLAUDE_MOUNT_CONFIGS=true dclaude "gh pr create"

# Pull from private Docker registries
DCLAUDE_MOUNT_CONFIGS=true dclaude "docker pull private.registry.io/image"
```

### Docker Socket Access

The container can access Docker on your host system. This enables Claude to:
- Manage Docker containers
- Build and run Docker images
- Access docker-compose projects

**⚠️ Security Note**: Docker socket mounting grants significant privileges. Only use in trusted environments.

### Homebrew Support

dclaude includes full Homebrew/Linuxbrew integration for package management:

```bash
# Create a persistent container first
DCLAUDE_RM=false dclaude

# Install packages with Homebrew
dclaude exec brew install ripgrep fd bat
dclaude exec brew install node@18
dclaude exec brew install postgresql

# Packages persist across sessions
dclaude exec which rg  # /home/linuxbrew/.linuxbrew/bin/rg

# Use installed tools in Claude
DCLAUDE_RM=false dclaude "search for TODO using ripgrep"
```

**How it works:**
- Homebrew installed in `/home/linuxbrew/.linuxbrew`
- Available to `claude` user via group membership
- Packages installed with `dclaude exec brew install` persist in containers
- Requires persistent containers (`DCLAUDE_RM=false`)

**Common use cases:**
- Install language toolchains (Go, Rust, etc.)
- Add development tools (jq, yq, httpie)
- Install databases (PostgreSQL, Redis, MongoDB)
- Add build tools (cmake, make, gcc)

## What's Included

### Container Environment
- **Base OS**: Ubuntu 24.04 LTS (compatible with Homebrew)
- **Languages**: Node.js 20+, Python 3 with pip
- **Package Managers**: Homebrew/Linuxbrew, npm, pip
- **Tools**: Docker CLI, Docker Compose, Git, GitHub CLI (gh), curl, nano
- **Claude CLI**: Latest version of `@anthropic-ai/claude-code`
- **Lifecycle**: Ephemeral by default, optional persistent mode

### Persistent Data

Data is stored in named Docker volumes:
- `dclaude-config`: Configuration files
- `dclaude-cache`: Cache data
- `dclaude-claude`: Claude-specific data

To reset all data:
```bash
docker volume rm dclaude-config dclaude-cache dclaude-claude
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | ✅ Full Support | Host networking available |
| macOS | ✅ Full Support | Bridge networking only |
| Windows | ✅ WSL2/Docker Desktop | Bridge networking only |

## Building from Source

```bash
# Clone the repository
git clone https://github.com/alanbem/dclaude.git
cd dclaude

# Build the Docker image
docker build -t alanbem/dclaude:local .

# Use the local image
DCLAUDE_TAG=local ./dclaude
```

## Common Workflows

### Quick Tasks (Ephemeral Mode)

For one-off tasks and quick interactions:

```bash
# Fix code issues
dclaude "fix linting errors in src/"

# Generate documentation
dclaude "create API documentation from comments"

# Run tests
dclaude "run the test suite and explain failures"

# Code review
dclaude "review the changes in git diff"
```

### Development Environment (Persistent Mode)

For longer development sessions with installed tools:

```bash
# Initial setup - create persistent container
DCLAUDE_RM=false dclaude

# Install development tools
dclaude exec brew install ripgrep fd exa
dclaude exec npm install -g typescript eslint prettier

# Work on your project
DCLAUDE_RM=false dclaude "refactor the authentication module"

# Access shell directly
dclaude exec  # Opens bash in the container

# Run commands without Claude
dclaude exec npm test
dclaude exec rg "TODO" src/
```

### Full-Stack Development

Using persistent containers for complex setups:

```bash
# Setup development environment
DCLAUDE_RM=false dclaude

# Install required tools
dclaude exec brew install postgresql node@18 redis
dclaude exec npm install -g pm2

# Start services in background (via shell)
dclaude exec
# Inside container:
brew services start postgresql
brew services start redis
pm2 start app.js
exit

# Use Claude with running services
DCLAUDE_RM=false dclaude "migrate the database schema"
DCLAUDE_RM=false dclaude "test the API endpoints on localhost:3000"
```

### CI/CD Integration

Use ephemeral mode for clean, reproducible builds:

```bash
# In your CI pipeline
dclaude "run tests and build production bundle"
dclaude "lint all files and report issues"
dclaude "generate changelog from git commits"
```

### Multi-Project Workflow

Each directory gets its own persistent container:

```bash
# Project A
cd ~/projects/frontend
DCLAUDE_RM=false dclaude
dclaude exec npm install

# Project B (separate container)
cd ~/projects/backend
DCLAUDE_RM=false dclaude
dclaude exec brew install go

# Each maintains its own environment
```

## Troubleshooting

### Docker not found
```bash
# Install Docker Desktop (macOS/Windows) or Docker Engine (Linux)
# Visit: https://docs.docker.com/get-docker/
```

### Permission denied on Docker socket
```bash
# Linux: Add your user to the docker group
sudo usermod -aG docker $USER
# Then logout and login again

# macOS/Windows: Ensure Docker Desktop is running
```

### Image not found / Pull failed
```bash
# Build the image locally first
docker build -t alanbem/dclaude:latest .
```

### Claude authentication issues
```bash
# Run dclaude and use /login command
dclaude
# Then at the Claude prompt:
/login
# Follow the authentication prompts
```

### Network access issues

**Can't access localhost services**:
```bash
# Check current networking mode
DCLAUDE_DEBUG=true dclaude

# Try forcing host mode (if supported)
DCLAUDE_NETWORK=host dclaude

# On macOS: Enable host networking in Docker Desktop or use OrbStack
# On Windows: Enable host networking beta feature in Docker Desktop

# Fallback: Use bridge mode with host.docker.internal
DCLAUDE_NETWORK=bridge dclaude
# Then access services via host.docker.internal:PORT
```

**Slow startup or networking detection**:
```bash
# Clear network detection cache
rm ~/.dclaude/network-mode

# Run with debug to see detection process
DCLAUDE_DEBUG=true dclaude
```

**Force specific networking mode**:
```bash
# Set in your shell profile (~/.bashrc, ~/.zshrc, etc.)
export DCLAUDE_NETWORK=host    # Always use host networking
export DCLAUDE_NETWORK=bridge  # Always use bridge networking
```

### Debug mode for troubleshooting
```bash
# Enable verbose output to diagnose issues
DCLAUDE_DEBUG=true dclaude
```

### "No container found" when using exec
```bash
# The exec command requires a persistent container
# Error: "No container found for this directory"

# Solution: Create a persistent container first
DCLAUDE_RM=false dclaude

# Then exec will work
dclaude exec
```

### Container not persisting installed packages
```bash
# Packages disappear after exit

# Cause: Using ephemeral mode (default)
dclaude  # Creates new container each time

# Solution: Use persistent mode
DCLAUDE_RM=false dclaude
dclaude exec brew install your-package
```

## Development

### Project Structure
```
.
├── dclaude              # Launcher script
├── Dockerfile           # Docker image definition
├── package.json         # NPM package configuration
├── .github/workflows/   # CI/CD pipelines
├── VERSION              # Version tracking
├── Makefile             # Development commands
├── completions/         # Shell completion scripts
├── examples/            # Usage examples and config
└── scripts/             # Utility scripts
```

### Using the Makefile
```bash
make build    # Build Docker image locally
make test     # Run tests
make install  # Install dclaude locally
make verify   # Verify installation
make release  # Create a new release
```

### Shell Completion
Install tab completion for your shell:
```bash
# Bash
source completions/dclaude.bash

# Zsh
source completions/dclaude.zsh
```

### Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

### Testing
```bash
# Test the launcher script
bash -n dclaude

# Build and test Docker image
docker build -t test-image .
docker run --rm test-image --version
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Anthropic](https://www.anthropic.com/) for Claude and the Claude Code CLI
- The Docker community for containerization tools
- Contributors and users of this project

## Support

- **Issues**: [GitHub Issues](https://github.com/alanbem/dclaude/issues)
- **Discussions**: [GitHub Discussions](https://github.com/alanbem/dclaude/discussions)