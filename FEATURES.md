# FEATURES.md - Potential Features & Ideas

## Purpose
This document tracks potential features, improvements, and ideas for dclaude. Not all items will be implemented - this serves as a brainstorming space and feature backlog.

## Planned Features

### Session Management with Screen/Tmux (Within Container Lifetime)
- **Description**: Run Claude in a screen or tmux session within the ephemeral container
- **Use Case**: Detach/reattach to Claude sessions while container is running
- **Benefits**:
  - Keep Claude running while doing other work in same container session
  - Multiple concurrent Claude sessions in screen tabs/windows
  - Switch between Claude and shell without losing Claude state
  - No persistent containers to manage
- **Implementation Ideas**:
  - Add screen (or tmux) to Dockerfile
  - Option 1: Auto-start Claude in screen on container launch
  - Option 2: Add wrapper script to start Claude in screen
  - Add helper command: `dclaude --screen` to start in screen mode
  - Document: While container runs, can detach (Ctrl+A,D) and reattach (`screen -r`)
  - Note: Sessions lost when container exits (use `exit` to leave container)
- **Complexity**: Low

### SSH & Tool Configuration Mounting
- **Description**: Mount host's SSH and tool configs into container for seamless integration
- **Use Case**: Use existing SSH keys, GitHub CLI auth, and other tool configurations
- **Benefits**:
  - No need to regenerate SSH keys or re-authenticate tools
  - Consistent configuration across host and container
  - Git operations and GitHub CLI work immediately
  - Docker push/pull from private registries works without re-login
