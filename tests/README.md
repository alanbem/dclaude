# Tests Directory

This directory contains reusable test scripts, test plans, and test documentation that are version controlled.

## Directory Structure

```
tests/
├── README.md                  # This file
├── TEST_<feature>.md          # Test plans and instructions
├── test_<feature>.sh          # Automated test scripts
├── utils/                     # Shared test utilities
└── fixtures/                  # Static test data
```

## Test Artifacts vs. Test Results

**Test Code (tracked here):**
- Test plans describing how to test features
- Automated test scripts that can be re-run
- Test utilities and helper functions
- Static test fixtures and sample data

**Test Results (not tracked, in `artifacts/`):**
- Output from test runs
- Test execution logs
- One-time analysis documents
- Generated reports

## Running Tests

Individual test scripts can be executed directly:

```bash
# Run port detection test
./tests/test_port_detection.sh

# Follow test plan for SSH feature
# See tests/TEST_SSH_FEATURE.md
```

Test results should be written to `artifacts/RESULTS_<feature>.md`.
