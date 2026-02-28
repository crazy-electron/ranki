// C FFI exports for the Anki library.
use std::ffi::CStr;
use std::os::raw::c_char;
use std::ptr;
use std::slice;

use anki_proto::collection::{CloseCollectionRequest, OpenCollectionRequest};
use prost::Message;

use crate::backend::{init_backend, Backend};
use crate::error::AnkiError;
use crate::log::set_global_logger;
use crate::services::BackendCollectionService;

/// Opaque handle to a Backend instance.
#[repr(C)]
pub struct AnkiBackend {
    backend: Backend,
}

/// A raw byte buffer owned by the caller after returning across the FFI.
#[repr(C)]
#[derive(Copy, Clone, Default)]
pub struct AnkiBytes {
    pub ptr: *mut u8,
    pub len: usize,
}

/// A result that contains either data or an error buffer.
#[repr(C)]
pub struct AnkiResult {
    pub ok: u8,
    pub data: AnkiBytes,
    pub err: AnkiBytes,
}

fn bytes_from_vec(mut bytes: Vec<u8>) -> AnkiBytes {
    if bytes.is_empty() {
        return AnkiBytes::default();
    }
    let out = AnkiBytes {
        ptr: bytes.as_mut_ptr(),
        len: bytes.len(),
    };
    std::mem::forget(bytes);
    out
}

fn err_from_backend(backend: &Backend, err: AnkiError) -> AnkiBytes {
    let backend_err = err.into_protobuf(&backend.tr);
    let mut bytes = Vec::new();
    if backend_err.encode(&mut bytes).is_ok() {
        bytes_from_vec(bytes)
    } else {
        AnkiBytes::default()
    }
}

fn result_ok(bytes: Vec<u8>) -> AnkiResult {
    AnkiResult {
        ok: 1,
        data: bytes_from_vec(bytes),
        err: AnkiBytes::default(),
    }
}

fn result_err(bytes: Vec<u8>) -> AnkiResult {
    AnkiResult {
        ok: 0,
        data: AnkiBytes::default(),
        err: bytes_from_vec(bytes),
    }
}

fn result_err_backend(backend: &Backend, err: AnkiError) -> AnkiResult {
    AnkiResult {
        ok: 0,
        data: AnkiBytes::default(),
        err: err_from_backend(backend, err),
    }
}

fn slice_from_ptr<'a>(ptr: *const u8, len: usize) -> Option<&'a [u8]> {
    if len == 0 {
        return Some(&[]);
    }
    if ptr.is_null() {
        return None;
    }
    Some(unsafe { slice::from_raw_parts(ptr, len) })
}

fn str_from_ptr<'a>(ptr: *const c_char) -> Option<&'a str> {
    if ptr.is_null() {
        return None;
    }
    let cstr = unsafe { CStr::from_ptr(ptr) };
    cstr.to_str().ok()
}

/// Free a buffer allocated by Anki.
#[no_mangle]
pub extern "C" fn anki_bytes_free(bytes: AnkiBytes) {
    if bytes.ptr.is_null() {
        return;
    }
    unsafe {
        let _ = Vec::from_raw_parts(bytes.ptr, bytes.len, bytes.len);
    }
}

/// Initialize logging. Returns 0 on success.
#[no_mangle]
pub extern "C" fn anki_initialize_logging(path: *const c_char) -> i32 {
    let path_str = if path.is_null() {
        None
    } else {
        match unsafe { CStr::from_ptr(path) }.to_str() {
            Ok(s) => Some(s),
            Err(_) => return 1,
        }
    };
    set_global_logger(path_str).map(|_| 0).unwrap_or(1)
}

/// Initialize the backend with a serialized BackendInit protobuf.
/// Returns NULL on error; if err_out is non-NULL, it will be filled with UTF-8
/// bytes describing the error.
#[no_mangle]
pub extern "C" fn anki_backend_open(
    init_ptr: *const u8,
    init_len: usize,
    err_out: *mut AnkiBytes,
) -> *mut AnkiBackend {
    let init_bytes = match slice_from_ptr(init_ptr, init_len) {
        Some(bytes) => bytes,
        None => {
            if !err_out.is_null() {
                let msg = b"init_ptr was NULL";
                unsafe {
                    *err_out = bytes_from_vec(msg.to_vec());
                }
            }
            return ptr::null_mut();
        }
    };

    match init_backend(init_bytes) {
        Ok(backend) => Box::into_raw(Box::new(AnkiBackend { backend })),
        Err(err) => {
            if !err_out.is_null() {
                unsafe {
                    *err_out = bytes_from_vec(err.into_bytes());
                }
            }
            ptr::null_mut()
        }
    }
}

/// Free the backend instance.
#[no_mangle]
pub extern "C" fn anki_backend_free(backend: *mut AnkiBackend) {
    if backend.is_null() {
        return;
    }
    unsafe {
        let _ = Box::from_raw(backend);
    }
}

