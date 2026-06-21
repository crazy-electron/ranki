using GLib;
using Archive;
using Soup;

namespace CrazySpices {

    public class Store : Object {
        public signal void item_changed (string key);

        public unowned T get_item<T> (string key) {
            return get_data<T> (key); 
        }

        public void set_item<T> (string key, owned T data){
            set_data<T> (key, (owned) data);
            item_changed (key);
        }

        public delegate void SignalConnectCb<T> (T data);

        public ulong signal_connect<T> (string key, SignalConnectCb<T> cb_data, Object owner) {

            ulong handler_id = item_changed.connect ((changed_key) => {
                if (changed_key == key) {
                    cb_data (get_item<T> (key));
                }
            });

            owner.weak_ref (() => {
                if (SignalHandler.is_connected (this, handler_id)) {
                    disconnect (handler_id);
                }
            });

            return handler_id;
        }
    }

    [ CCode (cname = "realpath") ]
    public static extern string? realpath(string path, char *resolved_path = null);

    public delegate T WorkFunc<T> () throws Error;

    public static async T? run_thread<T> ( WorkFunc<T> callback = null ) throws Error {

        T? thread_output = null; Error? thread_error = null;

        ThreadFunc<void*> thread_fn = () => {
            try {
                thread_output = callback();
            } catch (Error e) {
                thread_error = e;
            }
            Idle.add (run_thread.callback);
            return null;
        };

        Thread<void*>.create (thread_fn, false);

        yield;

        return thread_error ?? thread_output;
    }

}