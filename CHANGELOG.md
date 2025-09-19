# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Smart Network Detection**: Auto-detects optimal networking mode for each platform
- **Host Networking Support**: Full localhost access when platform supports it (Linux native, macOS with Docker Desktop beta/OrbStack, Windows with Docker Desktop beta)
- **Network Mode Caching**: 24-hour cache of network capability detection for faster startup
- **Command-Line Network Controls**: `--force-host` and `--force-bridge` flags for network mode override
- **Environment Variable Controls**: `DCLAUDE_NETWORK` environment variable with `auto`, `host`, `bridge` values
- **Platform-Specific Network Validation**: Warns about unusual network configurations per platform
- **Enhanced Debug Output**: Comprehensive network detection logging with `DCLAUDE_DEBUG=true`
- **Network Troubleshooting**: Detailed troubleshooting documentation for network access issues

### Changed
- **Default Network Mode**: Changed from platform-specific defaults to auto-detection
- **Network Documentation**: Comprehensive networking section in README with examples and troubleshooting
- **Help Documentation**: Updated help text with networking options and examples

### Fixed
- **Network Detection Reliability**: Robust testing with timeout protection and graceful fallbacks
- **Cache Management**: Proper cache validation with age checking and error handling

## [0.0.1] - 2024-01-19

### Added
- Initial release of Dockerized Claude Code
- Docker container with Alpine Linux 3.19 base
- Full MCP (Model Context Protocol) support with Node.js and Python
- `dclaude` launcher script with platform detection
- NPM package distribution as `@alanbem/dclaude`
- Docker Hub automated builds for `alanbem/dclaude`
- GitHub Actions CI/CD pipelines
- Named Docker volumes for persistent data
- Path mirroring between host and container
- Docker socket mounting for container management
- Cross-platform support (Linux, macOS, Windows)
- Debug mode and comprehensive error handling
- Automatic image updates on launch

### Security
- Non-root user execution in container
- Conditional Docker socket mounting
- Security warnings and documentation

[0.0.1]: https://github.com/alanbem/dclaude/releases/tag/v0.0.1