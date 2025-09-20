#!/bin/sh
# Docker entrypoint for dclaude with SSH agent proxy support

# If SSH_AUTH_SOCK is set and we're running as root, set up proxy for claude user
if [ "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ] && [ "$(id -u)" = "0" ]; then
    # Test if claude user can access the socket directly
    if ! su-exec claude sh -c "SSH_AUTH_SOCK=$SSH_AUTH_SOCK ssh-add -l" >/dev/null 2>&1; then
        echo "Setting up SSH agent proxy for non-root user..."

        # Ensure claude's directories exist with correct ownership
        mkdir -p /home/claude/.ssh /home/claude/.claude /home/claude/.claude/plugins
        chown -R claude:claude /home/claude/.ssh /home/claude/.claude

        # Start socat as root to bridge the permission gap
        # Creates a socket owned by claude that forwards to the root-owned socket
        socat UNIX-LISTEN:/home/claude/.ssh/agent,fork,user=claude,group=claude,mode=700 \
              UNIX-CONNECT:"$SSH_AUTH_SOCK" &

        # Brief wait for socket creation
        sleep 0.5

        # Update SSH_AUTH_SOCK for the claude user
        export SSH_AUTH_SOCK=/home/claude/.ssh/agent
    fi

    # Switch to claude user
    exec su-exec claude "$@"
fi

# If not root or no SSH socket, just run normally
exec "$@"