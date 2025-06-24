.PHONY: all build gate-flamegraph clean

# Default target
all: build

# Build the project
build:
	aztec-nargo compile

# Generate gate flamegraph of a private function
gate-flamegraph:
	@echo "Building gates flamegraph of $(filter-out $@,$(MAKECMDGOALS)) ..."
	SERVE=1 aztec flamegraph target/hello-Hello.json $(filter-out $@,$(MAKECMDGOALS))

# Clean build artifacts
clean:
	rm -rf target/

# Help command
help:
	@echo "Available commands:"
	@echo "  make build  - Compile the project"
	@echo "  make clean  - Remove build artifacts"
	@echo "  make gate-flamegraph <function_name> - Generate gate flamegraph for the given private function"
	@echo "  make help   - Show this help message" 
