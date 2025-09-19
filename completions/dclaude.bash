#!/bin/bash
# Bash completion for dclaude
# Install: source this file in your .bashrc or copy to /etc/bash_completion.d/

_dclaude_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main options
    opts="--help --version --update --debug --force-host --force-bridge"

    # Environment variables that can be set
    env_vars="DCLAUDE_TAG= DCLAUDE_DEBUG= DCLAUDE_DOCKER_SOCKET= DCLAUDE_NETWORK="

    case "${prev}" in
        dclaude)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        *)
            # Also complete file paths for Claude commands
            COMPREPLY=( $(compgen -f -- ${cur}) )
            ;;
    esac
}

# Only set completion if complete command is available
if command -v complete &> /dev/null; then
    complete -F _dclaude_completions dclaude
fi