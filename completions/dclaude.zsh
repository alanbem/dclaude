#!/bin/zsh
# Zsh completion for dclaude
# Install: copy to ~/.zsh/completions/ or add to fpath
#
# Note: dclaude passes all arguments directly to Claude CLI
# Use environment variables to control dclaude behavior:
#   DCLAUDE_NETWORK=host dclaude    # Force host networking
#   DCLAUDE_DEBUG=true dclaude      # Enable debug output
#   DCLAUDE_NO_UPDATE=true dclaude  # Skip image updates

#compdef dclaude

_dclaude() {
    # Since dclaude passes all arguments to Claude,
    # we just provide file/directory completion
    _files
}

# Environment variables that can be set (for reference)
_dclaude_env_info() {
    cat << 'EOF'
Environment variables for dclaude:
  DCLAUDE_TAG              Docker image tag to use
  DCLAUDE_DEBUG            Enable debug output (true/false)
  DCLAUDE_NO_UPDATE        Skip image update check (true/false)
  DCLAUDE_DOCKER_SOCKET    Docker socket path
  DCLAUDE_NETWORK          Network mode (auto/host/bridge)
  DCLAUDE_REGISTRY         Docker registry
  DCLAUDE_SSH              SSH auth mode (auto/agent-forwarding/key-mount/none)
  DCLAUDE_MOUNT_CONFIGS    Enable config mounting (true/false)
  DCLAUDE_MOUNT_DOCKER     Mount .docker/ directory
  DCLAUDE_MOUNT_GIT        Mount .gitconfig file
  DCLAUDE_MOUNT_GH         Mount .config/gh/ for GitHub CLI
  DCLAUDE_MOUNT_NPM        Mount .npmrc file
  CLAUDE_MODEL             Claude model to use
EOF
}

compdef _dclaude dclaude