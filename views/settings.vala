using Gtk;
using GLib;
using CrazySpices;

public class SettingsView : AppView {

    public override string get_template(){

        return """
            <interface>
                <object class="GtkVBox" id="main_vbox">

                <child>
                    <object class="InkScrolledWindow" id="scrolled_window">
                        <property name="name">settings-scrolled-window</property>

                        <child>
                        <object class="GtkVBox" id="main_vbox_2">
                        <property name="spacing">10</property>

                        <child>
                        <object class="GtkHBox" id="hbox1">       
                            <property name="spacing">10</property>                  
                            <child>
                            <object class="InkButton" id="back_button">
                                <property name="label">Back</property>                            
                            </object>
                            <packing>
                                <property name="expand">False</property>
                            </packing>
                            </child>

                            <child>
                            <object class="GtkLabel" id="_label_expander_1">                            
                                <property name="label"></property>
                            </object>
                            <packing>
                                <property name="expand">True</property>
                            </packing>
                            </child>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>
                        </child>

                        <child>
                        <object class="GtkLabel" id="username_entry_lbl">
                            <property name="can_focus">False</property>
                            <property name="xalign">0</property>
                            <property name="label">Email</property>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>
                        </child>

                        <child>
                        <object class="InkEntry" id="username_entry">                        
                            <property name="can_focus">True</property>
                            <property name="text"></property>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>
                        </child>      
                        
                        <child>
                        <object class="GtkLabel" id="password_entry_lbl">
                            <property name="can_focus">False</property>
                            <property name="xalign">0</property>
                            <property name="label">Password</property>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>
                        </child>

                        <child>
                        <object class="InkEntry" id="password_entry">                        
                            <property name="can_focus">True</property>
                            <property name="visibility">False</property>
                            <property name="text"></property>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>
                        </child>

                        <child>
                        <object class="InkRowToggleButton" id="sync_server_toggle">
                            <property name="label">Custom sync server</property>
                            <property name="description">use custom sync server</property>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>                        
                        </child>

                        <child>
                        <object class="InkEntry" id="sync_server_entry">
                            <property name="no-show-all">True</property>                                             
                            <property name="can_focus">True</property>
                            <property name="text"></property>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>
                        </child>                        

                        <child>
                        <object class="GtkHBox" id="hbox2">   
                        
                            <child>
                            <object class="GtkLabel" id="_label_expander_2">                            
                                <property name="label"></property>
                            </object>
                            <packing>
                                <property name="expand">True</property>
                            </packing>
                            </child>

                            <child>
                            <object class="InkButton" id="login_button">
                                <property name="label">Login</property>                            
                            </object>
                            <packing>
                                <property name="expand">False</property>
                            </packing>
                            </child>

                        </object>
                        <packing>
                            <property name="expand">False</property>
                            <property name="fill">False</property>
                        </packing>
                        </child>

                        <child>
                            <object class="InkRowHScale" id="content_scale">
                                <property name="label">Scale</property>
                                <property name="description">Scale card content.</property>
                                <property name="digits">1</property>
                            </object>
                            <packing>
                                <property name="expand">False</property>
                                <property name="fill">False</property>
                            </packing>                            
                        </child> 

                        <child>
                            <object class="InkButton" id="download_mathjax">
                                <property name="label">Download MathJax (35M)</property>                            
                            </object>
                            <packing>
                                <property name="expand">False</property>
                                <property name="fill">False</property>
                            </packing>
                        </child>                    

                        </object>             
                        </child>

                    </object>             
                </child>

                </object>                
            </interface>              
        """;

    }

    private Entry username_entry;
    private Entry password_entry;
    private Button login_button;
    private Button back_button;
    private InkRowHScale content_scale;
    private Button download_mathjax_button;

    private Entry sync_server_entry;
    private InkRowToggleButton sync_server_toggle;

    public bool has_mathjax { get; set; default = false; }
    public bool has_custom_sync_server { get; set; default = false; }
    public bool loading { get; set; default = false; }

    public string collection_assets_dir { get {
        return get_data<string> ("collection_assets_dir");        
    } }    

