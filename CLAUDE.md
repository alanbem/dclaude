# CLAUDE.md

AI assistant guidance for working with the dclaude (Dockerized Claude Code) project.

## ⚠️ CRITICAL: Dogfooding Awareness

**You may be running inside dclaude right now!** When working on the dclaude project, be aware that:

1. **The user is likely running you via dclaude** - you are inside the very container you're modifying
2. **NEVER run `dclaude stop` or `dclaude rm` on the current directory** - this kills YOUR container and terminates the session
3. **When testing dclaude commands**, always use a separate test directory:
   ```bash
   mkdir -p /tmp/dclaude-test && cd /tmp/dclaude-test
   # Now safe to test dclaude stop, rm, etc.
   ```
4. **Check before destructive operations** - if working in the dclaude repo, any container management commands affect YOUR session

**How to detect:** Run `test -f /.dockerenv && echo "dclaude" || echo "host"` - if it prints "dclaude", you're inside the container. If working directory is also the dclaude repository itself, you are dogfooding - exercise extreme caution with container lifecycle commands.

## Testing Guidelines

### Directory Structure

**`tests/` - Tracked Test Code and Documentation**

Reusable test scripts, test plans, and test documentation that should be version controlled:

- **Test plans**: `tests/TEST_<feature>.md` - Instructions for testing features
- **Test scripts**: `tests/test_<feature>.sh` - Automated test scripts
- **Test utilities**: `tests/utils/` - Shared test helper functions
- **Test fixtures**: `tests/fixtures/` - Static test data

**`artifacts/` - Gitignored Ephemeral Outputs**

One-time documents, intermediary test results, and outputs that should NOT be tracked:

- **Test results**: `artifacts/RESULTS_<feature>.md` - Output from test runs
- **Scratch documents**: `artifacts/scratch_*.md` - Temporary analysis documents
- **Generated files**: `artifacts/generated/` - Build outputs, reports, logs
- **Intermediary data**: `artifacts/data/` - Temporary data files

**Example:**
```bash
tests/                          # Tracked in git
├── TEST_SSH_FEATURE.md        # Test plan (reusable)
├── test_port_detection.sh     # Test script (reusable)
└── fixtures/
    └── sample_config.json

artifacts/                      # Gitignored
├── RESULTS_SSH_FEATURE.md     # Test run output (ephemeral)
├── scratch_analysis.md        # One-time analysis (ephemeral)
└── logs/
    └── test_2024_12_06.log
```

## Code Style Guidelines

### Comments and Documentation
- DO NOT leave conversation-style comments in code (e.g., "Removed X", "User requested Y")
- DO NOT use code comments as a changelog or conversation record
- Keep code clean - changes are tracked in git history, not comments
- Technical comments should explain WHY something works a certain way, not WHAT was changed
- Communication with user happens in chat, not in code comments

### Output Message Hierarchy

The dclaude script uses a strict hierarchy for output messages to provide predictable and debuggable output:

**Message Types and Colors:**
- `error()` - RED - Critical failures (always shown)
- `warning()` - YELLOW - Important notices (always shown)
- `success()` - GREEN - Completed operations (hidden in quiet mode)
- `info()` - BLUE - High-level operation summaries (hidden in quiet mode)
- `debug()` - CYAN - Implementation details (only shown in debug mode)

**Hierarchy Rules:**
1. ✅ **Info without debug** - OK for simple operations
   ```bash
   info "Starting new Claude session..."
   # No debug needed - operation is straightforward
   ```

2. ✅ **Info with debug** - OK for complex operations
   ```bash
   info "Detecting Docker socket..."
   debug "Checking Docker context for socket path"
   debug "Socket found: $socket_path"
   debug "Verified socket is accessible"
   ```

3. ❌ **Debug without info** - NOT OK (orphaned debug)
   ```bash
   # WRONG - Where's the context?
   debug "Socket found at /var/run/docker.sock"

   # RIGHT - Add info message above
   info "Detecting Docker socket..."
   debug "Socket found at /var/run/docker.sock"
   ```

**Output Modes:**
- **Normal** (`QUIET=false, DEBUG=false`): error, warning, success, info
- **Quiet** (`QUIET=true`): error, warning only (QUIET overrides DEBUG)
- **Debug** (`DEBUG=true, QUIET=false`): all messages including debug details

