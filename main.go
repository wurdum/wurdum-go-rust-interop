package main

/*
#cgo LDFLAGS: -L./rustlib/target/release -lrustlib
#include <stdlib.h>

// Declare the Rust functions
int add_numbers(int a, int b);
char* process_string(const char* input);
void free_rust_string(char* s);
unsigned long long fibonacci(unsigned int n);
*/
import "C"
import (
	"fmt"
	"unsafe"
)

func main() {
	fmt.Println("=== Wurdum Go-Rust Interop Demo ===")

	// Example 1: Call simple addition function
	result := C.add_numbers(5, 7)
	fmt.Printf("5 + 7 = %d\n", result)

	// Example 2: Process a string
	input := C.CString("hello from go")
	defer C.free(unsafe.Pointer(input))

	processed := C.process_string(input)
	processedStr := C.GoString(processed)
	C.free_rust_string(processed)

	fmt.Printf("Processed string: %s\n", processedStr)

	// Example 3: Calculate Fibonacci
	n := C.uint(10)
	fib := C.fibonacci(n)
	fmt.Printf("Fibonacci(%d) = %d\n", n, fib)
}
