#!/bin/bash
# tmux-wrapper.sh - Intercepts tmux calls for Agent Teams relay
#
# Installed at /usr/local/bin/tmux (ahead of /usr/bin/tmux in PATH).
# When relay is configured, sends tmux commands as JSON to the host-side
# relay listener. Otherwise passes through to real tmux.
#
# Pass-through conditions (use real tmux):
#   - Any argument is -L (dclaude-inner socket or other named socket)
#   - DCLAUDE_TMUX_RELAY_PORT is not set (no relay configured)
#   - TCP connection to relay fails (graceful fallback)

REAL_TMUX=/usr/bin/tmux

# Pass through if any argument is -L (dclaude-inner or other named socket)
for arg in "$@"; do
    [[ "$arg" == "-L" ]] && exec "$REAL_TMUX" "$@"
done

# Pass through if no relay configured
[[ -z "${DCLAUDE_TMUX_RELAY_PORT:-}" ]] && exec "$REAL_TMUX" "$@"

RELAY_HOST="${DCLAUDE_TMUX_RELAY_HOST:-host.docker.internal}"
RELAY_PORT="$DCLAUDE_TMUX_RELAY_PORT"
RELAY_NONCE="${DCLAUDE_TMUX_RELAY_NONCE:-}"

# Pass args through as-is — no pane ID translation needed.
# Claude Code's teammate pane IDs are already host-side IDs (returned by
# the relay's split-window response). The relay handler injects -t for
# commands that need pane context (display-message, list-panes, etc.)
# via the JSON "pane" field.
args=("$@")

# Build JSON request using jq (--args treats trailing arguments as strings)
if [[ ${#args[@]} -gt 0 ]]; then
    json=$(jq -nc \
        --arg nonce "$RELAY_NONCE" \
        --arg cwd "$(pwd)" \
        --arg pane "${DCLAUDE_HOST_PANE:-}" \
        --args '{nonce: $nonce, cmd: $ARGS.positional, cwd: $cwd, pane: $pane}' \
        -- "${args[@]}") 2>/dev/null
else
    json=$(jq -nc \
        --arg nonce "$RELAY_NONCE" \
        --arg cwd "$(pwd)" \
        --arg pane "${DCLAUDE_HOST_PANE:-}" \
        '{nonce: $nonce, cmd: [], cwd: $cwd, pane: $pane}') 2>/dev/null
fi

# If JSON building failed, fall back
[[ -z "$json" ]] && exec "$REAL_TMUX" "$@"

# Send to relay via TCP and read response
response=""
if exec 3<>/dev/tcp/"$RELAY_HOST"/"$RELAY_PORT" 2>/dev/null; then
    printf '%s\n' "$json" >&3
    response=$(timeout 30 cat <&3)
    exec 3<&-
else
    exec "$REAL_TMUX" "$@"
fi

# Parse response JSON
if [[ -z "$response" ]]; then
    exec "$REAL_TMUX" "$@"
fi

code=$(printf '%s' "$response" | jq -r '.code // 1' 2>/dev/null)
stdout=$(printf '%s' "$response" | jq -r '.stdout // empty' 2>/dev/null)
stderr=$(printf '%s' "$response" | jq -r '.stderr // empty' 2>/dev/null)

[[ -n "$stdout" ]] && printf '%s\n' "$stdout"
[[ -n "$stderr" ]] && printf '%s\n' "$stderr" >&2

exit "${code:-1}"
