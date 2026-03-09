#!/bin/bash
# claude-launcher.sh - Launches Claude Code with proper $TMUX handling for Agent Teams
#
# Runs as the tmux session command inside dclaude-inner. Controls whether
# Agent Teams uses tmux pane mode (visible panes on host) or in-process mode
# (invisible, all within the main Claude process).
#
# When DCLAUDE_HIDE_TMUX=1: unsets $TMUX so Claude Code uses in-process mode
# When relay env vars are set: keeps $TMUX so Claude Code uses tmux pane mode

if [[ "${DCLAUDE_HIDE_TMUX:-}" == "1" ]]; then
    unset TMUX
    unset TMUX_PANE
fi

# When relay is configured, Claude Code's auto detection can't probe tmux
# through the wrapper, so we explicitly set tmux pane mode
if [[ -n "${DCLAUDE_TMUX_RELAY_PORT:-}" ]]; then
    exec claude --teammate-mode tmux "$@"
fi

exec claude "$@"