/// Run a backend service method using service/method indexes and serialized input.
/// On success, ok=1 and data is set. On error, ok=0 and err contains a
/// BackendError protobuf.
#[no_mangle]
pub extern "C" fn anki_backend_command(
    backend: *mut AnkiBackend,
    service: u32,
    method: u32,
    input_ptr: *const u8,
    input_len: usize,
) -> AnkiResult {
    if backend.is_null() {
        return AnkiResult {
            ok: 0,
            data: AnkiBytes::default(),
            err: bytes_from_vec(b"backend was NULL".to_vec()),
        };
    }
    let backend = unsafe { &mut *backend };

    let input = match slice_from_ptr(input_ptr, input_len) {
        Some(bytes) => bytes,
        None => return result_err_backend(&backend.backend, AnkiError::InvalidInput {
            source: snafu::FromString::without_source("input_ptr was NULL".into()),
        }),
    };

    match backend.backend.run_service_method(service, method, input) {
        Ok(out) => result_ok(out),
        Err(err) => result_err(err),
    }
}

/// Run a DB command. Input/outputs are JSON bytes.
#[no_mangle]
pub extern "C" fn anki_backend_db_command(
    backend: *mut AnkiBackend,
    input_ptr: *const u8,
    input_len: usize,
) -> AnkiResult {
    if backend.is_null() {
        return AnkiResult {
            ok: 0,
            data: AnkiBytes::default(),
            err: bytes_from_vec(b"backend was NULL".to_vec()),
        };
    }
    let backend = unsafe { &mut *backend };

    let input = match slice_from_ptr(input_ptr, input_len) {
        Some(bytes) => bytes,
        None => {
            return result_err_backend(
                &backend.backend,
                AnkiError::InvalidInput {
                    source: snafu::FromString::without_source(
                        "input_ptr was NULL".into(),
                    ),
                },
            )
        }
    };

    match backend.backend.run_db_command_bytes(input) {
        Ok(out) => result_ok(out),
        Err(err) => result_err(err),
    }
}

/// Convenience wrapper to open a collection without protobuf on the C side.
#[no_mangle]
pub extern "C" fn anki_backend_open_collection(
    backend: *mut AnkiBackend,
    collection_path: *const c_char,
    media_folder_path: *const c_char,
    media_db_path: *const c_char,
) -> AnkiResult {
    if backend.is_null() {
        return AnkiResult {
            ok: 0,
            data: AnkiBytes::default(),
            err: bytes_from_vec(b"backend was NULL".to_vec()),
        };
    }
    let backend = unsafe { &mut *backend };

    let collection_path = match str_from_ptr(collection_path) {
        Some(s) => s,
        None => {
            return result_err_backend(
                &backend.backend,
                AnkiError::InvalidInput {
                    source: snafu::FromString::without_source(
                        "collection_path was NULL or invalid UTF-8".into(),
                    ),
                },
            )
        }
    };
    let media_folder_path = match str_from_ptr(media_folder_path) {
        Some(s) => s,
        None => {
            return result_err_backend(
                &backend.backend,
                AnkiError::InvalidInput {
                    source: snafu::FromString::without_source(
                        "media_folder_path was NULL or invalid UTF-8".into(),
                    ),
                },
            )
        }
    };
    let media_db_path = match str_from_ptr(media_db_path) {
        Some(s) => s,
        None => {
            return result_err_backend(
                &backend.backend,
                AnkiError::InvalidInput {
                    source: snafu::FromString::without_source(
                        "media_db_path was NULL or invalid UTF-8".into(),
                    ),
                },
            )
        }
    };

    let req = OpenCollectionRequest {
        collection_path: collection_path.to_string(),
        media_folder_path: media_folder_path.to_string(),
        media_db_path: media_db_path.to_string(),
    };

    match BackendCollectionService::open_collection(&backend.backend, req) {
        Ok(()) => result_ok(Vec::new()),
        Err(err) => result_err_backend(&backend.backend, err),
    }
}

/// Convenience wrapper to close the current collection.
#[no_mangle]
pub extern "C" fn anki_backend_close_collection(
    backend: *mut AnkiBackend,
    downgrade_to_schema11: u8,
) -> AnkiResult {
    if backend.is_null() {
        return AnkiResult {
            ok: 0,
            data: AnkiBytes::default(),
            err: bytes_from_vec(b"backend was NULL".to_vec()),
        };
    }
    let backend = unsafe { &mut *backend };

    let req = CloseCollectionRequest {
        downgrade_to_schema11: downgrade_to_schema11 != 0,
    };

    match BackendCollectionService::close_collection(&backend.backend, req) {
        Ok(()) => result_ok(Vec::new()),
        Err(err) => result_err_backend(&backend.backend, err),
    }
}