**Principles:**
- Info messages explain WHAT is happening (user-facing summary)
- Debug messages explain HOW it's happening (implementation details)
- Every debug must have an info parent for context
- Simple operations don't need debug details
- Complex operations should provide debug details for troubleshooting

## Core Understanding

**Project Purpose**: Containerizes Claude Code CLI to run in Docker with host-like capabilities while maintaining isolation.

**Key Innovation**: Path mirroring - container mounts host directory at identical path, enabling seamless file operations as if running natively.

**System Context Feature**: Claude CLI receives environment information via `--append-system-prompt` flag, informing it about the containerized environment, capabilities, and limitations.

## Critical Technical Context

### Architecture Components
- **docker/Dockerfile**: Ubuntu 24.04 base, non-root `claude` user, includes Docker CLI/Compose, GitHub CLI, Node.js, Python, socat, gosu, tini, tmux
- **tini**: Minimal init system (PID 1) that reaps zombie processes created by docker exec commands
- **docker/usr/local/bin/docker-entrypoint.sh**: Entrypoint script that sets up SSH agent proxy when needed (socat bridge for macOS permissions)
- **dclaude script**: Launcher handling platform detection, volume management, path mirroring, config mounting
- **Docker volumes**: `dclaude-config`, `dclaude-cache`, `dclaude-claude` for persistent data
- **Config mounting**: Optional read-only mounting of host configs (SSH, Docker, Git, GitHub CLI, NPM)
- **System Context**: Automatic environment awareness via `--append-system-prompt`

### System Context (Environment Awareness)

**Purpose**: Inform Claude about its containerized environment to enable better decision-making and more accurate suggestions.

**Implementation**:
- Function: `generate_system_context()` in dclaude script
- Parameters: network_mode, ssh_mode, has_docker
- Output: Markdown-formatted system prompt explaining the environment
- Delivery: Passed via `--append-system-prompt` flag to Claude CLI
- Control: `DCLAUDE_SYSTEM_CONTEXT` environment variable (default: true)

**What Claude Learns**:
1. **Container Architecture**:
   - Running in Docker with path mirroring
   - File operations affect host filesystem
   - Current directory mounted at identical path

2. **Available Capabilities**:
   - Docker socket access (if available)
   - Network mode (host vs bridge) and localhost implications
   - SSH authentication method (agent-forwarding, key-mount, or none)

3. **Development Tools**:
   - Languages: Node.js 20+, Python 3
   - Package managers: npm, pip, Homebrew
   - CLI tools: git, gh, docker, docker-compose

4. **Important Constraints**:
   - Bridge mode: cannot access localhost directly
   - Agent forwarding: keys not in filesystem
   - Path mirroring: absolute paths work as on host

**Benefits**:
- Claude understands networking limitations (bridge vs host mode)
- Better Docker command suggestions (knows it has daemon access)
- Appropriate SSH authentication advice based on actual setup
- Accurate file path handling (understands path mirroring)

**User Documentation**: See README.md "System Context (Environment Awareness)" section

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
- docker/Dockerfile: Installs `tini` package
- docker/Dockerfile ENTRYPOINT: Wraps entrypoint with tini for ephemeral containers
- dclaude script: Uses `--entrypoint /usr/bin/tini` for persistent containers
- Result: Clean process tree with no zombie accumulation

### Configuration Persistence with inotifywait

**Why event-based sync is critical:**

Claude Code stores its configuration in `~/.claude.json`. Since this directory is mounted as a volume for persistence, we need to sync changes between the container's home directory and the volume.

**The Problem With Polling:**
- Traditional approach: Check file every N seconds (e.g., every 5s)
- Wastes CPU cycles even when nothing changes
- Creates sync delay (up to N seconds before changes persist)
- Unnecessary I/O operations

**How inotifywait Solves This:**
- Event-based monitoring using Linux kernel inotify API
- Zero CPU usage while idle - kernel wakes process only on file changes
- Instant sync when file is modified (no polling delay)
- Handles atomic writes correctly (watches for `close_write` and `moved_to` events)

**Implementation:**
- docker/Dockerfile: Installs `inotify-tools` package
- docker/usr/local/bin/docker-entrypoint.sh: Background process watches `/home/claude/.claude.json` for changes
- On file modification: Immediately copies to volume at `/home/claude/.claude/.claude.json`
- Handles editor atomic writes (write to temp file, then move to final location)

