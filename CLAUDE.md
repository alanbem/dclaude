# CLAUDE.md

AI assistant guidance for working with the dclaude (Dockerized Claude Code) project.

## Core Understanding

**Project Purpose**: Containerizes Claude Code CLI to run in Docker with host-like capabilities while maintaining isolation.

**Key Innovation**: Path mirroring - container mounts host directory at identical path, enabling seamless file operations as if running natively.

## Critical Technical Context

### Architecture Components
- **Dockerfile**: Alpine 3.19 base, non-root `claude` user, includes Docker CLI/Compose, Node.js, Python
- **dclaude script**: Launcher handling platform detection, volume management, path mirroring
- **Docker volumes**: `dclaude-config`, `dclaude-cache`, `dclaude-claude` for persistent data
- **Future**: Consider adding `gh` CLI if mounting host configs (`.ssh`, `.config/gh`)

### Host Integration Features
1. **Docker socket mounting** (`/var/run/docker.sock`) - enables container management from within
2. **Path mirroring** - current directory mounted at same absolute path in container
3. **Smart network detection** - auto-detects optimal networking mode with caching and platform validation

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
1. For new tasks: `cp TASK.md.dist TASK.md`
2. For completed tasks: `mv TASK.md "TASK-$(date +%Y%m%d)-description.md.backup"`
3. Follow review cycles: implementation → review → fix (min 2 cycles, max 10)

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

## Security Constraints
- No sudo in container (removed for security)
- Docker socket access is privileged - document risks
- Non-root user with docker group membership only

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
- Template for new tasks: TASK.md.dist
- Build automation: Makefile
- CI/CD: .github/workflows/