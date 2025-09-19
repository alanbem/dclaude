# Dockerized Claude Code

[![Docker Hub](https://img.shields.io/docker/v/alanbem/claude-code?label=Docker%20Hub)](https://hub.docker.com/r/alanbem/claude-code)
[![npm version](https://img.shields.io/npm/v/@alanbem/dclaude)](https://www.npmjs.com/package/@alanbem/dclaude)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Run Claude Code CLI in a Docker container with full MCP (Model Context Protocol) support and host environment emulation.

## Features

- 🐳 **Fully Containerized**: Run Claude CLI without local installation
- 🔧 **Docker Access**: Mount Docker socket for container management from Claude
- 📁 **Path Mirroring**: Seamless file access between host and container
- 🔌 **MCP Support**: Full Node.js and Python environments for MCP servers
- 🔒 **Isolated Environment**: Persistent data in Docker volumes
- 🌍 **Cross-Platform**: Works on Linux, macOS, and Windows (with Docker)
- 🚀 **Auto-Updates**: Automatic image updates on launch

## Quick Start

### Option 1: Install via NPM (Recommended)

```bash
npm install -g @alanbem/dclaude
dclaude --help
```

### Option 2: Direct Download

```bash
# Download the launcher script
curl -fsSL https://raw.githubusercontent.com/alanbem/dockerized-claude-code/main/dclaude -o dclaude
chmod +x dclaude
./dclaude --help
```

### Option 3: Use Docker Directly

```bash
docker run --rm -it \
  -v "$(pwd):$(pwd)" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w "$(pwd)" \
  alanbem/claude-code --help
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
git clone https://github.com/alanbem/dockerized-claude-code.git
cd dockerized-claude-code

# Build the Docker image
docker build -t alanbem/claude-code:local .

# Use the local image
DCLAUDE_TAG=local ./dclaude
```

## Troubleshooting

### Docker not found
```bash
# Install Docker first
# Visit: https://docs.docker.com/get-docker/
```

### Permission denied on Docker socket
```bash
# Add your user to the docker group (Linux)
sudo usermod -aG docker $USER
# Then logout and login again
```

### Claude command not responding
```bash
# Check if Docker is running
docker info

# Update the image
dclaude --update

# Enable debug mode
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

- **Issues**: [GitHub Issues](https://github.com/alanbem/dockerized-claude-code/issues)
- **Discussions**: [GitHub Discussions](https://github.com/alanbem/dockerized-claude-code/discussions)