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
./dclaude --help

# (Optional) Install globally
sudo cp dclaude /usr/local/bin/
```

### Option 2: Install via NPM (Coming Soon)

```bash
# Note: Package will be published to NPM registry soon
npm install -g @alanbem/dclaude
dclaude --help
```

### Option 3: Use Docker Directly

```bash
# After building the image locally
docker run --rm -it \
  -v "$(pwd):$(pwd)" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w "$(pwd)" \
  alanbem/dclaude --help
```

## Usage

### Basic Commands

```bash
# Start Claude interactively
dclaude

# Run Claude with a prompt
dclaude "fix the bug in main.js"

# Show version
dclaude --version

# Update Docker image
dclaude --update

# Enable debug mode
DCLAUDE_DEBUG=true dclaude
```

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

3. **Network Emulation**:
   - Linux: Uses host networking (container shares host's network stack)
   - macOS/Windows: Uses bridge networking (some limitations apply)
   - Claude can access localhost services as if running directly on your host

4. **Persistent Data**: Configuration and cache stored in Docker volumes
   - `dclaude-config`: Configuration files
   - `dclaude-cache`: Cache data
   - `dclaude-claude`: Claude-specific data
   - Data persists between container restarts

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

### Network Access Details

#### Linux
- Uses **host networking**: Full access to localhost services
- Services on `localhost:PORT` work directly
- No network isolation from host

#### macOS/Windows
- Uses **bridge networking** with these limitations:
  - Access host services via `host.docker.internal` instead of `localhost`
  - Example: `http://host.docker.internal:8080` instead of `http://localhost:8080`
  - Some UDP services may not be accessible
  - Container has its own network namespace

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DCLAUDE_TAG` | Docker image tag to use | `latest` |
| `DCLAUDE_DEBUG` | Enable debug output | `false` |
| `DCLAUDE_DOCKER_SOCKET` | Docker socket path | `/var/run/docker.sock` |
| `DCLAUDE_NETWORK` | Network mode | `host` (Linux), `bridge` (Mac/Windows) |
| `CLAUDE_MODEL` | Claude model to use | (Claude's default) |

### Docker Socket Access

The container can access Docker on your host system. This enables Claude to:
- Manage Docker containers
- Build and run Docker images
- Access docker-compose projects

**⚠️ Security Note**: Docker socket mounting grants significant privileges. Only use in trusted environments.

## What's Included

### Container Environment
- **Base OS**: Alpine Linux 3.19 (minimal footprint)
- **Languages**: Node.js 20+, Python 3 with pip
- **Tools**: Docker CLI, Docker Compose, Git, curl, nano
- **Claude CLI**: Latest version of `@anthropic-ai/claude-code`

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

### Network access issues on macOS/Windows
```bash
# Use host.docker.internal instead of localhost
# Example: http://host.docker.internal:8080
```

### Debug mode for troubleshooting
```bash
# Enable verbose output to diagnose issues
DCLAUDE_DEBUG=true dclaude
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

### Configuration File
Create `~/.dclaude/config` to set defaults:
```bash
cp examples/dclaude.config ~/.dclaude/config
# Edit with your preferences
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