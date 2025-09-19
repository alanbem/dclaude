# FEATURES.md - Potential Features & Ideas

## Purpose
This document tracks potential features, improvements, and ideas for dclaude. Not all items will be implemented - this serves as a brainstorming space and feature backlog.

## Planned Features

### Persistent Session Management with Screen/Tmux
- **Description**: Run Claude in a screen or tmux session within the container
- **Use Case**: Exec into container and attach/detach from Claude sessions, enabling persistent work
- **Benefits**:
  - Keep Claude running while doing other work in container
  - Multiple concurrent Claude sessions in tabs/windows
  - Switch between Claude and shell as needed
- **Implementation Ideas**:
  - Add screen/tmux to Dockerfile
  - Auto-start Claude in a named screen session
  - Add `dclaude exec` command to enter running container
  - Commands like: `dclaude exec` → `screen -r claude`
  - Document session management (detach: Ctrl+A,D)
- **Complexity**: Low

### SSH Configuration Mounting
- **Description**: Mount host's .ssh directory into container for key reuse
- **Use Case**: Use existing SSH keys for git operations, remote server access
- **Benefits**:
  - No need to regenerate SSH keys
  - Consistent SSH config across host and container
  - Git operations work seamlessly
- **Implementation Considerations**:
  - Platform detection for SSH directory location:
    - Linux/macOS: `~/.ssh`
    - Windows: `%USERPROFILE%\.ssh`
  - Read-only mount for security
  - Optional via environment variable (DCLAUDE_MOUNT_SSH)
- **Security Notes**:
  - Should be opt-in feature
  - Consider permission implications
- **Complexity**: Low

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
- Simple exec wrapper: `dclaude exec` to enter running container
- Later: `dclaude exec bash` for direct shell access
- Future: `dclaude exec screen -r` to attach to Claude session

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