**Technical Details:**
```bash
# Watch directory (not file directly) to catch atomic writes
inotifywait -e close_write -e moved_to --include '\.claude\.json$' /home/claude
```

**Why watch the directory:**
- Many editors (vim, nano, etc.) don't modify files in-place
- They write to a temp file and then move it to the final location
- Watching the directory catches these `moved_to` events
- Pattern filter ensures we only react to `.claude.json` changes

**Result:**
- Efficient, responsive config persistence
- No polling overhead
- Instant sync on changes
- Works with all text editors

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
docker build -t alanbem/dclaude:local docker
DCLAUDE_TAG=local ./dclaude --version

# Verify Docker access from within container
./dclaude "docker ps"
```

### Making Changes

**Files requiring image rebuild** (baked into Docker image):
- `docker/Dockerfile` - Container definition
- `docker/usr/local/bin/docker-entrypoint.sh` - Startup script
- `docker/home/claude/.tmux.conf` - Tmux configuration

After changing these, rebuild and test:
```bash
docker build -t alanbem/dclaude:local docker
DCLAUDE_TAG=local ./dclaude
```

**Files NOT requiring rebuild** (used directly from host):
- `dclaude` - Launcher script (runs on host)
- `README.md`, `CLAUDE.md` - Documentation

General guidelines:
- **docker/ changes**: Always test with local build before committing
- **dclaude script changes**: Test on multiple platforms if possible
- **Documentation**: User-facing docs in README.md, technical context here

### Git Workflow

**Branch Protection:**
- `main` branch is protected - direct pushes are blocked
- All changes require a Pull Request
- CI must pass before merge (build-and-push workflow)

**Branch Policy:**
- All development work must be done on feature branches
- Branch naming: `feat/description`, `fix/description`, `docs/description`

**PR Workflow:**
1. Create feature branch: `git checkout -b feat/my-feature`
2. Make changes and commit
3. Push branch: `git push -u origin feat/my-feature`
4. Create PR: `gh pr create`
5. Wait for CI to pass
6. Merge PR: `gh pr merge --squash --delete-branch`

**Push Policy:**
- Do NOT push or create PRs until the user explicitly asks
- Each "push" or "create PR" request is a one-time approval only
- After pushing, wait for explicit approval before pushing again
- When user says "merge" - use `gh pr merge --squash --delete-branch` to merge and clean up

**PR Description Management:**
- Keep PR description up to date as work progresses
- Update Summary section when scope changes
- Keep checkboxes current: mark complete when done, add new ones for new scope, remove cancelled items
- Update feature tables/lists when implementation changes
- Update PR description using: `gh pr edit <number> --body "new content"` or `gh pr edit <number> --body-file -` with stdin

### SSH Authentication System

The `handle_ssh_auth()` function provides flexible SSH authentication via `DCLAUDE_GIT_AUTH` environment variable.

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

### Critical Tmux Configuration (docker/home/claude/.tmux.conf)

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

### Status Bar Design

The tmux status bar displays environment context at the bottom of the screen.

**Layout:**
```
 net: HOST • dir: /path/to/dir      session: NAME      claude: 1.2.3 • image: local
 └─ left ─────────────────────┘     └─ center ─┘       └────────── right ─────────┘
```

**Design Principles:**
1. **Theme-agnostic**: Works with both dark and light terminal themes
2. **Claude branding**: Labels use Claude orange (#D97757)
3. **Minimal footprint**: Single status line, no borders

**Color Scheme:**
| Element | Color | Rationale |
|---------|-------|-----------|
| Background | `terminal` | Matches user's terminal theme |
| Labels | `#D97757` | Claude orange for branding |
| Values | `terminal` | Adapts to user's theme (light/dark) |
| Separators | `#D97757` | Orange dot (•) between attributes |

**Internal Environment Variables:**
These are passed via `docker exec -e` when creating tmux sessions:
- `_DCLAUDE_NET` - Network mode (host/bridge)
- `_DCLAUDE_TAG` - Docker image tag
- `_DCLAUDE_SESSION` - Session name ("auto" or custom)

**Adding New Attributes:**
1. Pass new env var in dclaude script via `exec_env_args+=(-e "_DCLAUDE_NEWVAR=value")`
2. Update `docker/home/claude/.tmux.conf` status-left/right with: `#[fg=#D97757]label: #[fg=terminal]#(printenv _DCLAUDE_NEWVAR || echo '?')`
3. Use `•` separator between attributes in same section
4. Rebuild image (tmux config is baked in)

