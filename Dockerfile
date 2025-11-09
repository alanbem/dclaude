# Dockerized Claude Code
# Ubuntu-based container with Claude CLI, Docker, Homebrew, and MCP support

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && apt-get install -y \
    # Core utilities
    bash \
    curl \
    git \
    jq \
    nano \
    openssh-client \
    socat \
    gosu \
    procps \
    file \
    tmux \
    locales \
    # Build tools (required for Homebrew)
    build-essential \
    # Docker CLI installation dependencies
    ca-certificates \
    gnupg \
    lsb-release \
    # Python for Python-based MCP servers
    python3 \
    python3-pip \
    python3-dev \
    # Node.js installation dependencies
    && rm -rf /var/lib/apt/lists/*

# Configure UTF-8 locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen en_US.UTF-8

# Install Node.js 20.x (for Claude CLI and Node-based MCP servers)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI and Docker Compose
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for running Claude
# Note: Container starts as root for entrypoint setup, then switches to claude user
RUN useradd -m -s /bin/bash claude \
    && groupadd docker \
    && usermod -aG docker claude

# Install Homebrew as linuxbrew user (Homebrew's recommended approach)
RUN useradd -m -s /bin/bash linuxbrew \
    && usermod -aG sudo linuxbrew \
    && mkdir -p /home/linuxbrew/.linuxbrew \
    && chown -R linuxbrew:linuxbrew /home/linuxbrew/.linuxbrew

# Install Homebrew
USER linuxbrew
WORKDIR /home/linuxbrew
RUN curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

# Switch back to root to configure system-wide access
USER root

# Make Homebrew accessible to all users including claude
# Add claude to linuxbrew group and set proper permissions
RUN usermod -aG linuxbrew claude \
    && chmod -R g+w /home/linuxbrew/.linuxbrew \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /etc/profile.d/brew.sh \
    && chmod +x /etc/profile.d/brew.sh

# Set PATH for all tools (including Homebrew)
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/claude/.npm-global/bin:/home/claude/.local/bin:${PATH}"

# Configure Homebrew environment
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew" \
    HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar" \
    HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

# Switch to claude user temporarily for npm/package setup
USER claude
WORKDIR /home/claude

# Configure npm to use user directory for global packages
RUN npm config set prefix /home/claude/.npm-global \
    && echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.bashrc \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc \
    && echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.profile \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile

# Install Claude CLI
RUN npm install -g @anthropic-ai/claude-code

# Create workspace and necessary directories with correct ownership
RUN mkdir -p /home/claude/workspace \
    /home/claude/.claude \
    /home/claude/.config \
    /home/claude/.cache

# Switch back to root for entrypoint permission handling
USER root

# Declare .claude as a volume for persistent data
VOLUME ["/home/claude/.claude"]

# Copy entrypoint script and tmux config
COPY --chown=claude:claude docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chown=claude:claude .tmux.conf /home/claude/.tmux.conf
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

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
    TERM=xterm-256color \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

# Labels
LABEL maintainer="alanbem" \
      description="Dockerized Claude Code with Homebrew and MCP support" \
      version="0.0.1" \
      org.opencontainers.image.source="https://github.com/alanbem/dclaude" \
      org.opencontainers.image.documentation="https://github.com/alanbem/dclaude/blob/main/README.md" \
      org.opencontainers.image.licenses="MIT"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD claude --version || exit 1

# Use entrypoint script for config persistence
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "claude"]
CMD []
