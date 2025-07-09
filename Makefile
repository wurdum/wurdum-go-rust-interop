.PHONY: all clean prepare
.PHONY: build-all build-rust-all build-go-all build-dotnet-all
.PHONY: test-all

# Project configuration
GO_BINARY_NAME=wurdum-go-interop
DOTNET_BINARY_NAME=WurdumRustInterop
DIST_DIR=dist
RUST_DIR=rustlib
DOTNET_DIR=dotnet
GO_DIR=go

# Default to host platform if not specified
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Normalize OS names
ifeq ($(UNAME_S),Linux)
    HOST_OS := linux
else ifeq ($(UNAME_S),Darwin)
    HOST_OS := darwin
else ifeq ($(OS),Windows_NT)
    HOST_OS := windows
else
    HOST_OS := unknown
endif

# Normalize architecture names
ifeq ($(UNAME_M),x86_64)
    HOST_ARCH := amd64
else ifeq ($(UNAME_M),aarch64)
    HOST_ARCH := arm64
else ifeq ($(UNAME_M),arm64)
    HOST_ARCH := arm64
else ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
    HOST_ARCH := amd64
else ifeq ($(PROCESSOR_ARCHITECTURE),ARM64)
    HOST_ARCH := arm64
else
    HOST_ARCH := unknown
endif

# Target platform can be overridden
TARGET_OS ?= $(HOST_OS)
TARGET_ARCH ?= $(HOST_ARCH)

# Platform-specific configurations
# Library naming conventions
LIB_PREFIX_windows =
LIB_PREFIX_linux = lib
LIB_PREFIX_darwin = lib

# Static library extensions
LIB_EXT_windows = lib
LIB_EXT_linux = a
LIB_EXT_darwin = a

# Dynamic library extensions
DLL_EXT_windows = dll
DLL_EXT_linux = so
DLL_EXT_darwin = dylib

EXE_EXT_windows = .exe
EXE_EXT_linux =
EXE_EXT_darwin =

# Rust target triples
RUST_TARGET_windows_amd64 = x86_64-pc-windows-gnu
RUST_TARGET_windows_arm64 = aarch64-pc-windows-gnu
RUST_TARGET_darwin_amd64 = x86_64-apple-darwin
RUST_TARGET_darwin_arm64 = aarch64-apple-darwin
RUST_TARGET_linux_amd64 = x86_64-unknown-linux-gnu
RUST_TARGET_linux_arm64 = aarch64-unknown-linux-gnu

# Go environment variables
GO_ENV_windows_amd64 = GOOS=windows GOARCH=amd64 CGO_ENABLED=1
GO_ENV_windows_arm64 = GOOS=windows GOARCH=arm64 CGO_ENABLED=1
GO_ENV_darwin_amd64 = GOOS=darwin GOARCH=amd64 CGO_ENABLED=1
GO_ENV_darwin_arm64 = GOOS=darwin GOARCH=arm64 CGO_ENABLED=1
GO_ENV_linux_amd64 = GOOS=linux GOARCH=amd64 CGO_ENABLED=1
GO_ENV_linux_arm64 = GOOS=linux GOARCH=arm64 CGO_ENABLED=1

# .NET Runtime Identifiers
DOTNET_RID_windows_amd64 = win-x64
DOTNET_RID_windows_arm64 = win-arm64
DOTNET_RID_darwin_amd64 = osx-x64
DOTNET_RID_darwin_arm64 = osx-arm64
DOTNET_RID_linux_amd64 = linux-x64
DOTNET_RID_linux_arm64 = linux-arm64

# Build for current platform
all: build-$(HOST_OS)-$(HOST_ARCH)

# Build for all platforms (when on CI with matrix)
build-all: build-rust-all build-go-all build-dotnet-all

# Clean everything
clean:
	cd $(RUST_DIR) && cargo clean
	cd $(DOTNET_DIR) && dotnet clean
	rm -rf $(DIST_DIR)

# Prepare directory structure
prepare:
	@mkdir -p $(DIST_DIR)

prepare-platform:
	@mkdir -p $(DIST_DIR)/$(TARGET_OS)-$(TARGET_ARCH)

# =============================================================================
# Platform-specific build targets
# =============================================================================

# Windows AMD64
build-windows-amd64: TARGET_OS=windows
build-windows-amd64: TARGET_ARCH=amd64
build-windows-amd64: prepare-platform
	@echo "Building for Windows AMD64..."
	@$(MAKE) build-rust-target
	@$(MAKE) build-go-target
	@$(MAKE) build-dotnet-target

# Windows ARM64
build-windows-arm64: TARGET_OS=windows
build-windows-arm64: TARGET_ARCH=arm64
build-windows-arm64: prepare-platform
	@echo "Building for Windows ARM64..."
	@$(MAKE) build-rust-target
	@$(MAKE) build-go-target
	@$(MAKE) build-dotnet-target