### Session Lifecycle
1. `dclaude` starts → Creates new tmux session → Runs Claude
2. Claude exits → Tmux session ends automatically
3. All sessions exit → Tmux server shuts down
4. Container keeps running → Ready for next `dclaude` invocation

### Known Issues (Fixed)
- ❌ **Session switching bug**: Using `detach-on-destroy off` caused sessions to switch instead of exit (FIXED: use `on`)
- ❌ **Input lag in second session**: Creating detached session then attaching caused double tmux processes (FIXED: use direct `new-session`)

### TTY Detection and Interactive Mode

**Key concept**: Interactivity depends on how the command is called, not on the arguments passed to Claude.

| Scenario | stdin TTY | stdout TTY | Interactive? | Uses tmux? |
|----------|-----------|------------|--------------|------------|
| User runs `dclaude` from terminal | yes | yes | yes | yes |
| User runs `dclaude -p "test"` from terminal | yes | yes | yes | no (print mode) |
| Script/CI runs `dclaude` | no | no | no | should skip |
| Piped input: `echo x \| dclaude` | no | yes | no | should skip |
| Redirected output: `dclaude > out.txt` | yes | no | no | should skip |

**Why this matters:**
- Tmux provides session management for interactive use (multiple concurrent sessions, reattachment)
- For non-interactive use (scripts, CI, piped commands), tmux adds unnecessary overhead
- TTY detection (`test -t 0` for stdin, `test -t 1` for stdout) determines the execution context
- The `detect_tty_flags()` function checks TTY availability and returns appropriate Docker flags

**Implementation:**
- Both persistent and ephemeral containers respect TTY detection
- When no TTY is detected (non-interactive), Claude runs directly without tmux
- When `-p`/`--print` flag is detected, Claude runs directly without tmux (even with TTY)
- When TTY is available and not in print mode, tmux provides session management
- The `detect_tty_flags()` function returns `-i -t` flags for interactive mode, empty for non-interactive
- The `is_print_mode()` function checks for `-p`/`--print` as separate arguments (safe from string matching)

## Chrome DevTools Integration

The `dclaude chrome` subcommand provides seamless integration between Claude and Chrome DevTools via the Model Context Protocol (MCP).

### Architecture

**Host-Container Model:**
- Chrome runs on the **host** (macOS/Linux/Windows) with remote debugging enabled
- Claude runs inside the **dclaude container**
- MCP server (`chrome-devtools-mcp`) runs in the container and connects to Chrome on the host
- Host networking mode enables `localhost` access from container to host

### Usage

```bash
# Launch Chrome with DevTools and create .mcp.json configuration
dclaude chrome

# Custom debugging port
dclaude chrome --port=9223

# Just create .mcp.json without launching Chrome
dclaude chrome --setup-only

# Use different Chrome profile
DCLAUDE_CHROME_PROFILE=testing dclaude chrome
```

### What `dclaude chrome` Does

1. **Auto-detects Chrome** binary (macOS, Linux, Windows supported)
2. **Creates profile directory** at `.dclaude/chrome/profiles/<profile-name>/`
3. **Checks/creates `.mcp.json`** with `chrome-devtools-mcp` server configuration
4. **Validates port consistency** between Chrome launch and `.mcp.json` config
5. **Launches Chrome** with remote debugging on specified port (default: 9222)
6. **Verifies connection** to Chrome DevTools Protocol endpoint

### Chrome Launch Flags

**Default flags (always set):**
- `--user-data-dir=.dclaude/chrome/profiles/<profile>/` - Isolated profile per project
- `--remote-debugging-port=<port>` - Enable DevTools Protocol (default: 9222)
- `--no-first-run` - Skip first-run wizard
- `--no-default-browser-check` - Don't ask to be default browser
- `--disable-default-apps` - Skip default app installation
- `--disable-sync` - Don't sync with Google account
- `--allow-insecure-localhost` - Allow https on localhost without cert warnings

**Custom flags via `DCLAUDE_CHROME_FLAGS`:**
```bash
# Example: Disable extensions and set window size
DCLAUDE_CHROME_FLAGS="--disable-extensions --window-size=1920,1080" dclaude chrome
```

### Configuration

