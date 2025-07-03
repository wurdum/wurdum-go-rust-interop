# Go-Rust Interop Example

A minimal example demonstrating how to call Rust functions from Go using CGO and Rust's C FFI.

## What it does

This project shows three simple examples:
- **Addition**: Adding two integers in Rust
- **String processing**: Converting strings to uppercase in Rust
- **Fibonacci**: Calculating Fibonacci numbers in Rust

All functions are called from Go code.

## Prerequisites

- Go 1.21+
- Rust (latest stable)
- C compiler (for CGO)
- Make

## Build and Run

```bash
# Build everything
make all

# Run the demo
make run-all
```

## Available Commands

- `make all` - Build Rust library and Go binary
- `make run-all` - Build and run the complete application
- `make clean` - Clean all build artifacts
- `make dev` - Build in debug mode for development

## How it works

1. Rust functions are marked with `#[no_mangle]` and `extern "C"`
2. Go uses CGO to declare and call these functions
3. The Makefile handles cross-platform building and linking
