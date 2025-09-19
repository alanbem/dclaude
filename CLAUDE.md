# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project containerizes the Claude Code CLI inside a Docker container with host-like environment emulation. The container provides:
- Minimal Alpine Linux base
- Access to host Docker daemon via socket mounting
- Path mirroring between host and container
- Persistent Claude configuration isolated from host

## Architecture

### Key Components

1. **Docker Container Setup** (`Dockerfile`)
   - Alpine Linux 3.19 base with Docker CLI and Docker Compose
   - Claude CLI installed via npm in user space
   - Non-root `claude` user with docker group permissions

2. **Path Mirroring System** (`dclaude` launcher script)
   - Dynamically mounts current host directory at same path in container
   - Creates parent directories as needed to preserve full path structure
   - Enables seamless file access and command execution from Claude

3. **Docker Socket Access**
   - Container connects to host Docker daemon via `/var/run/docker.sock`
   - Allows Claude to manage other Docker containers on the host
   - Network mode set to "host" on Linux for localhost port access

4. **Persistent Storage** (Named Docker Volumes)
   - Claude configuration stored in named Docker volumes
   - Isolated from host Claude installations
   - Includes `dclaude-config`, `dclaude-cache`, and `dclaude-claude` volumes

## Common Commands

### Installation and Usage
```bash
# Install via NPM
npm install -g @alanbem/dclaude

# Run Claude
dclaude

# Run with specific command
dclaude "fix the bug"

# Update Docker image
dclaude --update

# Enable debug mode
DCLAUDE_DEBUG=true dclaude
```

### Building from Source
```bash
# Build Docker image
docker build -t alanbem/dclaude:local .

# Test the image
docker run --rm alanbem/dclaude:local --version

# Use local image with dclaude
DCLAUDE_TAG=local dclaude
```

### Testing Docker Access from Claude
When inside Claude, verify Docker access with:
```bash
docker --version
docker compose version
docker ps
```

## Important Configuration

### Environment Variables
- `MCP_TIMEOUT`: Model Context Protocol timeout (default: 30000ms)
- `CLAUDE_BASH_TIMEOUT`: Bash command timeout (default: 600000ms/10min)
- `CLAUDE_UNSAFE_TRUST_WORKSPACE=true`: Skip interactive prompts

### Volume Mounts
- Current directory mounted at same path in container
- Docker socket at `/var/run/docker.sock` (conditional)
- Persistent data in named Docker volumes:
  - `dclaude-config`: Configuration files
  - `dclaude-cache`: Cache data
  - `dclaude-claude`: Claude-specific data

### Security Considerations
- Container runs without sudo privileges
- Docker socket mount grants significant privileges (only when available)
- Non-root `claude` user with docker group membership
- Platform-specific network mode (host on Linux, bridge on Mac/Windows)

## Task Management Workflow

### Starting a New Task
When beginning a new task or project:

1. **Check for existing TASK.md**:
   - If `TASK.md` exists with a completed task, back it up first:
     ```bash
     mv TASK.md "TASK-$(date +%Y%m%d)-description.md.backup"
     ```

2. **Create new TASK.md from template**:
   ```bash
   cp TASK.md.dist TASK.md
   ```

3. **Customize the template**:
   - Fill in project name, dates, and objectives
   - Add/remove/reorder phases as needed
   - Update success criteria and requirements

4. **Follow the development process**:
   - Each phase must include implementation → review → fix cycles
   - Minimum 2 review iterations, maximum 10
   - Track all review cycles in the tables provided

### Managing Task Files
- `TASK.md.dist`: Template file, kept in version control
- `TASK.md`: Active task file, ignored by git for privacy
- `TASK-*.md.backup`: Archived completed tasks, ignored by git

### Best Practices
- Always start with research phase for complex tasks
- Document decisions and rationale as you work
- Update progress daily during active development
- Keep review feedback and fixes documented
- Archive completed tasks for future reference