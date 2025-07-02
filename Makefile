.PHONY: all build-rust build-go run clean

# Binary name based on project
BINARY_NAME=wurdum-interop

all: build-rust build-go

build-rust:
	cd rustlib && cargo build --release

build-go: build-rust
	go build -o $(BINARY_NAME) main.go

run: all
	./$(BINARY_NAME)

clean:
	cd rustlib && cargo clean
	rm -f $(BINARY_NAME)

# For development with hot reload
dev:
	cd rustlib && cargo build
	go run main.go
