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
if [ -S "/var/run/docker.sock" ]; then
    SOCKET_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null || stat -f '%g' /var/run/docker.sock 2>/dev/null)
    if [ -n "$SOCKET_GID" ] && [ "$SOCKET_GID" != "1002" ]; then
        # Socket is not in our docker group (1002), we need to adjust
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

            # Now switch to claude user and continue
            # Use gosu to properly switch user and execute command
            exec gosu claude "$@"
        fi
    fi
fi

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

# Execute the command (running as claude user)
exec "$@"