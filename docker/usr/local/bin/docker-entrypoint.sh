#!/bin/sh
# Docker entrypoint for dclaude with config persistence

# Handle SSH agent proxy setup for macOS (must run as root)
if [ -n "$SSH_AUTH_SOCK" ] && [ -e "$SSH_AUTH_SOCK" ]; then
    # Check if we need to create a proxy socket
    # This is typically needed on macOS where the SSH_AUTH_SOCK has restrictive permissions
    if [ ! -S "/tmp/ssh-proxy/agent" ] && [ -d "/tmp/ssh-proxy" ]; then
        # We're running as root (from docker run), so create the proxy
        # Start socat proxy in background to bridge SSH agent socket
        socat UNIX-LISTEN:/tmp/ssh-proxy/agent,fork,user=claude,group=claude,mode=660 \
              UNIX-CONNECT:$SSH_AUTH_SOCK &

        # Give socat a moment to create the socket
        sleep 0.2
    fi
fi

# Fix permissions for mounted volumes as root before switching user
if [ "$(id -u)" = "0" ]; then
    # Fix .claude volume ownership to match claude user
    if [ -d "/home/claude/.claude" ]; then
        chown -R claude:claude /home/claude/.claude 2>/dev/null || true
    fi
fi

# Fix Docker socket permissions if needed
# On some systems (like OrbStack), the Docker socket group doesn't match our docker group
NEED_USER_SWITCH=false
if [ -S "/var/run/docker.sock" ]; then
    # Use -L to follow symlinks (important on macOS where socket is often symlinked)
    SOCKET_GID=$(stat -L -c '%g' /var/run/docker.sock 2>/dev/null || stat -L -f '%g' /var/run/docker.sock 2>/dev/null)
    
    # Get the GID of our docker group (dynamically, not hardcoded)
    DOCKER_GROUP_GID=$(getent group docker | cut -d: -f3)
    
    if [ -n "$SOCKET_GID" ] && [ -n "$DOCKER_GROUP_GID" ] && [ "$SOCKET_GID" != "$DOCKER_GROUP_GID" ]; then
        # Socket is not in our docker group, we need to adjust
        # Check if we're running as root (can modify groups)
        if [ "$(id -u)" = "0" ]; then
            # If socket is in root group (0), add claude to root group
            # Otherwise, change docker group GID to match socket
            if [ "$SOCKET_GID" = "0" ]; then
                adduser claude root 2>/dev/null || true
            else
                delgroup docker 2>/dev/null || true
                groupadd -g "$SOCKET_GID" docker 2>/dev/null || true
                usermod -aG docker claude 2>/dev/null || true
            fi
            NEED_USER_SWITCH=true
        fi
    fi
fi

# Create wrapper script for config persistence as claude user
cat > /tmp/entrypoint-wrapper.sh << 'WRAPPER_EOF'
#!/bin/sh
# This runs as claude user

# Restore .claude.json from volume if it exists
if [ -f /home/claude/.claude/.claude.json ] && [ ! -f /home/claude/.claude.json ]; then
    cp /home/claude/.claude/.claude.json /home/claude/.claude.json
fi

# Set up trap to sync config on exit
cleanup() {
    if [ -f /home/claude/.claude.json ]; then
        cp /home/claude/.claude.json /home/claude/.claude/.claude.json 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# Start background process to periodically sync config to volume
(
    # Initial sync
    if [ -f /home/claude/.claude.json ]; then
        cp /home/claude/.claude.json /home/claude/.claude/.claude.json 2>/dev/null || true
    fi

    # Watch for changes using inotifywait (efficient event-based sync)
    # We watch the directory because editors/tools often write to temp file and move it
    while inotifywait -e close_write -e moved_to --include '\.claude\.json$' /home/claude 2>/dev/null; do
        cp /home/claude/.claude.json /home/claude/.claude/.claude.json 2>/dev/null || true
    done
) >/dev/null 2>&1 &

# Execute the actual command
exec "$@"
WRAPPER_EOF

chmod +x /tmp/entrypoint-wrapper.sh

# Switch to claude user if needed, otherwise just run wrapper
if [ "$NEED_USER_SWITCH" = "true" ]; then
    exec gosu claude /tmp/entrypoint-wrapper.sh "$@"
else
    exec /tmp/entrypoint-wrapper.sh "$@"
fi