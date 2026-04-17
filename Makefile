.PHONY: build run bundle release clean

# Build debug binary
build:
	swift build

# Build and run directly (no app bundle needed for dev)
run: build
	.build/debug/GitHubSentry

# Build debug + create .app bundle
bundle: build
	bash scripts/bundle-app.sh debug

# Build release + create .app bundle
release:
	bash scripts/bundle-app.sh release

# Clean build artifacts
clean:
	swift package clean
	rm -rf build/
