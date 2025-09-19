#!/bin/bash
# Generate release notes from git commits
# Usage: ./release-notes.sh [from-tag] [to-tag]

set -euo pipefail

# Check Bash version (we need 4.0+ for associative arrays, fallback to simpler version)
BASH_MAJOR_VERSION="${BASH_VERSION%%.*}"
BASH_MAJOR_VERSION="${BASH_MAJOR_VERSION:-3}"

# Colors
if [[ -t 1 ]]; then
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
else
    readonly BOLD=''
    readonly NC=''
fi

# Arguments
FROM_TAG="${1:-}"
TO_TAG="${2:-HEAD}"

# If no from-tag provided, get the last tag
if [[ -z "$FROM_TAG" ]]; then
    FROM_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [[ -z "$FROM_TAG" ]]; then
        echo "No previous tags found. Showing all commits."
        FROM_TAG=$(git rev-list --max-parents=0 HEAD)
    fi
fi

# Get version from VERSION file
VERSION=$(cat VERSION 2>/dev/null || echo "unknown")

echo -e "${BOLD}Release Notes for v${VERSION}${NC}"
echo -e "${BOLD}========================${NC}"
echo
echo "**Release Date:** $(date +%Y-%m-%d)"
echo

# Get commit range
if [[ "$FROM_TAG" == "$TO_TAG" ]]; then
    RANGE="$FROM_TAG"
else
    RANGE="${FROM_TAG}..${TO_TAG}"
fi

# For older Bash (macOS default 3.2), use simpler approach
if [[ "$BASH_MAJOR_VERSION" -lt 4 ]]; then
    echo "### 📝 Changes"
    echo
    git log --format="- %s" "$RANGE"
    echo
else
    # Use associative arrays for Bash 4+
    declare -A categories
    categories["feat"]="### 🚀 Features"
    categories["fix"]="### 🐛 Bug Fixes"
    categories["docs"]="### 📚 Documentation"
    categories["style"]="### 💄 Style"
    categories["refactor"]="### ♻️ Refactoring"
    categories["perf"]="### ⚡ Performance"
    categories["test"]="### ✅ Tests"
    categories["chore"]="### 🔧 Chores"
    categories["ci"]="### 👷 CI/CD"

    # Temporary files for each category
    for key in "${!categories[@]}"; do
        > "/tmp/release_notes_${key}.txt"
    done
    > "/tmp/release_notes_other.txt"

    # Process commits
    while IFS= read -r line; do
        # Parse commit
        hash=$(echo "$line" | cut -d'|' -f1)
        subject=$(echo "$line" | cut -d'|' -f2)

        # Determine category
        if [[ "$subject" =~ ^feat(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_feat.txt"
        elif [[ "$subject" =~ ^fix(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_fix.txt"
        elif [[ "$subject" =~ ^docs(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_docs.txt"
        elif [[ "$subject" =~ ^style(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_style.txt"
        elif [[ "$subject" =~ ^refactor(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_refactor.txt"
        elif [[ "$subject" =~ ^perf(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_perf.txt"
        elif [[ "$subject" =~ ^test(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_test.txt"
        elif [[ "$subject" =~ ^chore(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_chore.txt"
        elif [[ "$subject" =~ ^ci(\(.*\))?:\ .* ]]; then
            echo "- ${subject#*: }" >> "/tmp/release_notes_ci.txt"
        else
            echo "- ${subject}" >> "/tmp/release_notes_other.txt"
        fi
    done < <(git log --format="%H|%s" "$RANGE")

    # Output categorized commits
    for key in feat fix docs perf refactor test chore ci; do
        if [[ -s "/tmp/release_notes_${key}.txt" ]]; then
            echo "${categories[$key]}"
            echo
            cat "/tmp/release_notes_${key}.txt"
            echo
        fi
    done

    # Other commits
    if [[ -s "/tmp/release_notes_other.txt" ]]; then
        echo "### 📝 Other Changes"
        echo
        cat "/tmp/release_notes_other.txt"
        echo
    fi

    # Cleanup
    for key in "${!categories[@]}"; do
        rm -f "/tmp/release_notes_${key}.txt"
    done
    rm -f "/tmp/release_notes_other.txt"
fi

# Contributors
echo "### 👥 Contributors"
echo
git log --format="- @%an" "$RANGE" | sort -u
echo

# Stats
echo "### 📊 Statistics"
echo
COMMIT_COUNT=$(git rev-list --count "$RANGE")
FILE_COUNT=$(git diff --name-only "$RANGE" 2>/dev/null | wc -l | tr -d ' ')
echo "- **Commits:** $COMMIT_COUNT"
echo "- **Files changed:** $FILE_COUNT"
echo

# Installation
echo "### 📦 Installation"
echo
echo '```bash'
echo '# Via NPM'
echo "npm install -g @alanbem/dclaude@${VERSION}"
echo ''
echo '# Via Docker'
echo "docker pull alanbem/dclaude:${VERSION}"
echo '```'