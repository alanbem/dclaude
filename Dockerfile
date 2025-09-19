# Dockerized Claude Code
# Minimal Alpine-based container with Claude CLI, Docker, and MCP support

FROM alpine:3.19

# Install essential packages
RUN apk add --no-cache \
    # Core utilities
    bash \
    curl \
    git \
    jq \
    nano \
    openssh-client \
    # Docker CLI and compose
    docker-cli \
    docker-cli-compose \
    # Node.js for Claude CLI and Node-based MCP servers
    nodejs \
    npm \
    # Python for Python-based MCP servers
    python3 \
    py3-pip \
    # Build tools needed by some npm packages (kept for MCP compatibility)
    make \
    g++ \
    python3-dev

# Create non-root user for running Claude
# Note: sudo removed for security - container should run with appropriate permissions
RUN adduser -D -s /bin/bash claude \
    && addgroup -S docker 2>/dev/null || true \
    && addgroup claude docker

# Switch to claude user
USER claude
WORKDIR /home/claude

# Configure npm to use user directory for global packages
RUN npm config set prefix /home/claude/.npm-global \
    && echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.bashrc \
    && echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.profile

# Set PATH for all tools
ENV PATH="/home/claude/.npm-global/bin:/home/claude/.local/bin:${PATH}"

# Install Claude CLI with audit
RUN npm install -g @anthropic-ai/claude-code

# Create workspace directory
RUN mkdir -p /home/claude/workspace

# Set working directory to workspace
WORKDIR /home/claude/workspace

# Environment variables for Claude
ENV CLAUDE_UNSAFE_TRUST_WORKSPACE=true \
    MCP_TIMEOUT=30000 \
    CLAUDE_BASH_TIMEOUT=600000 \
    CLAUDE_READ_TIMEOUT=300000 \
    CLAUDE_EDIT_TIMEOUT=300000 \
    CLAUDE_WRITE_TIMEOUT=300000 \
    CLAUDE_WEBFETCH_TIMEOUT=300000 \
    TERM=xterm-256color

# Labels
LABEL maintainer="alanbem" \
      description="Dockerized Claude Code with MCP support" \
      version="0.0.1" \
      org.opencontainers.image.source="https://github.com/alanbem/dockerized-claude-code" \
      org.opencontainers.image.documentation="https://github.com/alanbem/dockerized-claude-code/blob/main/README.md" \
      org.opencontainers.image.licenses="MIT"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD claude --version || exit 1

# Default command
ENTRYPOINT ["claude"]
CMD ["--help"]