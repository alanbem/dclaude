.PHONY: help build test install clean push release verify

# Default target
help:
	@echo "Dockerized Claude Code - Makefile Commands"
	@echo ""
	@echo "  make build      Build Docker image locally"
	@echo "  make test       Run tests"
	@echo "  make install    Install dclaude locally"
	@echo "  make verify     Verify installation"
	@echo "  make clean      Clean build artifacts"
	@echo "  make push       Push to registries (Docker Hub & NPM)"
	@echo "  make release    Create a new release"
	@echo ""

# Build Docker image
build:
	docker build -t alanbem/claude-code:local .
	@echo "✓ Docker image built: alanbem/claude-code:local"

# Run tests
test:
	@echo "Running syntax check..."
	@bash -n dclaude
	@echo "✓ Syntax check passed"
	@echo "Testing Docker image..."
	@if docker image inspect alanbem/claude-code:local &>/dev/null; then \
		docker run --rm alanbem/claude-code:local --version && echo "✓ Docker image test passed"; \
	else \
		echo "⚠️  Local image not found. Run 'make build' first or test will use remote image"; \
		docker run --rm alanbem/claude-code:latest --version 2>/dev/null && echo "✓ Remote image test passed" || echo "✗ No image available for testing"; \
	fi

# Install locally
install:
	@echo "Installing dclaude..."
	@chmod +x dclaude
	@cp dclaude /usr/local/bin/dclaude 2>/dev/null || (echo "Permission denied. Try: sudo make install" && exit 1)
	@echo "✓ dclaude installed to /usr/local/bin/dclaude"

# Verify installation
verify:
	@bash scripts/install-verify.sh

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -f *.tgz
	@docker rmi alanbem/claude-code:local 2>/dev/null || true
	@echo "✓ Cleaned build artifacts"

# Push to registries (requires authentication)
push:
	@echo "Pushing to Docker Hub..."
	docker push alanbem/claude-code:latest
	@echo "Publishing to NPM..."
	npm publish
	@echo "✓ Pushed to registries"

# Create a new release
release:
	@echo "Current version: $$(cat VERSION)"
	@read -p "Enter new version: " VERSION && \
		echo "$$VERSION" > VERSION && \
		npm version $$VERSION --no-git-tag-version && \
		git add VERSION package.json package-lock.json && \
		git commit -m "chore: Release v$$VERSION" && \
		git tag "v$$VERSION" && \
		echo "✓ Release v$$VERSION created" && \
		echo "Run 'git push --tags' to trigger CI/CD"

# Development targets
.PHONY: dev-build dev-run

dev-build:
	docker build -t alanbem/claude-code:dev .

dev-run:
	DCLAUDE_TAG=dev ./dclaude