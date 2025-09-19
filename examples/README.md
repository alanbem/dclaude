# dclaude Examples

This directory contains example configurations and usage patterns for dclaude.

## Files

### dclaude.config
Example configuration file for dclaude. Copy to `~/.dclaude/config` and customize.

## Usage Examples

### Basic Usage
```bash
# Start Claude interactively
dclaude

# Run with a specific prompt
dclaude "explain this code"

# Process a file
dclaude "review main.js for bugs"
```

### With Environment Variables
```bash
# Use a specific Docker image tag
DCLAUDE_TAG=v0.0.1 dclaude

# Enable debug mode
DCLAUDE_DEBUG=true dclaude

# Use a specific Claude model
CLAUDE_MODEL=claude-3-opus dclaude
```

### Docker Management Examples
```bash
# Let Claude manage your Docker containers
dclaude "list all running containers and their resource usage"

# Build and run a Dockerfile
dclaude "build and run the Dockerfile in current directory"

# Docker compose operations
dclaude "bring up the docker-compose stack and check logs"
```

### Development Workflows
```bash
# Code review
dclaude "review all Python files for security issues"

# Debugging
dclaude "help me debug why the API returns 500 errors"

# Testing
dclaude "write unit tests for utils.js"

# Documentation
dclaude "generate API documentation from the code"
```

### Advanced Usage
```bash
# Custom Docker socket
DCLAUDE_DOCKER_SOCKET=/custom/docker.sock dclaude

# Custom network mode
DCLAUDE_NETWORK=bridge dclaude

# With config file
cp examples/dclaude.config ~/.dclaude/config
# Edit ~/.dclaude/config with your preferences
dclaude # Uses your config
```

## Tips

1. **First Run**: On first run, dclaude will download the Docker image which may take a few minutes.

2. **Persistent Data**: Your Claude settings are stored in Docker volumes and persist between sessions.

3. **Updates**: Run `dclaude --update` periodically to get the latest Claude CLI version.

4. **Debug Issues**: If something isn't working, run with `DCLAUDE_DEBUG=true dclaude` to see detailed output.

5. **Shell Completion**: Source the completion scripts for tab completion:
   ```bash
   # Bash
   source completions/dclaude.bash

   # Zsh
   source completions/dclaude.zsh
   ```