# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

### Preferred Method

Use [GitHub Security Advisories](../../security/advisories/new) for private discussion and coordinated disclosure. This allows us to:

- Discuss the vulnerability privately
- Develop a fix before public disclosure
- Credit you for the discovery

### Alternative Method

If you cannot use GitHub Security Advisories, open a private security report by:

1. Going to the repository's Security tab
2. Clicking "Report a vulnerability"
3. Including the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes

### What to Expect

| Stage | Timeline |
|-------|----------|
| Initial response | 48 hours |
| Status update | 5 business days |
| Resolution target | 90 days |

### Scope

The following are in scope for security reports:

- Container escape vulnerabilities
- Privilege escalation within the container
- Secret/credential exposure
- Supply chain vulnerabilities in dependencies
- CI/CD pipeline security issues

### Out of Scope

- Vulnerabilities in the upstream Claude CLI (report to Anthropic)
- Vulnerabilities in Docker itself (report to Docker)
- Social engineering attacks
- Physical attacks

## Security Measures

This project implements the following security controls:

- **Non-root container execution** - Claude runs as unprivileged user
- **Automated vulnerability scanning** - Trivy scans on every build
- **Dependency updates** - Dependabot monitors for security updates
- **Image signing** - Cosign keyless signing with OIDC
- **SBOM generation** - Software Bill of Materials for every release
- **Provenance attestations** - Build provenance for supply chain security
