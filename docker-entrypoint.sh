#!/bin/sh
# Docker entrypoint for dclaude with config persistence

# Handle config persistence - restore .claude.json from volume if it exists
if [ -f /home/claude/.claude/.claude.json ] && [ ! -f /home/claude/.claude.json ]; then
    cp /home/claude/.claude/.claude.json /home/claude/.claude.json
fi

# Start background process to periodically sync config to volume
(
    while true; do
        sleep 5
        if [ -f /home/claude/.claude.json ]; then
            # Only copy if file has changed (compare timestamps)
            if [ /home/claude/.claude.json -nt /home/claude/.claude/.claude.json ] || [ ! -f /home/claude/.claude/.claude.json ]; then
                cp /home/claude/.claude.json /home/claude/.claude/.claude.json 2>/dev/null || true
            fi
        fi
    done
) &

# Execute the command (already running as claude user)
exec "$@"