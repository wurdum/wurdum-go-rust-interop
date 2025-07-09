# Go/C#-Rust Interop Example

A cross-platform example demonstrating how to call Rust functions from Go and C# using CGO and .NET's P/Invoke with Rust's C FFI.

## Supported Platforms

This project supports building for the following platforms:
- **Windows**: AMD64
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

### All Platforms
- Go 1.21+
- .NET 9.0+ SDK
- Rust (latest stable)
- Make

### Platform-Specific Requirements

#### On Windows

IMPORTANT: The Windows ARM is not supported yet due to limitations with the MinGW-w64 toolchain and CGO. The project currently supports only AMD64 builds on Windows.

1. **Install Rust** from https://rustup.rs/
2. **Install Go** from https://go.dev/dl/
3. **Install .NET 9.0 SDK** from https://dotnet.microsoft.com/download
4. **Install MSYS2** from https://www.msys2.org/
   - This provides the MinGW-w64 toolchain needed for CGO
5. **Configure MinGW-w64 toolchain in MSYS2 MINGW64 terminal**:
   ```bash
   # For AMD64
   pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-toolchain base-devel
   ```
6. **Add Rust targets**:
   ```bash
   # For AMD64
   rustup target add x86_64-pc-windows-gnu
   ```
7. **Update PATH**: Ensure the MSYS2 MinGW64 bin directory (typically `C:\msys64\mingw64\bin`) is in your PATH

**Note**: The project uses MinGW-w64 toolchain on Windows for compatibility with CGO. The Rust library builds both static (`.a`) and dynamic (`.dll`) libraries.

#### On macOS
- Xcode Command Line Tools: `xcode-select --install`

#### On Linux
For cross-compilation to ARM64:
- Cross-compilation toolchains: `gcc-aarch64-linux-gnu`

### For Cross-Compilation
Install Rust targets as needed:
```bash
rustup target add <target>
# Example: rustup target add aarch64-unknown-linux-gnu
```

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

# macOS
make build-darwin-amd64   # macOS Intel
make build-darwin-arm64   # macOS Apple Silicon

# Linux
make build-linux-amd64    # Linux x64
make build-linux-arm64    # Linux ARM64
```

### Build All Platforms for an OS
```bash
make build-all-windows    # Only AMD64
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
│   ├── librustlib.a             # Rust static library (for Go)
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

## Platform-Specific Notes

### Windows
- Uses MinGW-w64 toolchain (not MSVC) for CGO compatibility
- Rust library names: `librustlib.a` (static) and `rustlib.dll` (dynamic)
- Both Go and .NET executables are built as `.exe` files

### macOS
- Full static linking is not supported due to macOS restrictions
- Dynamic libraries use `.dylib` extension

### Linux
- Supports full static linking for Go binaries
- Dynamic libraries use `.so` extension
