.PHONY: all build-rust build-go build-dotnet run-go run-dotnet clean prepare

# Binary names based on project
GO_BINARY_NAME=wurdum-go-interop
DOTNET_BINARY_NAME=wurdum-dotnet-interop
DIST_DIR=dist
RUST_LIB_DIR=rustlib/target/release
DOTNET_DIR=dotnet
GO_DIR=go

# Detect OS for Linux/macOS support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LIB_EXT=so
    LIB_PREFIX=lib
    DOTNET_RID=linux-x64
endif
ifeq ($(UNAME_S),Darwin)
    LIB_EXT=dylib
    LIB_PREFIX=lib
    # Detect ARM64 vs x64 on macOS
    UNAME_M := $(shell uname -m)
    ifeq ($(UNAME_M),arm64)
        DOTNET_RID=osx-arm64
    else
        DOTNET_RID=osx-x64
    endif
endif

all: prepare build-rust build-go build-dotnet

prepare:
	mkdir -p $(DIST_DIR)

build-rust: prepare
	cd rustlib && cargo build --release
	# Copy Rust library to dist
	cp $(RUST_LIB_DIR)/$(LIB_PREFIX)rustlib.$(LIB_EXT) $(DIST_DIR)/
	cp $(RUST_LIB_DIR)/$(LIB_PREFIX)rustlib.a $(DIST_DIR)/

build-go: prepare build-rust
	cd $(GO_DIR) && go build -o ../$(DIST_DIR)/$(GO_BINARY_NAME) main.go

build-dotnet: prepare build-rust
	cd $(DOTNET_DIR) && dotnet build -c Release -o ../$(DIST_DIR)

run-go: build-go
	cd $(DIST_DIR) && ./$(GO_BINARY_NAME)

run-dotnet: build-dotnet
	cd $(DIST_DIR) && ./$(DOTNET_BINARY_NAME)

run: run-go

run-all: run-go run-dotnet

clean:
	cd rustlib && cargo clean
	cd $(DOTNET_DIR) && dotnet clean
	rm -rf $(DIST_DIR)

# For development with hot reload
dev-go: prepare
	cd rustlib && cargo build
	cp rustlib/target/debug/$(LIB_PREFIX)rustlib.$(LIB_EXT) $(DIST_DIR)/
	cp rustlib/target/debug/$(LIB_PREFIX)rustlib.a $(DIST_DIR)/
	cd $(GO_DIR) && go run main.go

dev-dotnet: prepare
	cd rustlib && cargo build
	cp rustlib/target/debug/$(LIB_PREFIX)rustlib.$(LIB_EXT) $(DIST_DIR)/
	cd $(DOTNET_DIR) && dotnet run