# Darwin (macOS) AMD64
build-darwin-amd64: TARGET_OS=darwin
build-darwin-amd64: TARGET_ARCH=amd64
build-darwin-amd64: prepare-platform
	@echo "Building for macOS AMD64..."
	@$(MAKE) build-rust-target
	@$(MAKE) build-go-target
	@$(MAKE) build-dotnet-target

# Darwin (macOS) ARM64
build-darwin-arm64: TARGET_OS=darwin
build-darwin-arm64: TARGET_ARCH=arm64
build-darwin-arm64: prepare-platform
	@echo "Building for macOS ARM64..."
	@$(MAKE) build-rust-target
	@$(MAKE) build-go-target
	@$(MAKE) build-dotnet-target

# Linux AMD64
build-linux-amd64: TARGET_OS=linux
build-linux-amd64: TARGET_ARCH=amd64
build-linux-amd64: prepare-platform
	@echo "Building for Linux AMD64..."
	@$(MAKE) build-rust-target
	@$(MAKE) build-go-target
	@$(MAKE) build-dotnet-target

# Linux ARM64
build-linux-arm64: TARGET_OS=linux
build-linux-arm64: TARGET_ARCH=arm64
build-linux-arm64: prepare-platform
	@echo "Building for Linux ARM64..."
	@$(MAKE) build-rust-target
	@$(MAKE) build-go-target
	@$(MAKE) build-dotnet-target

# =============================================================================
# Component build targets (used by platform-specific targets)
# =============================================================================

# Build Rust library for target platform
build-rust-target:
	@echo "  Building Rust library for $(TARGET_OS)-$(TARGET_ARCH)..."
	cd $(RUST_DIR) && \
		rustup target add $(RUST_TARGET_$(TARGET_OS)_$(TARGET_ARCH)) 2>/dev/null || true && \
		cargo build --release --target $(RUST_TARGET_$(TARGET_OS)_$(TARGET_ARCH))
	@echo "  Copying static library for Go..."
	@cp $(RUST_DIR)/target/$(RUST_TARGET_$(TARGET_OS)_$(TARGET_ARCH))/release/$(LIB_PREFIX_$(TARGET_OS))rustlib.$(LIB_EXT_$(TARGET_OS)) \
		$(DIST_DIR)/$(TARGET_OS)-$(TARGET_ARCH)/
	@echo "  Copying dynamic library for .NET..."
	@cp $(RUST_DIR)/target/$(RUST_TARGET_$(TARGET_OS)_$(TARGET_ARCH))/release/$(LIB_PREFIX_$(TARGET_OS))rustlib.$(DLL_EXT_$(TARGET_OS)) \
		$(DIST_DIR)/$(TARGET_OS)-$(TARGET_ARCH)/ 2>/dev/null || true

# Build Go binary for target platform
build-go-target:
	@echo "  Building Go binary for $(TARGET_OS)-$(TARGET_ARCH)..."
	cd $(GO_DIR) && \
		$(GO_ENV_$(TARGET_OS)_$(TARGET_ARCH)) \
		go build -o ../$(DIST_DIR)/$(TARGET_OS)-$(TARGET_ARCH)/$(GO_BINARY_NAME)$(EXE_EXT_$(TARGET_OS)) main.go

# Build .NET binary for target platform
build-dotnet-target:
	@echo "  Building .NET binary for $(TARGET_OS)-$(TARGET_ARCH)..."
	cd $(DOTNET_DIR) && \
		dotnet build -c Release -r $(DOTNET_RID_$(TARGET_OS)_$(TARGET_ARCH)) \
		-o ../$(DIST_DIR)/$(TARGET_OS)-$(TARGET_ARCH)

# =============================================================================
# Test targets
# =============================================================================

# Test current platform
test: test-$(HOST_OS)-$(HOST_ARCH)

# Test Windows AMD64
test-windows-amd64:
	@echo "Testing Windows AMD64 build..."
	@ls -l $(DIST_DIR)/windows-amd64
	cd $(DIST_DIR)/windows-amd64 && ./$(GO_BINARY_NAME).exe
	cd $(DIST_DIR)/windows-amd64 && dotnet ./wurdum-dotnet-interop.dll

# Test Windows ARM64
test-windows-arm64:
	@echo "Testing Windows ARM64 build..."
	@ls -l $(DIST_DIR)/windows-arm64
	cd $(DIST_DIR)/windows-arm64 && ./$(GO_BINARY_NAME).exe
	cd $(DIST_DIR)/windows-arm64 && dotnet ./wurdum-dotnet-interop.dll