**Environment Variables:**
- `DCLAUDE_CHROME_BIN` - Chrome executable path (auto-detected if not set)
- `DCLAUDE_CHROME_PROFILE` - Profile name (default: `claude`)
- `DCLAUDE_CHROME_PORT` - Debugging port (default: `9222`)
- `DCLAUDE_CHROME_FLAGS` - Additional Chrome flags (default: empty)

### Port Mismatch Warning

If `.mcp.json` already exists with a different port, `dclaude chrome` will warn but still launch:

```
⚠️  Warning: Port mismatch detected!

  Chrome will launch on port:    9223
  MCP expects (.mcp.json):       9222

⚠️  MCP will not be able to connect until .mcp.json is updated
```

This ensures you're aware of configuration mismatches without blocking Chrome from launching.

### Directory Structure

```
project-root/
├── .mcp.json                    # MCP server configuration
└── .dclaude/
    └── chrome/
        └── profiles/
            ├── claude/          # Default profile
            ├── testing/         # Alternative profiles
            └── debug/
```

### Workflow Example

```bash
# 1. Launch Chrome with DevTools
dclaude chrome
# → Chrome opens with debugging on port 9222
# → .mcp.json created with chrome-devtools-mcp configuration

# 2. Start Claude in dclaude container
dclaude
# → Claude starts with Chrome MCP server enabled
# → Can now interact with Chrome via MCP tools

# 3. Claude can now:
#    - List browser tabs
#    - Navigate to URLs
#    - Inspect DOM elements
#    - Execute JavaScript
#    - Take screenshots
#    - Debug web applications
```

### Technical Details

**Why Chrome runs on host:**
- Chrome requires GUI access and native system integration
- Container would need X11 forwarding or VNC (complex, slow)
- Host Chrome + remote debugging is simpler and more performant

**Why host networking works:**
- Container shares host's network namespace
- `localhost:9222` in container = `localhost:9222` on host
- No port mapping or special networking required

**MCP Server:**
- Package: `chrome-devtools-mcp@latest`
- Protocol: Chrome DevTools Protocol (CDP)
- Connection: `--browserUrl=http://localhost:9222`

## SSH Server for Remote Access

The `dclaude ssh` command provides SSH access to the container for remote development tools like JetBrains Gateway, VS Code Remote SSH, or direct SSH connections.

### Usage

```bash
# Start container (SSH port automatically reserved)
dclaude

# Start SSH server and show connection info
dclaude ssh

# Stop SSH server
dclaude ssh --stop
```

### Connection

```bash
ssh claude@localhost -p <port>
# Password: claude
# Port is shown when running 'dclaude ssh'
```

### How It Works

1. When container is created, a random available port is reserved and stored in a container label
2. `dclaude ssh` reads the port from the label and starts sshd on that port
3. Port is mapped identically on host and container (e.g., `34567:34567`)
4. Works with both host and bridge networking modes

### Use Cases

**JetBrains Gateway (PhpStorm, IntelliJ, WebStorm, PyCharm, etc.):**
1. Start container: `dclaude`
2. Start SSH server: `dclaude ssh` (note the port shown)
3. Open JetBrains Gateway → New Connection → SSH
4. Connect to `localhost:<port>` with username `claude`, password `claude`
5. Gateway automatically downloads and deploys IDE backend into the container
6. Select your project directory

**VS Code Remote SSH:**
1. Start container: `dclaude`
2. Start SSH server: `dclaude ssh` (note the port shown)
3. In VS Code: Remote-SSH → Connect to Host → `claude@localhost:<port>`

**Direct SSH/SFTP:**
- SSH: `ssh claude@localhost -p <port>`
- SFTP: `sftp -P <port> claude@localhost`

### Technical Details

**SSH configuration:**
- Password authentication enabled (username: `claude`, password: `claude`)
- SFTP subsystem enabled for file transfer
- Host keys generated on first `dclaude ssh` invocation
- sshd listens on the dynamically assigned port (not port 22)

**Port allocation:**
- Random available port selected at container creation (range: 2222-65000)
- Port stored in container label `dclaude.ssh.port`
- Same port used on both host and container sides
- SSH server only runs when started with `dclaude ssh`

### Security Note

SSH password is hardcoded (`claude:claude`) - suitable for local development only. For production or shared environments, consider SSH key authentication.

## Security Constraints
- No sudo in container (removed for security)
- Docker socket access is privileged - document risks
- Non-root user with docker group membership only
- Config mounts are read-only to prevent modification
- Config mounting is opt-in for security

