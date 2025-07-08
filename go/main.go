package main

/*
#cgo windows,amd64 LDFLAGS: -L../dist/windows-amd64 -lrustlib -lws2_32 -luserenv -lntdll -static
#cgo windows,arm64 LDFLAGS: -L../dist/windows-arm64 -lrustlib -lws2_32 -luserenv -lntdll -static
#cgo darwin,amd64 LDFLAGS: -L../dist/darwin-amd64 -lrustlib
#cgo darwin,arm64 LDFLAGS: -L../dist/darwin-arm64 -lrustlib
#cgo linux,amd64 LDFLAGS: -L../dist/linux-amd64 -lrustlib -static
#cgo linux,arm64 LDFLAGS: -L../dist/linux-arm64 -lrustlib -static
#include <stdlib.h>

// Declare the Rust functions
int add_numbers(int a, int b);
char* process_string(const char* input);
void free_rust_string(char* s);
unsigned long long fibonacci(unsigned int n);

// Forward declarations for Go callbacks
void processCallback(int value);
void sumCallback(int value);

// C wrapper functions that can be used as function pointers
static void c_process_callback(int value) {
    processCallback(value);
}

static void c_sum_callback(int value) {
    sumCallback(value);
}

// Data structure with callback
typedef struct {
    int* data;
    int length;
    void (*callback)(int);
} DataWithCallback;

// Declare new Rust functions for callbacks
int process_data_with_callback(DataWithCallback data_struct);
int sum_with_callback(DataWithCallback data_struct);

// Helper functions to create DataWithCallback structs
static DataWithCallback create_data_with_process_callback(int* data, int length) {
    DataWithCallback result;
    result.data = data;
    result.length = length;
    result.callback = c_process_callback;
    return result;
}

static DataWithCallback create_data_with_sum_callback(int* data, int length) {
    DataWithCallback result;
    result.data = data;
    result.length = length;
    result.callback = c_sum_callback;
    return result;
}
*/
import "C"
import (
	"fmt"
	"unsafe"
)

//export processCallback
func processCallback(value C.int) {
	fmt.Printf("  → Rust processed value: %d\n", value)
}

//export sumCallback
func sumCallback(value C.int) {
	fmt.Printf("  → Running sum: %d\n", value)
}

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

	fmt.Println("\n=== NEW: Callback Examples ===")

	// Example 4: Data processing with callback
	fmt.Println("\nExample 4: Processing data with callback")
	data := []C.int{1, 2, 3, 4, 5}

	// Create the data structure using helper function
	dataStruct := C.create_data_with_process_callback(
		(*C.int)(unsafe.Pointer(&data[0])),
		C.int(len(data)),
	)

	fmt.Printf("Original data: %v\n", data)
	fmt.Println("Rust will double each value and call back:")
	processedCount := C.process_data_with_callback(dataStruct)
	fmt.Printf("Processed %d elements\n", processedCount)

	// Example 5: Sum calculation with callback
	fmt.Println("\nExample 5: Sum calculation with running totals callback")
	data2 := []C.int{10, 20, 30, 40}

	dataStruct2 := C.create_data_with_sum_callback(
		(*C.int)(unsafe.Pointer(&data2[0])),
		C.int(len(data2)),
	)

	fmt.Printf("Data: %v\n", data2)
	fmt.Println("Rust will calculate running sums and call back:")
	totalSum := C.sum_with_callback(dataStruct2)
	fmt.Printf("Final sum: %d\n", totalSum)
}