# Test Darwin AMD64
test-darwin-amd64:
	@echo "Testing macOS AMD64 build..."
	@ls -l $(DIST_DIR)/darwin-amd64
	cd $(DIST_DIR)/darwin-amd64 && ./$(GO_BINARY_NAME)
	cd $(DIST_DIR)/darwin-amd64 && dotnet ./wurdum-dotnet-interop.dll

# Test Darwin ARM64
test-darwin-arm64:
	@echo "Testing macOS ARM64 build..."
	@ls -l $(DIST_DIR)/darwin-arm64
	cd $(DIST_DIR)/darwin-arm64 && ./$(GO_BINARY_NAME)
	cd $(DIST_DIR)/darwin-arm64 && dotnet ./wurdum-dotnet-interop.dll

# Test Linux AMD64
test-linux-amd64:
	@echo "Testing Linux AMD64 build..."
	@ls -l $(DIST_DIR)/linux-amd64
	cd $(DIST_DIR)/linux-amd64 && ./$(GO_BINARY_NAME)
	cd $(DIST_DIR)/linux-amd64 && dotnet ./wurdum-dotnet-interop.dll

# Test Linux ARM64
test-linux-arm64:
	@echo "Testing Linux ARM64 build..."
	@ls -l $(DIST_DIR)/linux-arm64
	cd $(DIST_DIR)/linux-arm64 && ./$(GO_BINARY_NAME)
	cd $(DIST_DIR)/linux-arm64 && dotnet ./wurdum-dotnet-interop.dll

# =============================================================================
# Convenience targets
# =============================================================================

# Build all Windows targets
build-all-windows: build-windows-amd64 build-windows-arm64

# Build all macOS targets
build-all-darwin: build-darwin-amd64 build-darwin-arm64

# Build all Linux targets
build-all-linux: build-linux-amd64 build-linux-arm64

# Run Go binary (current platform)
run-go: build-$(HOST_OS)-$(HOST_ARCH)
	cd $(DIST_DIR)/$(HOST_OS)-$(HOST_ARCH) && ./$(GO_BINARY_NAME)$(EXE_EXT_$(HOST_OS))

# Run .NET binary (current platform)
run-dotnet: build-$(HOST_OS)-$(HOST_ARCH)
	cd $(DIST_DIR)/$(HOST_OS)-$(HOST_ARCH) && dotnet ./wurdum-dotnet-interop.dll

# Run both binaries (current platform)
run-all: run-go run-dotnet

# Legacy compatibility
run: run-go

# Development targets (build debug versions for current platform)
dev-go: TARGET_OS=$(HOST_OS)
dev-go: TARGET_ARCH=$(HOST_ARCH)
dev-go: prepare-platform
	cd $(RUST_DIR) && cargo build
	@cp $(RUST_DIR)/target/debug/$(LIB_PREFIX_$(HOST_OS))rustlib.$(LIB_EXT_$(HOST_OS)) \
		$(DIST_DIR)/$(HOST_OS)-$(HOST_ARCH)/
	cd $(GO_DIR) && go run main.go

dev-dotnet: TARGET_OS=$(HOST_OS)
dev-dotnet: TARGET_ARCH=$(HOST_ARCH)
dev-dotnet: prepare-platform
	cd $(RUST_DIR) && cargo build
	@cp $(RUST_DIR)/target/debug/$(LIB_PREFIX_$(HOST_OS))rustlib.$(LIB_EXT_$(HOST_OS)) \
		$(DIST_DIR)/$(HOST_OS)-$(HOST_ARCH)/
	@cp $(RUST_DIR)/target/debug/$(LIB_PREFIX_$(HOST_OS))rustlib.$(DLL_EXT_$(HOST_OS)) \
		$(DIST_DIR)/$(HOST_OS)-$(HOST_ARCH)/ 2>/dev/null || true
	cd $(DOTNET_DIR) && dotnet run

# Help target
help:
	@echo "Wurdum Go/Rust/.NET Interop - Makefile targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  make build-windows-amd64  - Build for Windows x64"
	@echo "  make build-windows-arm64  - Build for Windows ARM64"
	@echo "  make build-darwin-amd64   - Build for macOS x64"
	@echo "  make build-darwin-arm64   - Build for macOS ARM64"
	@echo "  make build-linux-amd64    - Build for Linux x64"
	@echo "  make build-linux-arm64    - Build for Linux ARM64"
	@echo ""
	@echo "Test targets:"
	@echo "  make test-<os>-<arch>     - Test specific platform build"
	@echo ""
	@echo "Convenience targets:"
	@echo "  make all                  - Build for current platform"
	@echo "  make clean                - Clean all build artifacts"
	@echo "  make run-all              - Run both binaries (current platform)"
	@echo ""
	@echo "Development:"
	@echo "  make dev-go               - Run Go in development mode"
	@echo "  make dev-dotnet           - Run .NET in development mode"