### Docker Scout Security Scanning

Run Docker Scout periodically to check for vulnerabilities in the published image:

**When to scan:**
- When creating a new feature branch (check base branch security status)
- Before creating a PR (ensure no new vulnerabilities introduced)
- After merging to main (verify production image security)
- Periodically as part of maintenance

**Commands:**
```bash
# Quick overview of vulnerabilities
docker scout quickview alanbem/dclaude:latest

# Detailed CVE list (critical and high severity)
docker scout cves alanbem/dclaude:latest --only-severity critical,high

# Compare two images (e.g., before/after a change)
docker scout compare alanbem/dclaude:latest alanbem/dclaude:main
```

**What to look for:**
- Critical and High severity vulnerabilities that have fixes available
- New vulnerabilities introduced by dependency updates
- Vulnerabilities in packages we directly install vs. transitive dependencies

**Note:** Many vulnerabilities come from apt-installed packages (Go binaries like gh, docker CLI) or system packages (linux kernel, glibc). These often can't be fixed without upstream updates.

## CI/CD Linting Guidelines

The project uses several linters (Hadolint, ShellCheck, Semgrep) that may produce warnings and errors.

**Philosophy: Fix first, suppress last**

1. **Always try to fix warnings** - Don't just suppress them. Investigate the root cause.
2. **Understand why** - Before ignoring a rule, understand what it's protecting against.
3. **Document exceptions** - If suppression is truly necessary, add a comment explaining why.
4. **Suppress narrowly** - Prefer inline suppressions over global ignores when possible.

**When suppression is acceptable:**
- The warning is a false positive for our specific use case
- Fixing would break intended functionality (e.g., DL3002 - we need root for entrypoint)
- The fix is not possible due to upstream constraints (e.g., apt-installed packages)

**Configuration files:**
- `.hadolint.yaml` - Dockerfile linting rules
- `.shellcheckrc` - Shell script linting (if created)
- `.trivyignore` - Vulnerability exceptions (with CVE documentation)

## Review Requirements

### Addressing PR Feedback
When asked to address PR reviews:
1. Read ALL comments on the PR - both formal reviews and regular comments can contain actionable feedback (bots like CodeRabbit post suggestions as comments, not reviews)
2. Do NOT blindly apply suggested changes - evaluate each suggestion in context
3. If a suggestion seems wrong, unnecessary, or you're unsure about it, ask the user before making changes
4. Some suggestions may conflict with project conventions or introduce issues - use judgment

### Code Review Checklist
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

### Docker Image Tags

| Tag | When Updated | Use Case |
|-----|--------------|----------|
| `latest` | Release tags only (`v1.2.3`) | Stable, recommended for most users |
| `edge` | Every main branch push | Bleeding edge, latest features |
| `1.2.3` | Release tag `v1.2.3` | Pin to specific version |
| `1.2` | Release tag `v1.2.x` | Pin to minor version |
| `1` | Release tag `v1.x.x` | Pin to major version |
| `sha-abc123` | Every build | Pin to exact commit |

**Key principle:** `latest` = stable releases only, `edge` = bleeding edge.

### Debug Issues
```bash
DCLAUDE_DEBUG=true dclaude    # Enable debug output
make verify                    # Run installation verification
```

### User Shortcuts

When the user asks to "kill dclaudes" or "kill dclaude instances":
- Stop and remove all dclaude containers
- Do NOT remove volumes (preserves config and cache)
- Only remove volumes if explicitly asked

```bash
docker ps -a --filter "name=dclaude" -q | xargs -r docker rm -f
```

**Note:** Force-killing containers may leave terminal mouse mode enabled, causing iTerm2 warnings. User should click "Yes" on the iTerm notification or run `printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l'` in the affected terminal. Graceful exit (Ctrl+C or `/exit` in Claude) avoids this issue.

### Iterative Development Workflow

When working iteratively on dclaude changes (especially files in `docker/`):
1. Make the change
2. Rebuild the image (`docker build -t alanbem/dclaude:local docker`)
3. **Automatically kill dclaudes** - don't wait for user to ask
4. User can then test immediately

This speeds up the feedback loop since old containers use the old image.

## References
- Full user documentation: See README.md
- Task management: See tasks/CLAUDE.md
- Task template: tasks/_TASK.md
- Build automation: Makefile
- CI/CD: .github/workflows/