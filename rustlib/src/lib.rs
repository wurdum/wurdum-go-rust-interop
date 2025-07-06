use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};

/// Struct that represents data with a callback function pointer
#[repr(C)]
pub struct DataWithCallback {
    pub data: *const c_int,
    pub length: c_int,  // Changed from usize to c_int to match Go's int type
    pub callback: extern "C" fn(c_int),
}

/// Simple function that adds two numbers
#[no_mangle]
pub extern "C" fn add_numbers(a: c_int, b: c_int) -> c_int {
    a + b
}

/// Function that processes a string and returns a new one
#[no_mangle]
pub extern "C" fn process_string(input: *const c_char) -> *mut c_char {
    unsafe {
        // Convert C string to Rust string
        let c_str = CStr::from_ptr(input);
        let rust_str = c_str.to_str().unwrap_or("invalid");

        // Process the string (simple example: make it uppercase)
        let processed = format!("Processed: {}", rust_str.to_uppercase());

        // Convert back to C string
        let c_string = CString::new(processed).unwrap();
        c_string.into_raw()
    }
}

/// Free memory allocated by Rust (important for strings)
#[no_mangle]
pub extern "C" fn free_rust_string(s: *mut c_char) {
    unsafe {
        if s.is_null() {
            return;
        }
        _ = CString::from_raw(s);
    }
}

/// More complex example: calculate fibonacci
#[no_mangle]
pub extern "C" fn fibonacci(n: u32) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        _ => {
            let mut a = 0u64;
            let mut b = 1u64;
            for _ in 2..=n {
                let temp = a + b;
                a = b;
                b = temp;
            }
            b
        }
    }
}

/// Process data with callback function
/// This function doubles each number in the array and calls the callback for each result
#[no_mangle]
pub extern "C" fn process_data_with_callback(data_struct: DataWithCallback) -> c_int {
    println!("process_data_with_callback called");

    unsafe {
        if data_struct.data.is_null() || data_struct.length <= 0 {
            return -1;
        }

        // Create a slice from the raw pointer
        let data_slice = std::slice::from_raw_parts(data_struct.data, data_struct.length as usize);

        let mut processed_count = 0;

        // Process each element
        for &value in data_slice {
            // Double the value as an example of processing
            let processed_value = value * 2;

            // Call the Go callback function with the processed value
            (data_struct.callback)(processed_value);

            processed_count += 1;
        }

        processed_count
    }
}

/// Process data with callback and return sum
/// This function calculates sum of all elements and calls callback with running totals
#[no_mangle]
pub extern "C" fn sum_with_callback(data_struct: DataWithCallback) -> c_int {
    println!("sum_with_callback called");

    unsafe {
        // Validate input
        if data_struct.data.is_null() || data_struct.length <= 0 {
            return 0;
        }

        // Create a slice from the raw pointer
        let data_slice = std::slice::from_raw_parts(data_struct.data, data_struct.length as usize);

        let mut running_sum = 0;

        // Process each element and maintain running sum
        for &value in data_slice {
            running_sum += value;

            // Call the Go callback with current running sum
            (data_struct.callback)(running_sum);
        }

        running_sum
    }
}