    public SettingsView ( string data = "") {

        debug("new SettingsView");

        back_button = builder.get_object ("back_button") as Button;
        
        back_button.clicked.connect (() => navigate( new DeckTreeView() ));
        
        username_entry = builder.get_object ("username_entry") as Entry;
    
        password_entry = builder.get_object ("password_entry") as Entry;
        password_entry.visibility = password_entry.is_focus;
        password_entry.notify["is-focus"].connect (() => {
            password_entry.visibility = password_entry.is_focus;
        });

        sync_server_entry  = builder.get_object ("sync_server_entry") as Entry;
        sync_server_toggle = builder.get_object ("sync_server_toggle") as InkRowToggleButton;

        login_button   = builder.get_object ("login_button") as Button;
        
        content_scale  = builder.get_object ("content_scale") as InkRowHScale;
        content_scale.upper = 5;
        content_scale.lower = 1;

        download_mathjax_button = builder.get_object ("download_mathjax") as Button;
        
        var entries = new Widget[] { username_entry, password_entry, sync_server_entry };

        foreach (var entry in entries) { 
            entry.notify["is-focus"].connect(() => {
                do_action(entry.is_focus ? AnkiReviewer.AppViewActions.SHOW_KEYBOARD : AnkiReviewer.AppViewActions.HIDE_KEYBOARD);
            });
        }

        login_button.clicked.connect (() => login());

        download_mathjax_button.clicked.connect (() => {
            if (has_mathjax)
                remove_mathjax();
            else
                download_mathjax();
        });  

        bind_property ("has-mathjax", download_mathjax_button, "label", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE, (binding, srcval, ref targetval) => {
            targetval.set_string( srcval.get_boolean () ? "MathJax installed. (tap to remove)" : "Download MathJax (35M)" );
            return true;
        });

        bind_property ("has-custom-sync-server", sync_server_toggle , "active", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE);
        bind_property ("has-custom-sync-server", sync_server_entry, "visible", GLib.BindingFlags.DEFAULT | GLib.BindingFlags.SYNC_CREATE);
        bind_property ("has-custom-sync-server", sync_server_entry, "text", GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE,
            (binding, srcval, ref targetval) => {
                targetval.set_string( srcval.get_boolean() ? targetval.get_string() ?? "" : "" );
                return true;
            },
            (binding, srcval, ref targetval) => {
                targetval.set_boolean( srcval.get_string().length > 0 );
                return true;
            }
        );

        bind_property ("loading", back_button, "sensitive", GLib.BindingFlags.DEFAULT | BindingFlags.INVERT_BOOLEAN | GLib.BindingFlags.SYNC_CREATE);
        bind_property ("loading", login_button, "sensitive", GLib.BindingFlags.DEFAULT | BindingFlags.INVERT_BOOLEAN | GLib.BindingFlags.SYNC_CREATE);
        bind_property ("loading", username_entry, "sensitive", GLib.BindingFlags.DEFAULT | BindingFlags.INVERT_BOOLEAN | GLib.BindingFlags.SYNC_CREATE);
        bind_property ("loading", password_entry, "sensitive", GLib.BindingFlags.DEFAULT | BindingFlags.INVERT_BOOLEAN | GLib.BindingFlags.SYNC_CREATE);
        bind_property ("loading", download_mathjax_button, "sensitive", GLib.BindingFlags.DEFAULT | BindingFlags.INVERT_BOOLEAN | GLib.BindingFlags.SYNC_CREATE);
    
    }

    public override void ready(){

        {
            var dir  = File.new_for_path( Path.build_path (Path.DIR_SEPARATOR_S, collection_assets_dir, "MathJax-2.7.9") );
            has_mathjax = dir.query_exists();
        }
        
        bind_settings<string> (keyfile, "General", "sync_server", sync_server_entry, "text", () => { 
            do_action(AnkiReviewer.AppViewActions.SAVE_SETTINGS);
        });        

        bind_settings<double> (keyfile, "General", "scale", content_scale, "value", () => { 
            do_action(AnkiReviewer.AppViewActions.SAVE_SETTINGS);
        });
    }

