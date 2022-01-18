use std::{
    ffi::{CStr, CString},
    os::raw::c_char,
};

use base64;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn base64_encode_wasm(data: Vec<u8>) -> String {
    base64::encode(data)
}

#[no_mangle]
pub extern "C" fn base64_encode_ffi(data: *const c_char) -> *const c_char {
    unsafe {
        let c_str = CStr::from_ptr(data).to_str().unwrap();
        let str = CString::new(base64::encode(c_str)).unwrap();
        println!("Encoded: {:?}", str);
        let ptr = str.as_ptr();
        std::mem::forget(str);
        ptr
    }
}
