# CLAUDE.md

AI assistant guidance for working with the dclaude (Dockerized Claude Code) project.

## Code Style Guidelines

### Comments and Documentation
- DO NOT leave conversation-style comments in code (e.g., "Removed X", "User requested Y")
- DO NOT use code comments as a changelog or conversation record
- Keep code clean - changes are tracked in git history, not comments
- Technical comments should explain WHY something works a certain way, not WHAT was changed
- Communication with user happens in chat, not in code comments

## Core Understanding

**Project Purpose**: Containerizes Claude Code CLI to run in Docker with host-like capabilities while maintaining isolation.

**Key Innovation**: Path mirroring - container mounts host directory at identical path, enabling seamless file operations as if running natively.

## Critical Technical Context

### Architecture Components
- **Dockerfile**: Ubuntu 24.04 base, non-root `claude` user, includes Docker CLI/Compose, GitHub CLI, Node.js, Python, socat, gosu, tini, tmux
- **tini**: Minimal init system (PID 1) that reaps zombie processes created by docker exec commands
- **docker-entrypoint.sh**: Entrypoint script that sets up SSH agent proxy when needed (socat bridge for macOS permissions)
- **dclaude script**: Launcher handling platform detection, volume management, path mirroring, config mounting
- **Docker volumes**: `dclaude-config`, `dclaude-cache`, `dclaude-claude` for persistent data
- **Config mounting**: Optional read-only mounting of host configs (SSH, Docker, Git, GitHub CLI, NPM)

### Process Management with Tini

**Why tini is critical:**

Persistent containers run `tini` as PID 1, which serves as a minimal init system that properly reaps zombie (defunct) processes.

**The Problem Without Tini:**
- When using `docker exec` to start tmux sessions, child processes (tmux, claude, sh, git) are created
- When these processes exit, they become zombies if their parent doesn't call `wait()` to reap them
- `tail -f /dev/null` (our daemon process) doesn't reap zombies, causing accumulation
- Zombie processes waste PIDs and can eventually exhaust system resources

**How Tini Solves This:**
- Tini runs as PID 1 and properly handles SIGCHLD signals
- Automatically reaps any zombie child processes
- Forwards signals to child processes correctly
- Minimal overhead (~10KB binary)

**Implementation:**
- Dockerfile: Installs `tini` package
- Dockerfile ENTRYPOINT: Wraps entrypoint with tini for ephemeral containers
- dclaude script: Uses `--entrypoint /usr/bin/tini` for persistent containers
- Result: Clean process tree with no zombie accumulation

### Host Integration Features
1. **Docker socket mounting** (`/var/run/docker.sock`) - enables container management from within
2. **Path mirroring** - current directory mounted at same absolute path in container
3. **Smart network detection** - auto-detects optimal networking mode with caching and platform validation
4. **Configuration mounting** - optional read-only mounting of host tool configs for seamless authentication

### Network Detection Algorithm

The `detect_network_capability()` function implements a sophisticated testing approach:

#### Detection Process
1. **Cache Check**: Validates cached results from `~/.dclaude/network-mode` (24-hour TTL)
2. **Basic Test**: Verifies host networking support with loopback interface check
3. **Service Test**: Tests container-to-container localhost communication using dynamic ports
4. **Platform Validation**: Cross-references results with expected platform capabilities
5. **Result Caching**: Stores successful detection results for faster subsequent launches

#### Implementation Details
- **Dynamic Port Discovery**: Uses `find_available_port()` to avoid conflicts
- **Ephemeral Test Containers**: Creates temporary alpine:3.19 containers for testing
- **Timeout Protection**: 10-second overall timeout with 5-second individual test limits
- **Cleanup Handling**: Robust cleanup via trap handlers for interrupted tests
- **Platform-Specific Warnings**: Validates unusual combinations (e.g., host mode on macOS without beta features)

#### Cache Management
- **Location**: `~/.dclaude/network-mode`
- **Format**: Single line containing `host` or `bridge`
- **Validation**: Age verification and content validation before use
- **Invalidation**: Manual removal or 24-hour automatic expiry

#### Error Handling
- **Graceful Degradation**: Falls back to bridge mode on any test failure
- **Informative Warnings**: Provides platform-specific guidance for enabling host networking
- **Debug Output**: Comprehensive logging when `DCLAUDE_DEBUG=true`

## Development Workflow

