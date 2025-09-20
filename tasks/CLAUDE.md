# Task Management for dclaude

## Task Management Workflow

### Starting a New Task
1. Copy the template: `cp tasks/_TASK.md tasks/TASK.md`
2. Work in `tasks/TASK.md` as the active task file
3. Fill in project details, objectives, and phases
4. Work through each phase following the review cycle requirements

### Review Cycle Requirements
- **Minimum**: 2 review cycles per phase (initial + verification)
- **Maximum**: 10 review cycles (then escalate/document blockers)
- **Process**: Implementation → Review → Fix → Re-review → Iterate until clean

### Review Process for Each Phase
1. **Implementation**: Write the code/feature
2. **Initial Review**: Run review agent on the implementation
3. **Fix Issues**: Address all review feedback
4. **Re-Review**: Run review agent again with context of fixes
5. **Iterate**: Repeat steps 3-4 until review passes

### Completing a Task
1. Ensure all phases are complete with passing reviews
2. Move completed `tasks/TASK.md` to `tasks/XXX-short-description.md`
   - XXX = three-digit order number (001, 002, etc.)
   - short-description = brief kebab-case description
3. Update the archive table below

## Completed Tasks Archive

| Task # | File | Description | Completion Date | Review Cycles |
|--------|------|-------------|-----------------|---------------|
| 001 | [001-host-networking-detection.md](001-host-networking-detection.md) | Smart Host Networking Detection | 2025-09-19 | P1: 2, P2: 3, P3: 1, P4: 1 |
| 002 | [002-ssh-tool-config-mounting.md](002-ssh-tool-config-mounting.md) | SSH & Tool Configuration Mounting | 2025-09-20 | P1: 1, P2: 1, P3: 1, P4: 1, P5: 1 |
| 003 | [003-ssh-agent-forwarding.md](003-ssh-agent-forwarding.md) | SSH Agent Forwarding Support | 2025-09-20 | P1: 2, P2: 2, P3: 2, P4: 1, P5: 1 |
| 004 | [004-ssh-agent-socat-proxy.md](004-ssh-agent-socat-proxy.md) | SSH Agent Forwarding via Socat Proxy | 2025-09-20 | P0: 0, P0.5: 0, P1: 1, P2: 1, P3: 0, P4: 0, P5: 0 |
| 005 | [005-docker-socket-tty-ssh-fixes.md](005-docker-socket-tty-ssh-fixes.md) | Docker Socket, TTY Detection & SSH Fixes | 2025-09-20 | P1: 1, P2: 1, P3: 2, P4: 1, P5: 1 |
| 006 | [006-volume-permission-fix.md](006-volume-permission-fix.md) | Volume Permission Fix & Simplification | 2025-09-20 | P1: 1, P2: 1, P3: 1 |
| 007 | [007-unbound-variable-fix.md](007-unbound-variable-fix.md) | Fix Unbound Variable Error | 2025-09-20 | P0: 1, P1: 1, P2: 1 |
| 008 | [008-claude-config-persistence.md](008-claude-config-persistence.md) | Fix Claude Config Persistence & Setup Screen | 2025-09-21 | P0: 1, P1: 1, P2: 1 |

## Task Template Location
- Template: `tasks/_TASK.md`
- Active task: `tasks/TASK.md` (gitignored)
- Use this template for all new feature development tasks

## Review Agent Commands
```bash
# Code Review
Task: Review the [component] implementation for security, reliability, and best practices

# Testing Review
Task: Test the [feature] on different platforms and configurations

# Documentation Review
Task: Review the [documentation] for clarity, completeness, and accuracy
```

## Notes
- Always provide context to review agents about dclaude's architecture
- Ensure agents test actual functionality, not just review syntax
- Document all review findings and fixes in TASK.md
- Keep review cycles focused and iterative