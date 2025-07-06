# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Standard Build Process
- `make all` - Build Rust library and both Go and C# binaries
- `make clean` - Clean all build artifacts
- `make run-all` - Build and run both Go and C# demos

### Individual Language Builds
- `make build-rust` - Build only the Rust shared library
- `make build-go` - Build only the Go binary (requires Rust library)
- `make build-dotnet` - Build only the C# binary (requires Rust library)

### Development Commands
- `make dev-go` - Build Rust in debug mode and run Go program
- `make dev-dotnet` - Build Rust in debug mode and run C# program
- `make run-go` - Run only the Go demo
- `make run-dotnet` - Run only the C# demo

### Manual Commands
- `cd rustlib && cargo build --release` - Build Rust library manually
- `cd dotnet && dotnet run` - Run C# program directly
- `cd go && go run main.go` - Run Go program directly (requires Rust library in dist/)

## Architecture Overview

This project demonstrates **cross-language interoperability** between Rust, Go, and C#. The architecture follows a **C FFI (Foreign Function Interface)** pattern where:

1. **Rust Core Library** (`rustlib/`) - Provides the implementation
   - Functions marked with `#[no_mangle]` and `extern "C"` for C compatibility
   - Configured as both `cdylib` (dynamic) and `staticlib` (static) library
   - Handles memory management for strings and complex data structures

2. **Go Application** (`go/`) - Consumer using CGO
   - Uses `#cgo` directives for linking with platform-specific library paths
   - Implements callback functions exported with `//export` comments
   - Manages memory conversion between Go and C types using `unsafe` package

3. **C# Application** (`dotnet/`) - Consumer using P/Invoke
   - Uses modern `LibraryImport` attribute with source generators
   - Implements sophisticated native library loading with `NativeLibraryLoader`
   - Uses `UnmanagedCallersOnly` for high-performance callback functions

### Key Interop Patterns

**Memory Management**: Rust allocates strings that must be freed by calling `free_rust_string()` from consuming languages.

**Callback Architecture**: Rust accepts function pointers in structs, enabling callbacks from Rust back to Go/C#. Go uses C wrapper functions, while C# uses modern function pointer syntax.

**Platform Abstraction**: Makefile handles cross-platform library extensions (.dylib on macOS, .so on Linux, .dll on Windows) and architecture detection (ARM64 vs x64).

**Build Dependencies**: Both Go and C# applications depend on the Rust library being built first. The `dist/` directory contains all compiled artifacts.

## Platform-Specific Notes

### Library Files
- **macOS**: `librustlib.dylib` (dynamic), `librustlib.a` (static)
- **Linux**: `librustlib.so` (dynamic), `librustlib.a` (static)
- **Windows**: `rustlib.dll` (dynamic), `rustlib.lib` (static)

### C# Runtime Considerations
The C# application uses sophisticated native library loading that searches multiple paths including the executable directory, current directory, and system paths. This ensures the application works whether run from the project root or the `dist/` directory.

### CGO Linking
Go uses conditional CGO directives that link against the appropriate library based on the target platform. The library must be available in `rustlib/target/release/` for the linker to find it. The Go code is located in the `go/` directory and uses relative paths (`../rustlib/target/release/`) to find the Rust library.

## Development Workflow

1. **Make changes to Rust code** in `rustlib/src/lib.rs`
2. **Update function signatures** in Go's CGO comments (`go/main.go`) and C#'s `LibraryImport` declarations
3. **Build and test** using `make run-all` to verify both languages work
4. **For development iterations**, use `make dev-go` or `make dev-dotnet` to use debug builds

## Common Issues

**Missing Library Error**: If you get linking errors, ensure `make build-rust` has been run and the library files exist in `rustlib/target/release/`.

**Callback Crashes**: Ensure callback function signatures match exactly between Rust expectations and Go/C# implementations, particularly calling conventions.

**Memory Leaks**: Always call `free_rust_string()` after receiving string results from Rust functions.