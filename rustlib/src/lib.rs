use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Simple function that adds two numbers
#[no_mangle]
pub extern "C" fn add_numbers(a: i32, b: i32) -> i32 {
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
        CString::from_raw(s);
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
