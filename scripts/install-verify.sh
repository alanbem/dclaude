#!/bin/bash
# Installation verification script for dclaude
# Checks system compatibility and installation status

set -euo pipefail

# Colors
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

# Functions
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo "==================================="
echo "  dclaude Installation Verifier"
echo "==================================="
echo

# Check operating system
echo "Checking system compatibility..."
OS="$(uname -s)"
case "${OS}" in
    Linux*)
        success "Operating System: Linux"
        ;;
    Darwin*)
        success "Operating System: macOS"
        ;;
    MINGW*|CYGWIN*|MSYS*)
        warning "Operating System: Windows (requires WSL2 or Docker Desktop)"
        ;;
    *)
        error "Operating System: Unknown (${OS})"
        exit 1
        ;;
esac

# Check architecture
ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64|amd64)
        success "Architecture: AMD64"
        ;;
    arm64|aarch64)
        success "Architecture: ARM64"
        ;;
    *)
        error "Architecture: ${ARCH} (unsupported)"
        exit 1
        ;;
esac

echo
echo "Checking Docker installation..."

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    success "Docker installed: ${DOCKER_VERSION}"
else
    error "Docker not installed"
    echo "  Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker daemon
if docker info &> /dev/null; then
    success "Docker daemon running"
else
    error "Docker daemon not running"
    echo "  Please start Docker"
    exit 1
fi

# Check Docker socket
if [[ -S "/var/run/docker.sock" ]]; then
    success "Docker socket available"
else
    warning "Docker socket not found at /var/run/docker.sock"
    echo "  Container will not have Docker access"
fi

echo
echo "Checking dclaude installation..."

# Check if dclaude is installed
if command -v dclaude &> /dev/null; then
    DCLAUDE_PATH=$(command -v dclaude)
    success "dclaude installed: ${DCLAUDE_PATH}"

    # Check version
    if dclaude --version &> /dev/null; then
        info "Version check passed"
    else
        warning "Could not verify dclaude version"
    fi
else
    warning "dclaude not found in PATH"
    echo "  Install with: npm install -g @alanbem/dclaude"
fi

# Check for local dclaude script
if [[ -f "./dclaude" ]]; then
    info "Local dclaude script found"
    if [[ -x "./dclaude" ]]; then
        success "Local script is executable"
    else
        warning "Local script is not executable"
        echo "  Run: chmod +x ./dclaude"
    fi
fi

echo
echo "Checking Docker image..."

# Check if image exists
IMAGE="alanbem/claude-code:latest"
if docker image inspect "${IMAGE}" &> /dev/null; then
    success "Docker image exists: ${IMAGE}"
    IMAGE_ID=$(docker image inspect "${IMAGE}" --format='{{.Id}}' | cut -d: -f2 | head -c 12)
    info "Image ID: ${IMAGE_ID}"
else
    warning "Docker image not found locally"
    echo "  It will be downloaded on first run"
fi

# Check volumes
echo
echo "Checking Docker volumes..."
for vol in dclaude-config dclaude-cache dclaude-claude; do
    if docker volume inspect "$vol" &> /dev/null; then
        success "Volume exists: $vol"
    else
        info "Volume not found: $vol (will be created on first run)"
    fi
done

# Check Node.js/npm (for development)
echo
echo "Checking Node.js/npm (optional)..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    success "Node.js installed: ${NODE_VERSION}"
else
    info "Node.js not installed (only needed for npm installation)"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    success "npm installed: ${NPM_VERSION}"
else
    info "npm not installed (only needed for npm installation)"
fi

# Summary
echo
echo "==================================="
echo "        Verification Summary"
echo "==================================="

READY=true

if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
    error "Docker is required but not available"
    READY=false
fi

if ! command -v dclaude &> /dev/null && [[ ! -f "./dclaude" ]]; then
    warning "dclaude not installed"
    echo "  Install with one of:"
    echo "    npm install -g @alanbem/dclaude"
    echo "    curl -fsSL https://raw.githubusercontent.com/alanbem/dockerized-claude-code/main/dclaude -o dclaude && chmod +x dclaude"
    READY=false
fi

if [[ "$READY" == "true" ]]; then
    echo
    success "System is ready to run dclaude!"
    echo
    echo "Quick start:"
    echo "  dclaude --help"
    exit 0
else
    echo
    error "System is not ready. Please fix the issues above."
    exit 1
fi