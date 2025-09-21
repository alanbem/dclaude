#!/bin/bash
# Bash completion for dclaude
# Install: source this file in your .bashrc or copy to /etc/bash_completion.d/
#
# Note: dclaude passes all arguments directly to Claude CLI
# Use environment variables to control dclaude behavior:
#   DCLAUDE_NETWORK=host dclaude    # Force host networking
#   DCLAUDE_DEBUG=true dclaude      # Enable debug output
#   DCLAUDE_NO_UPDATE=true dclaude  # Skip image updates

_dclaude_completions() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Since dclaude passes all arguments to Claude,
    # we just provide basic file completion
    COMPREPLY=( $(compgen -f -- ${cur}) )

    # Optionally, also complete directories
    if [[ -d "${cur}" ]]; then
        COMPREPLY+=( $(compgen -d -- ${cur}) )
    fi
}

# Only set completion if complete command is available
if command -v complete &> /dev/null; then
    complete -F _dclaude_completions dclaude
fi