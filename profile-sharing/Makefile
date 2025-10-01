# Profile Sharing App Makefile

.PHONY: help build test clean deploy run-demo

# Default target
help:
	@echo "Profile Sharing App - Available commands:"
	@echo "  build        - Compile the contract"
	@echo "  test         - Run contract tests"
	@echo "  clean        - Clean build artifacts"
	@echo "  deploy       - Deploy contract to sandbox"
	@echo "  run-demo     - Run TypeScript demo"
	@echo "  install-ts   - Install TypeScript dependencies"
	@echo "  build-ts     - Build TypeScript project"

# Contract operations
build:
	@echo "Building contract..."
	cd contract && aztec-nargo compile
	cd contract && aztec-postprocess-contract

test:
	@echo "Running contract tests..."
	cd contract && aztec test

clean:
	@echo "Cleaning build artifacts..."
	cd contract && rm -rf target
	cd ts && rm -rf dist

# Deployment
deploy: build
	@echo "Deploying contract to sandbox..."
	aztec-wallet deploy contract/target/profile_sharing-ProfileSharing.json --from test0 --alias profile-sharing

# TypeScript operations
install-ts:
	@echo "Installing TypeScript dependencies..."
	cd ts && npm install

build-ts: install-ts
	@echo "Building TypeScript project..."
	cd ts && npm run build

run-demo: build-ts
	@echo "Running TypeScript demo..."
	cd ts && npm start

# Development
dev: build-ts
	@echo "Starting development mode..."
	cd ts && npm run dev

# Full setup
setup: install-ts build
	@echo "Setup complete! Run 'make deploy' to deploy the contract."