    private async void download_mathjax() {

        loading = true;

        var cancellable = new Cancellable();

        cancellables.append_val(cancellable);

        FileStream? file = null;
        int? fd = null;
        string? path = null;

        try {

            path = Path.build_path (Path.DIR_SEPARATOR_S, collection_assets_dir, ".ranki-mathjax-XXXXXX.zip");

            fd   = FileUtils.mkstemp (path);

            if (fd == -1) {
                throw new AnkiReviewerError.ERROR(@"Error creating temporary file: GFileError $(FileUtils.error_from_errno (GLib.errno)).");
            }

            file = FileStream.fdopen (fd, "wb");

            debug("Temporary file created: %s", path);
        
            yield CrazySpices.run_thread<void>(() => {

                int64 last = 0, elapsed = 0;
   
                debug("downloading...");
                
                CrazySpices.ZipDownloader.download( 
                    "https://github.com/mathjax/MathJax/archive/2.7.9.zip",
                    file,
                    (now, total) => {

                        // debug(@"download $now / $total");

                        elapsed = get_monotonic_time() - last;

                        if ( ((double) elapsed / 1000.0) < 100.0 ) {
                            return;
                        }

                        Idle.add (() => {
                            download_mathjax_button.label = "Downloading... %s".printf( format_size_for_display( (int64) now ) );
                            return false;
                        });

                        last = get_monotonic_time();

                    },
                    cancellable         
                );

                debug("extracting...");

                CrazySpices.extract_zip(
                    file,
                    collection_assets_dir,
                    (now, total) => {

                        elapsed = get_monotonic_time() - last;

                        if ( ((double) elapsed / 1000.0) < 100.0 ) {
                            return;
                        }

                        Idle.add (() => {
                            download_mathjax_button.label = "Extracting... %.0f%%".printf( (now / total) * 100.0 );
                            return false;
                        });

                        last = get_monotonic_time();

                    },
                    cancellable
                );  
            
            });

            has_mathjax = true;

        } catch (Error e) { // IOError.CANCELLED e
            has_mathjax = false;
            debug("Operation cancelled!");
        }

        if (fd != -1)
            FileUtils.close(fd);

        if (path != null)
            FileUtils.remove(path); 

        loading = false;
    }

    private async void remove_mathjax() {

        loading = true;

        var path = Path.build_path (Path.DIR_SEPARATOR_S, collection_assets_dir, "MathJax-2.7.9");
        var dir  = File.new_for_path(path);

        try {
            yield CrazySpices.run_thread<void>(() => { CrazySpices.delete_tree(dir); });
            has_mathjax = false;
        } catch (Error e) {
            debug("Operation cancelled!");
        }

        loading = false;

    }

    private async void login() {

        loading = true;

        var endpoint = "";

        try {
            endpoint = keyfile.get_string("General", "sync_server") ?? "";
        } catch (Error e) {
            //
        }        

        if (endpoint.length == 0)
            endpoint = "https://ankiweb.net/";
        
        try {

            var a_sync_synclogin_req = new Anki.Sync.SyncLoginRequest() {
                username = username_entry.text,
                password = password_entry.text,
                endpoint = endpoint
            };
            var a_sync_syncauth = new Anki.Sync.SyncAuth();

            yield run_thread<void>(
                () => backend.run_command( 1, 3, a_sync_synclogin_req, a_sync_syncauth)
            );
            
            debug("a_sync_syncauth %s", a_sync_syncauth.to_string());

            keyfile.set_string("General", "hkey", a_sync_syncauth.hkey);

            do_action(AnkiReviewer.AppViewActions.SAVE_SETTINGS);

            navigate( new DeckTreeView( ) );

        } catch (Error e) {

            warning ("[error]: %s", e.message);

            Gtk.Window? parent = get_toplevel () as Gtk.Window;

            var dialog = new Gtk.MessageDialog (
                parent,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.CLOSE,
                "[error]: %s",
                e.message
            );

            dialog.set_transient_for (parent);
            dialog.set_position (Gtk.WindowPosition.CENTER_ON_PARENT);

            dialog.title = "L:A_N:application_ID:error_PC:N";
            dialog.run();
            dialog.destroy();

        }

        loading = false;

    }

    ~SettingsView() {
        debug("destroying SettingsView");
    }    

}