// Minimal C FFI for Anki's Rust backend.
#ifndef ANKI_FFI_H
#define ANKI_FFI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AnkiBackend AnkiBackend;

typedef struct {
  uint8_t* ptr;
  size_t len;
} AnkiBytes;

typedef struct {
  uint8_t ok;
  AnkiBytes data;
  AnkiBytes err;
} AnkiResult;

void anki_bytes_free(AnkiBytes bytes);

// Initialize logging to the provided path (NULL for default).
int32_t anki_initialize_logging(const char* path);

// Open a backend with a serialized BackendInit protobuf.
// Returns NULL on error; if err_out != NULL it will be set to a UTF-8 message.
AnkiBackend* anki_backend_open(const uint8_t* init_ptr, size_t init_len, AnkiBytes* err_out);

// Free a backend handle.
void anki_backend_free(AnkiBackend* backend);

// Run a backend service method.
AnkiResult anki_backend_command(AnkiBackend* backend, uint32_t service, uint32_t method,
                                const uint8_t* input_ptr, size_t input_len);

// Run a DB command (JSON bytes in/out).
AnkiResult anki_backend_db_command(AnkiBackend* backend, const uint8_t* input_ptr,
                                   size_t input_len);

// Convenience wrapper to open a collection without protobuf on the C side.
AnkiResult anki_backend_open_collection(AnkiBackend* backend, const char* collection_path,
                                        const char* media_folder_path, const char* media_db_path);

// Convenience wrapper to close the collection.
AnkiResult anki_backend_close_collection(AnkiBackend* backend, uint8_t downgrade_to_schema11);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // ANKI_FFI_H
