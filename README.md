# Go/C#-Rust Interop Example

A cross-platform example demonstrating how to call Rust functions from Go and C# using CGO and .NET's P/Invoke with Rust's C FFI.

## Supported Platforms

This project supports building for the following platforms:
- **Windows**: AMD64, ARM64
- **macOS**: AMD64 (Intel), ARM64 (Apple Silicon)
- **Linux**: AMD64, ARM64

## What it does

This project shows three simple examples:
- **Addition**: Adding two integers in Rust
- **String processing**: Converting strings to uppercase in Rust
- **Fibonacci**: Calculating Fibonacci numbers in Rust
- **Callbacks**: Processing data with callbacks from Go/C# to Rust

All functions are called from both Go and C# code.

## Prerequisites

- Go 1.21+
- .NET 9.0+
- Rust (latest stable)
- C compiler (for CGO)
- Make

For cross-compilation:
- Rust targets installed via `rustup target add <target>`
- Cross-compilation toolchains for Linux ARM64 (if building on Linux)

## Build Commands

### Build for Current Platform
```bash
# Build everything for your current platform
make all

# Or explicitly specify platform
make build-darwin-arm64  # macOS Apple Silicon
make build-linux-amd64   # Linux x64
make build-windows-amd64 # Windows x64
```

### Build for Specific Platforms
```bash
# Windows
make build-windows-amd64  # Windows x64
make build-windows-arm64  # Windows ARM64

# macOS
make build-darwin-amd64   # macOS Intel
make build-darwin-arm64   # macOS Apple Silicon

# Linux
make build-linux-amd64    # Linux x64
make build-linux-arm64    # Linux ARM64
```

### Build All Platforms for an OS
```bash
make build-all-windows    # Both AMD64 and ARM64
make build-all-darwin     # Both AMD64 and ARM64
make build-all-linux      # Both AMD64 and ARM64
```

## Run and Test

### Run on Current Platform
```bash
# Run both Go and .NET examples
make run-all

# Run individually
make run-go
make run-dotnet
```

### Test Specific Platform Build
```bash
make test-darwin-arm64   # Test macOS ARM64 build
make test-linux-amd64    # Test Linux AMD64 build
make test-windows-amd64  # Test Windows AMD64 build
```

## Build Artifacts

All build artifacts are placed in platform-specific directories:
```
dist/
├── windows-amd64/
│   ├── rustlib.lib              # Rust static library (for Go)
│   ├── rustlib.dll              # Rust dynamic library (for .NET)
│   ├── wurdum-go-interop.exe    # Go executable
│   ├── wurdum-dotnet-interop.exe    # .NET executable
│   └── wurdum-dotnet-interop.dll    # .NET assembly
├── darwin-arm64/
│   ├── librustlib.a             # Rust static library (for Go)
│   ├── librustlib.dylib         # Rust dynamic library (for .NET)
│   ├── wurdum-go-interop        # Go executable
│   ├── wurdum-dotnet-interop    # .NET executable
│   └── wurdum-dotnet-interop.dll    # .NET assembly
└── linux-amd64/
│   ├── librustlib.a             # Rust static library (for Go)
│   ├── librustlib.so            # Rust dynamic library (for .NET)
│   └── ... (similar structure)
```

## Development

For development with hot reload:
```bash
make dev-go      # Run Go in development mode
make dev-dotnet  # Run .NET in development mode
```

## CI/CD

The project includes GitHub Actions workflows that:
- Build for all supported platforms
- Run tests on native architectures
- Upload build artifacts
- Create releases with platform-specific tarballs when tags are pushed

## Clean Build Artifacts

```bash
make clean  # Remove all build artifacts
```

## How it works

1. **Rust**: Functions are marked with `#[no_mangle]` and `extern "C"` to expose C-compatible APIs. Builds both static (`.a`/`.lib`) and dynamic (`.so`/`.dll`/`.dylib`) libraries
2. **Go**: Uses CGO with platform-specific LDFLAGS to statically link the Rust library
3. **C#**: Uses P/Invoke with LibraryImport to dynamically load the Rust library, with a custom loader for cross-platform support
4. **Makefile**: Handles cross-platform building with proper target mappings and library type selection
5. **Library Linking**: Go uses static linking for single-file distribution, while .NET uses dynamic linking as required by P/Invoke

## Notes

- The .NET build is framework-dependent and requires .NET 9.0 runtime on the target system
- Go binaries are statically linked with the Rust library (except on macOS where full static linking isn't supported)
- Windows builds use MSVC toolchain
- Cross-compilation from one OS to another requires appropriate toolchains
