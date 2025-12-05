# Artifacts Directory

This directory contains ephemeral outputs that are NOT tracked in git.

## What Goes Here

**Test Results:**
- `RESULTS_<feature>.md` - Output from test runs
- Test execution logs
- Performance measurements

**One-Time Documents:**
- `scratch_*.md` - Temporary analysis documents
- Investigation notes
- Debugging artifacts

**Generated Files:**
- Build outputs
- Generated reports
- Compilation artifacts

**Intermediary Data:**
- Temporary data files
- Cache files
- Download artifacts

## Why This Directory Exists

The `artifacts/` directory provides a consistent location for ephemeral files without cluttering the repository. All contents are gitignored.

For reusable test code and documentation, use the `tests/` directory instead (tracked in git).
