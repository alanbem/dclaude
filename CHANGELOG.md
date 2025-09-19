# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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