### Task Management
See [tasks/CLAUDE.md](tasks/CLAUDE.md) for complete task management workflow, review requirements, and completed tasks archive.

### Testing Commands
```bash
# Local build and test
docker build -t alanbem/dclaude:local .
DCLAUDE_TAG=local ./dclaude --version

# Verify Docker access from within container
./dclaude "docker ps"
```

### Making Changes
- **Dockerfile changes**: Test with local build before committing
- **dclaude script changes**: Test on multiple platforms if possible
- **Documentation**: User-facing docs in README.md, technical context here

### SSH Authentication System

The `handle_ssh_auth()` function provides flexible SSH authentication via `DCLAUDE_SSH` environment variable.

**User Documentation**: See README.md "SSH Authentication" section for usage and examples.

#### Technical Implementation
- Function handles socket mounting for agent forwarding and directory mounting for keys
- Platform-specific handling: Linux uses direct mount, macOS runs container as root for proxy setup
- Returns null-separated Docker arguments for safe parsing
- **SOLVED**: macOS Docker Desktop permissions via socat proxy in entrypoint script
- Entrypoint automatically creates proxy socket owned by claude user when needed

### Configuration Mounting System

The `mount_host_configs()` function provides selective config mounting controlled by `DCLAUDE_MOUNT_CONFIGS`.

**User Documentation**: See README.md "Configuration Mounting" section for usage and supported configs.

#### Technical Implementation
- Returns null-separated Docker arguments for safe parsing
- Validates each config path exists and is readable before mounting
- All mounts use read-only flag (`:ro`)
- SSH handled separately via `handle_ssh_auth()` function

## Tmux Session Management

### Architecture
Persistent containers (`DCLAUDE_RM=false`, now the default) use tmux for session management. Each `dclaude` invocation creates a **new** tmux session with a unique name.

### Session Naming
- **Default**: Auto-generated timestamp-based name (e.g., `claude-20231118-143022`)
- **Custom**: Set via `DCLAUDE_TMUX_SESSION` environment variable (e.g., `claude-architect`)
- **Multiple sessions**: Multiple Claude instances can run concurrently in the same container

### Critical Tmux Configuration (.tmux.conf)

**IMPORTANT BUG FIX**: The following settings are critical for proper multi-session behavior:

```tmux
# When the last pane exits, detach instead of switching sessions
set-option -g detach-on-destroy on
```

**Why this matters:**
- **Problem**: With `detach-on-destroy off`, tmux will switch to another active session when one exits, creating confusing UX where exiting one Claude jumps you into another Claude session
- **Solution**: With `detach-on-destroy on`, tmux cleanly exits to your terminal when a session ends
- **Behavior**: Each session is independent; exiting one session returns you to your terminal, not to another Claude

**Additional performance settings:**
- `escape-time 0` - Eliminates keyboard input delays
- `aggressive-resize off` - Prevents input lag in multiple sessions
- Simple `new-session` command without detach/attach pattern prevents double tmux processes that cause lag

### Session Lifecycle
1. `dclaude` starts → Creates new tmux session → Runs Claude
2. Claude exits → Tmux session ends automatically
3. All sessions exit → Tmux server shuts down
4. Container keeps running → Ready for next `dclaude` invocation

### Known Issues (Fixed)
- ❌ **Session switching bug**: Using `detach-on-destroy off` caused sessions to switch instead of exit (FIXED: use `on`)
- ❌ **Input lag in second session**: Creating detached session then attaching caused double tmux processes (FIXED: use direct `new-session`)

## Security Constraints
- No sudo in container (removed for security)
- Docker socket access is privileged - document risks
- Non-root user with docker group membership only
- Config mounts are read-only to prevent modification
- Config mounting is opt-in for security

## Review Requirements
When code changes are made:
1. Security implications of Docker socket access
2. Cross-platform compatibility (Linux/macOS/Windows)
3. Path mirroring edge cases
4. Volume persistence behavior

## Common Operations

### Release Process
```bash
make release          # Interactive version bump
make build           # Build image
make test            # Run tests
make push            # Push to registries (requires auth)
```

### Debug Issues
```bash
DCLAUDE_DEBUG=true dclaude    # Enable debug output
make verify                    # Run installation verification
```

## References
- Full user documentation: See README.md
- Task management: See tasks/CLAUDE.md
- Task template: tasks/_TASK.md
- Build automation: Makefile
- CI/CD: .github/workflows/