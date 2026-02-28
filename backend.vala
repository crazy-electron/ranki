using GLib;

public errordomain BackendError {
    FAILED
}

public class Backend : GLib.Object {

    // Free a buffer returned by the FFI.
    //  [CCode (cname = "anki_bytes_free", has_type_id = false)]
    //  private extern static void anki_bytes_free (AnkiBytes bytes);
 
    // Open a backend with a serialized BackendInit protobuf.
    // Returns NULL on error; if err_out != NULL it will be set to a UTF-8 message.
    //  [CCode (cname = "anki_backend_open", has_type_id = false)]
    //  private extern static uint8* anki_backend_open (uint8* init_ptr, size_t init_len, ref AnkiBytes err_out);

    // Free a backend handle.
    //  [CCode (cname = "anki_backend_free", has_type_id = false)]
    //  private extern static void anki_backend_free (uint8* backend);
 
    // Run a backend service method.
    //  [CCode (cname = "anki_backend_command", has_type_id = false)]
    //  private extern static AnkiResult anki_backend_command (uint8* backend, uint32 service, uint32 method, uint8* input_ptr, size_t input_len);

    // Convenience wrapper to open a collection without protobuf on the C side.
    //  [CCode (cname = "anki_backend_open_collection", has_type_id = false)]
    //  private extern static AnkiResult anki_backend_open_collection (uint8* backend, string collection_path, string media_folder_path, string media_db_path);

    // Convenience wrapper to close the collection.
    //  [CCode (cname = "anki_backend_close_collection", has_type_id = false)]
    //  private extern static AnkiResult anki_backend_close_collection (uint8* backend, uint8 downgrade_to_schema11);

    private uint8* backend;

    private Bridge bridge;

    public Backend(string so_path) throws BackendError {

        bridge = new Bridge( so_path );

        var init = new Anki.Backend.BackendInit() {
            locale_folder_path = "",
            server = false
        };
        init.preferred_langs.append ("en");
        
        var enc = new Protobuf.EncodeBuffer ();
        init.encode (enc);

        var err = Bridge.AnkiBytes () { ptr = null, len = 0 };
 
        backend = bridge.anki_backend_open (enc.data, enc.data.length, ref err);

        throw_if_error( Bridge.AnkiResult() {
            ok  = backend == null ? 0 : 1,
            err = err
        });

    }

    ~Backend() {
        lock (bridge) {
            debug("closing Backend");
            bridge.anki_backend_close_collection(backend);
            bridge.anki_backend_free(backend);
        }
    }

    public void open_collection(string col_path, string media_dir, string media_db) throws BackendError {
        lock (bridge) {
            var res = bridge.anki_backend_open_collection(backend, col_path, media_dir, media_db);    
            throw_if_error( res );
        }
    }

    public void run_command(uint32 service, uint32 method, Protobuf.Message request, Protobuf.Message? output = null) throws BackendError {
        lock (bridge) {

            var dreq_enc = new Protobuf.EncodeBuffer ();

            request.encode (dreq_enc);

            var res = bridge.anki_backend_command (
                backend,
                service,
                method,
                dreq_enc.data,
                dreq_enc.data.length
            );

            throw_if_error(res);

            if (output == null) return;        

            if (res.data.len == 0) {
                warning("res.data.len 0");
                return; // throw?
            }

            var buffer = new uint8[res.data.len];
            Memory.copy(buffer, res.data.ptr, res.data.len);
            bridge.anki_bytes_free(res.data);
            
            output.decode( new Protobuf.DecodeBuffer (buffer) );
        }
    }

    private void throw_if_error( Bridge.AnkiResult res ) throws BackendError {
        
        if (res.ok == 1)
            return;
  
        if (res.err.ptr == null || res.err.len == 0) // free if ptr != null ?
            throw new BackendError.FAILED ("Backend error: (no details)");

        var buffer = new uint8[res.err.len];
        Memory.copy(buffer, res.err.ptr, res.err.len);
        bridge.anki_bytes_free(res.err);

        var backend_error = new Anki.Backend.BackendError.from_data(
            new Protobuf.DecodeBuffer ( buffer ) 
        );

        throw new BackendError.FAILED ("Backend error: %s",
            backend_error.message ?? "(no message)"
        );

    }

    public void sync_collection(Anki.Sync.SyncAuth a_sync_syncauth) throws Error {

        //  Thread.usleep (2 * 1000 * 1000);

        //  return;
        //  var a_sync_synclogin_req = new Anki.Sync.SyncLoginRequest() {
        //      username = "<username>",
        //      password = "<password>",
        //      endpoint = "https://ankiweb.net/"
        //  };
        //  var a_sync_syncauth = new Anki.Sync.SyncAuth();

        //  bridge.run_command( 1, 3, a_sync_synclogin_req, a_sync_syncauth);

        //  var a_sync_syncauth = new Anki.Sync.SyncAuth() {
        //      hkey = hkey,
        //      endpoint = "https://ankiweb.net/"
        //  };

        debug("sync_collection %s", a_sync_syncauth.to_string() );

        var a_sync_synccollection_req = new Anki.Sync.SyncCollectionRequest() {
            auth = a_sync_syncauth,
            sync_media = true
        };
        var a_sync_synccollection_res = new Anki.Sync.SyncCollectionResponse();

        run_command( 1, 5, a_sync_synccollection_req, a_sync_synccollection_res);

        debug("a_sync_synccollection_res %s", a_sync_synccollection_res.to_string() );

        if ( a_sync_synccollection_res.required == Anki.Sync.SyncCollectionResponse.ChangesRequired.FULL_SYNC ||
                a_sync_synccollection_res.required == Anki.Sync.SyncCollectionResponse.ChangesRequired.FULL_DOWNLOAD
        ) {

            debug("full sync");

            if ( a_sync_synccollection_res.new_endpoint != null ){
                a_sync_syncauth.endpoint = a_sync_synccollection_res.new_endpoint;
            }

            debug("sync_collection for full %s", a_sync_syncauth.to_string() );   

            var a_sync_fulluploadordownload_req = new Anki.Sync.FullUploadOrDownloadRequest() {
                auth = a_sync_syncauth,
                upload = false,
                server_usn = a_sync_synccollection_res.server_media_usn
            };

            run_command( 1, 6, a_sync_fulluploadordownload_req);
            
        }
    }    

    // could be generated inside anki build a .vala as pylib/_backend_generated.py is for python
    // instead of hard coding services and method indexes on run_command
    
}