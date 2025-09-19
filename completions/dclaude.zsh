#!/bin/zsh
# Zsh completion for dclaude
# Install: copy to ~/.zsh/completions/ or add to fpath

#compdef dclaude

_dclaude() {
    local -a opts
    opts=(
        '--help[Show help message]'
        '--version[Show version information]'
        '--update[Force update the Docker image]'
        '--debug[Run with debug output]'
    )

    _arguments -C \
        '1: :_dclaude_commands' \
        '*::arg:->args' \
        && ret=0

    case $state in
        args)
            _arguments $opts
            _files
            ;;
    esac
}

_dclaude_commands() {
    local commands
    commands=(
        '--help:Show help message'
        '--version:Show version information'
        '--update:Update Docker image'
        '--debug:Enable debug mode'
    )
    _describe 'command' commands
}

# Environment variables
_dclaude_env() {
    local env_vars
    env_vars=(
        'DCLAUDE_TAG:Docker image tag'
        'DCLAUDE_DEBUG:Enable debug output'
        'DCLAUDE_DOCKER_SOCKET:Docker socket path'
        'DCLAUDE_NETWORK:Network mode'
    )
    _describe 'environment' env_vars
}

compdef _dclaude dclaude