- **Implementation Considerations**:
  - Mount multiple config directories (read-only for security):
    - `~/.ssh` → `/home/claude/.ssh` (SSH keys)
    - `~/.docker` → `/home/claude/.docker` (Docker registry auth)
    - `~/.config/gh` → `/home/claude/.config/gh` (GitHub CLI auth)
    - `~/.gitconfig` → `/home/claude/.gitconfig` (Git configuration)
    - `~/.npmrc` → `/home/claude/.npmrc` (NPM auth, optional)
  - Platform detection for paths:
    - Linux/macOS: `~/.ssh`, `~/.config/`, `~/.docker/`
    - Windows: `%USERPROFILE%\.ssh`, `%APPDATA%\`, `%USERPROFILE%\.docker\`
  - Additional tool configs to consider:
    - `~/.aws` → `/home/claude/.aws` (AWS credentials and config)
    - `~/.kube` → `/home/claude/.kube` (Kubernetes configs)
    - `~/.gcloud` → `/home/claude/.gcloud` (Google Cloud config)
  - Add `gh` CLI to Dockerfile when config mounting is enabled
  - Optional via environment variable (DCLAUDE_MOUNT_CONFIGS=true)
- **Tool Integration**:
  - Docker: Uses mounted `~/.docker/config.json` for registry authentication
  - GitHub CLI: Pre-installed, uses mounted auth from `~/.config/gh/`
  - Git: Uses mounted `.gitconfig` and SSH keys
  - NPM: Optional mounting of `.npmrc` for private registries
- **Security Notes**:
  - Should be opt-in feature
  - All mounts should be read-only
  - Document which configs are being shared
- **Complexity**: Low-Medium

### Enhanced Developer Tools Bundle
- **Description**: Pre-install all commonly used development tools in the container
- **Use Case**: Have familiar tools available without installation during each session
- **Implementation Timeline**:

  **Near Future (Priority)**:
  - **GitHub Integration**:
    - `gh` - GitHub CLI for PR/issue management
  - **Development Utilities** (AI-friendly tools):
    - `jq` - JSON processor (already included) - parse API responses, configs
    - `yq` - YAML processor - manipulate k8s manifests, configs
    - `httpie` - Modern HTTP client - test APIs with readable syntax
    - `fzf` - Fuzzy finder - interactive selection from lists
    - `ripgrep` (`rg`) - Fast grep - search codebases efficiently
    - `fd` - Fast find alternative - locate files quickly
    - `bat` - Better cat with syntax highlighting - show code with context
    - `eza` - Modern ls replacement - understand directory structures
    - `tree` - Directory tree visualization - show project structure
    - `tldr` - Simplified man pages - quick command examples
    - `cheat` - Interactive cheatsheets - command snippets
    - `glow` - Markdown renderer in terminal - render docs beautifully
    - `mdcat` - Another markdown renderer with images
    - `pandoc` - Universal document converter - transform between formats
    - `entr` - Run commands on file change - automation helper
    - `watchexec` - Similar to entr but more features
    - `just` - Command runner (like make but simpler) - task automation
    - `sd` - Intuitive find & replace - better than sed for Claude
    - `delta` - Better git diff - understand code changes
    - `difftastic` - Structural diff - language-aware diffs
    - `tokei` - Code statistics - analyze project composition
    - `scc` - Code counter with complexity - understand codebases
    - `gron` - Make JSON greppable - flatten JSON for processing
    - `xsv` - CSV data manipulation - process data files
    - `miller` - Like awk/sed for CSV/JSON - data transformation
    - `visidata` - Terminal spreadsheet - explore data interactively
  - **Cloud Provider CLIs**:
    - `aws` CLI - AWS services management
    - `gcloud` - Google Cloud Platform
    - `az` - Azure CLI
    - `doctl` - DigitalOcean CLI

  **Considered (Future)**:
  - **Version Control & Git Tools**:
    - `glab` - GitLab CLI
    - `tig` - Text-mode interface for git
    - `git-flow` - Git branching model tools
  - **Container & Orchestration**:
    - `kubectl` - Kubernetes control
    - `helm` - Kubernetes package manager
    - `k9s` - Kubernetes TUI
    - `podman` - Alternative container runtime
    - `buildah` - Container image builder
  - **Database Clients**:
    - `psql` - PostgreSQL client
    - `mysql` - MySQL client
    - `mongosh` - MongoDB shell
    - `redis-cli` - Redis client
  - **Language-Specific Tools**:
    - `nvm` - Node Version Manager
    - `pyenv` - Python Version Manager
    - `poetry` - Python dependency management
    - `cargo` - Rust package manager
  - **Monitoring & Debugging**:
    - `htop` - Process viewer
    - `ncdu` - Disk usage analyzer
    - `lazydocker` - Docker TUI
    - `dive` - Docker image explorer

- **Why These Tools Are Great for AI**:
  - **Structured Output**: Tools like `jq`, `yq`, `gron` give predictable, parseable output
  - **Fast Search**: `ripgrep`, `fd` are orders of magnitude faster than traditional tools
  - **Better Context**: `bat`, `delta`, `difftastic` provide syntax highlighting and context
  - **Documentation**: `tldr`, `cheat` provide concise examples Claude can learn from
  - **Automation**: `entr`, `watchexec`, `just` enable Claude to set up workflows
  - **Data Processing**: `xsv`, `miller`, `visidata` let Claude analyze data efficiently
  - **Code Understanding**: `tokei`, `scc` help Claude understand project scale/complexity

- **Implementation Approach**:
  - Install all tools in single image (you're the main user)
  - No variants for now - full installation
  - Add tools progressively starting with Near Future list
- **Considerations**:
  - Image size will grow but acceptable for main user
  - Can optimize later if needed
- **Complexity**: Low-Medium

### Dedicated Workspace Directory
- **Description**: Create a persistent dclaude workspace directory for project files
- **Use Case**: Dedicated space for Claude projects that persists between sessions
- **Benefits**:
  - Clear separation from host filesystem
  - Easy backup and migration
  - Consistent workspace across sessions
- **Implementation Ideas**:
  - Default location: `~/dclaude/` on host
  - Customizable via DCLAUDE_WORKSPACE env var
  - Auto-create if doesn't exist
  - Mount at `/workspace` in container
  - Could include subdirectories:
    - `~/dclaude/projects/` - active projects
    - `~/dclaude/archives/` - completed work
    - `~/dclaude/shared/` - shared resources
- **Complexity**: Low

### Smart Host Networking Detection
- **Description**: Auto-detect and use host networking when available on all platforms
- **Use Case**: Better localhost access for development on macOS/Windows
- **Current Situation**:
  - Linux: Host networking works natively
  - macOS: Docker Desktop beta feature or OrbStack supports it
  - Windows: Docker Desktop beta feature may support it
- **Implementation Ideas**:
  - Test host networking capability on startup:
    ```bash
    # Quick test: run container with host network and check localhost access
    docker run --rm -d --network host --name test-host alpine sleep 2
    # Try to access a localhost port or check network interfaces
    docker exec test-host wget -q -O- http://localhost:80 2>/dev/null && echo "host networking works"
    docker rm -f test-host 2>/dev/null
    ```
  - Cache the result for future runs (in a dotfile or env var)
  - Fall back to bridge mode if host networking fails
  - Add `--force-bridge` and `--force-host` flags to override detection
- **Benefits**:
  - Seamless localhost access on all platforms
  - No more port mapping hassles
  - Better performance for network operations
  - Works automatically with OrbStack
- **Complexity**: Low-Medium

## Ideas & Considerations

### Container Access Improvements
- Within running container: Use screen to manage Claude sessions
- Workflow: Start container → detach from Claude (Ctrl+A,D) → work in shell → reattach (`screen -r`)
- No need for exec since container stays ephemeral

### Enhanced SSH Access (Future)
- Add SSH server to container (dropbear/openssh)
- Generate unique SSH keys per container
- Expose SSH port mapping (e.g., 2222:22)
- Enable true remote Claude access from any device

### Workspace Synchronization
- Optional sync with cloud storage (Dropbox, Google Drive, OneDrive)
- Git-based workspace sync
- Conflict resolution for multi-device usage

### Session Sharing
- Share screen/tmux sessions with teammates
- Read-only observer mode
- Collaborative debugging sessions

## Technical Notes

### Screen vs Tmux Decision
- **Screen**: Simpler, widely available, sufficient for basic needs
- **Tmux**: More features, better scripting, modern
- Recommendation: Start with screen for simplicity, consider tmux if advanced features needed

### SSH Key Security
- Never mount with write permissions
- Consider using SSH agent forwarding instead of mounting
- Document security implications clearly

## Evaluation Criteria

When considering features for implementation:
1. **User Impact**: How many users would benefit?
2. **Technical Feasibility**: Can it be implemented reliably?
3. **Maintenance Burden**: Long-term support requirements
4. **Security Implications**: Does it introduce new risks?
5. **Performance Impact**: Effect on startup time and resource usage
6. **Compatibility**: Works across all supported platforms?

## Contributing Ideas

To propose a new feature:
1. Check if similar idea already exists
2. Include: Description, Use Case, Complexity estimate
3. Optional: Implementation ideas, potential challenges

---

*This is a living document. Features may be added, modified, or removed based on user feedback and project direction.*