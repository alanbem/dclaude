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

### ✅ IMPLEMENTED: SSH Authentication
- **Status**: Completed on 2025-09-20, simplified on 2025-12-29
- **Implementation**:
  - SSH agent forwarding or key mounting via `DCLAUDE_GIT_AUTH`
  - GitHub CLI (gh) added to Dockerfile - users auth inside container with `dclaude gh`
  - Git config done inside container, persists until container removal
- **Simplified**: Removed host config mounting (DCLAUDE_MOUNT_CONFIGS) in favor of in-container auth
- **Documented**: README.md and CLAUDE.md updated

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