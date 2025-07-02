.PHONY: all build-rust build-go run clean prepare

# Binary name based on project
BINARY_NAME=wurdum-interop
DIST_DIR=dist
RUST_LIB_DIR=rustlib/target/release

# Detect OS for Linux/macOS support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LIB_EXT=so
    LIB_PREFIX=lib
endif
ifeq ($(UNAME_S),Darwin)
    LIB_EXT=dylib
    LIB_PREFIX=lib
endif

all: prepare build-rust build-go

prepare:
	mkdir -p $(DIST_DIR)

build-rust:
	cd rustlib && cargo build --release
	# Copy Rust library to dist
	cp $(RUST_LIB_DIR)/$(LIB_PREFIX)rustlib.$(LIB_EXT) $(DIST_DIR)/
	cp $(RUST_LIB_DIR)/$(LIB_PREFIX)rustlib.a $(DIST_DIR)/

build-go: build-rust
	go build -o $(DIST_DIR)/$(BINARY_NAME) main.go

run: all
	cd $(DIST_DIR) && ./$(BINARY_NAME)

clean:
	cd rustlib && cargo clean
	rm -rf $(DIST_DIR)

# For development with hot reload
dev: prepare
	cd rustlib && cargo build
	cp rustlib/target/debug/$(LIB_PREFIX)rustlib.$(LIB_EXT) $(DIST_DIR)/
	cp rustlib/target/debug/$(LIB_PREFIX)rustlib.a $(DIST_DIR)/
	go run main.go
