
using Gtk;
using GLib;
using CrazySpices;

errordomain AnkiReviewerError {
    ERROR
}

public class AnkiReviewer : Window {

    private static weak AnkiReviewer? self = null;

    private AppView? main_view = null;

    // accessible on views
    private Backend backend;
    private KeyFile keyfile;

    public enum AppViewActions {
        SAVE_SETTINGS,
        TOGGLE_FULLSCREEN,
        TOGGLE_STYLE,
        SHOW_KEYBOARD,
        HIDE_KEYBOARD
    }

    private string collection_media_dir = "";

    private Lipstick lipstick;

    private Debouncer save_settings_debouncer;
    private Debouncer show_keyboard_debouncer;

    public string app_id = "ranki.ranki.ranki";

    public bool fullscreen { get; set; default = true; }

    public AnkiReviewer () throws AnkiReviewerError, KeyFileError, FileError {

        Intl.setlocale (LocaleCategory.ALL, "");

        update_window_title();

        name = "app-light";
        
        border_width = 0;

        notify["fullscreen"].connect((s, p) => update_window_title());

        try {
            lipstick = new Lipstick();
        } catch (Error e) {
            warning("lipstick error\n");
        }

        keyfile = new KeyFile ();
        keyfile.load_from_file ( config_file , KeyFileFlags.KEEP_COMMENTS); // relative to shell?? ( internal realpath )

        // libanki.so
        var libanki_path = keyfile.get_string ("General", "libanki_path");
        libanki_path = libanki_path.replace("<arch>", FileUtils.test("/lib/ld-linux-armhf.so.3", FileTest.EXISTS) ? "armhf" : "armel" );
        
        if ( !Path.is_absolute(libanki_path) ) {
            libanki_path = Path.build_filename( Path.get_dirname(config_file), libanki_path);
        }

        // collection.anki2 collection.media collection.media.db2
        var collection_dir = keyfile.get_string ("General", "collection_dir");
        if ( !Path.is_absolute(collection_dir) ) {
            collection_dir = Path.build_filename( Path.get_dirname(config_file), collection_dir);
        }

        debug(@"real path %s", realpath( Path.get_dirname(collection_dir) ) );

        // force path to be inside /mnt/us
        if ( !((realpath( Path.get_dirname(collection_dir) ) ?? "") + "/").has_prefix("/mnt/us/") ) {
            throw new AnkiReviewerError.ERROR(@"anki data on unsafe path: $(collection_dir)"); 
        }

        if ( !FileUtils.test( @"$(collection_dir)/collection.media", FileTest.IS_DIR ) ) {
            var _cmdir = File.new_for_path ( @"$(collection_dir)/collection.media" );
            _cmdir.make_directory_with_parents ();
        }

        collection_media_dir = realpath( @"$(collection_dir)/collection.media" );
        
        debug(@"libanki_path $libanki_path collection_dir $collection_dir");

        backend = new Backend( libanki_path );
        backend.open_collection( @"$(collection_dir)/collection.anki2", @"$(collection_dir)/collection.media", @"$(collection_dir)/collection.media.db2" );

        // backend.load_hkey();

        save_settings_debouncer = new Debouncer<void*> (500, () => {
            debug ("save_settings");
            save_settings ();
        });
        
        show_keyboard_debouncer = new Debouncer<bool> (200, (is_active) => {
            debug ("show_keyboard_debouncer (active=%s)", is_active.to_string ());
            show_keyboard(is_active);
        });
        
        load_style_rc_file();

        set_main_view( new DeckTreeView() );        

    }

    public void set_main_view (AppView view) {

        if (main_view != null)
            main_view.destroy();

        debug("after main_view.destroy() "); 

        // wire
        view.navigate.connect((v) => set_main_view(v));

        view.exit_app.connect(() => destroy());

        view.do_action.connect((action) => do_action(action));

        view.set_data<unowned Backend> ("backend", backend);
        view.set_data<unowned KeyFile> ("keyfile", keyfile);
        // improve this
        view.set_data<string> ("collection_media_dir", collection_media_dir);
        
        view.ready();

        main_view = view;

        add (main_view);

        show_all();

    }

    private void update_window_title() {
        var param = new string[] { @"L:A_N:application_ID:$(app_id)_O:U" };
        if ( fullscreen ) {
            param += "PC:N";
        }
        title = string.joinv("_", param);
    }

    private void do_action (AppViewActions action) {

        if ( action == AppViewActions.SAVE_SETTINGS ) {
            save_settings_debouncer.trigger(null);
            return;
        }

        if ( action == AppViewActions.TOGGLE_STYLE ) {
            name = name == "app-light" ? "app-dark" : "app-light";
            reset_rc_styles ();
            return;
        }

        if ( action == AppViewActions.TOGGLE_FULLSCREEN ) {
            fullscreen = !fullscreen;
            return;
        }        

        if ( action == AppViewActions.SHOW_KEYBOARD ) {
            show_keyboard_debouncer.trigger(true);
            return;
        }

        if ( action == AppViewActions.HIDE_KEYBOARD ) {
            show_keyboard_debouncer.trigger(false);
            return;
        }

    }

    private void load_style_rc_file() {

        string contents = """
            style "app-font" {
                font_name = "Amazon Ember Regular 10"
                InkButton::ink-border = 1                  
                InkScrolledWindow::ink-border = 1                  
            }

            widget_class "*" style "app-font"

            style "primary" {
                bg[NORMAL]   = "#000000" # normal background (0)
                fg[NORMAL]   = "#FFFFFF" # normal text (0) 
                bg[ACTIVE]   = "#FFFFFF" # pressed (active toggle?) background (1)
                fg[ACTIVE]   = "#000000" # pressed (active toggle?) text (1)
                bg[SELECTED] = "#000000" # ?
                fg[SELECTED] = "#FFFFFF" # ?      
                bg[PRELIGHT] = "#000000" # hover background (2)
                fg[PRELIGHT] = "#FFFFFF" # hover text (2)
            }
            style "secondary" {
                bg[NORMAL]   = "#FFFFFF" # normal background
                fg[NORMAL]   = "#000000" # normal text  
                bg[ACTIVE]   = "#000000" # pressed (active?) background 
                fg[ACTIVE]   = "#FFFFFF" # pressed (active?) text 
                bg[SELECTED] = "#FFFFFF" # ?
                fg[SELECTED] = "#000000" # ?      
                bg[PRELIGHT] = "#FFFFFF" # hover background
                fg[PRELIGHT] = "#000000" # hover text
            }
            widget "*app-dark*" style "primary"
            widget "*app-dark*.drawing-area-container" style "secondary"
            widget "*app-light*" style "secondary"
            widget "*app-light*.drawing-area-container" style "primary"

            style "button" {
                xthickness = 0
                ythickness = 0
                GtkWidget::focus-line-width = 0
                GtkWidget::focus-padding = 0
            }
            
            widget_class "*GtkButton" style "button"
            widget_class "*InkButton" style "button"


            widget_class "*GtkToggleButton" style "button"
            widget_class "*GtkRadioButton" style "button"
            widget_class "*InkRadioButton" style "button"
            widget_class "*InkToggleButton" style "button"

            style "slider"
            {
                font_name = "Amazon Ember Regular 8"
                GtkRange::trough-border = 0
                GtkRange::slider-width = @35
                GtkScale::slider-length = @35    
            }
            widget_class "*InkHScale" style "slider"
            widget_class "*GtkHScale" style "slider"
        """;

        var scaling = get_screen().get_width() / 600.0;
        var regex   = new Regex ("@(\\d+)");

        var style_rc_file_content = regex.replace_eval ((string) contents, contents.length, 0, 0, (mi, result) => {
            var s = mi.fetch (1); // string
            var n = int.parse (s);
            result.append (((int) (n * scaling)).to_string ());

            debug("scaling %f %s to %s", scaling, s,  ((int) (n * scaling)).to_string () );

            return false;
        });

        rc_parse_string ( style_rc_file_content );

    }

    private void save_settings () {
        var fs = FileStream.open ( config_file, "w");
        fs.puts ( keyfile.to_data ());
    }


    private void show_keyboard (bool show = true) {

        debug("show_keyboard %s", show.to_string());
        var visible = lipstick.get_int_property("com.lab126.keyboard", "show") == 1;

        if ( show == visible )
            return;
        
        if (show) {
            debug("show k %s", show.to_string());
            lipstick.set_string_property("com.lab126.keyboard", "open", @"$(app_id):abc:1");
        } else {
            debug("hode k %s", show.to_string());
            lipstick.set_string_property("com.lab126.keyboard", "close", @"$(app_id)");
        }

    }    

    ~AnkiReviewer() {
        debug("destroying AnkiReviewer");
    }

    private static string? config_file = null;
    private static string exe_dir = null;

    private const OptionEntry[] options = {
        { "config", 'c', 0, OptionArg.FILENAME, ref config_file, "Config file", "FILE" },
        { null }
    };    

    public static int main (string[] args) {
        Gtk.init (ref args);

        {
            var _webview = new WebKit.WebView ();
        }

        string exe_path = null;

        try {
            exe_path = FileUtils.read_link("/proc/self/exe"); // bin file path
        } catch (Error e) {
            warning("Failed to find executable path: %s\n", e.message);
            exe_path = args[0];
        }

        exe_dir = Path.get_dirname(exe_path);

        try {      
            var opt_context = new OptionContext ("- OptionContext example");
            opt_context.set_help_enabled (true);
            opt_context.add_main_entries (options, null);                  
			opt_context.parse (ref args);
		} catch (OptionError e) {
			printerr ("error: %s\n", e.message);
			printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return Posix.EXIT_FAILURE;
		}


        if (config_file == null) {
            config_file = Path.build_filename( exe_dir, "config.ini");
        }

        if ( !Path.is_absolute(config_file) ) {
            config_file = Path.build_filename( realpath("."), config_file);
        }

        debug(@"config_file $config_file");

        try {

            self = new AnkiReviewer ();
            self.destroy.connect (() => Gtk.main_quit ());

            Posix.signal (Posix.SIGINT, (sig) => {
                GLib.Idle.add (() => {
                    if (self != null)
                        self.destroy ();
                    return false;
                });
            });

        } catch (Error e) {

            warning ("[error]: %s", e.message);

            var dialog = new Gtk.MessageDialog (
                null,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.CLOSE,
                "[error]: %s",
                e.message
            );

            dialog.title = "L:A_N:application_ID:error_PC:N";
            dialog.run();
            dialog.destroy();

            return Posix.EXIT_FAILURE;
        }

        Gtk.main ();

        return Posix.EXIT_SUCCESS;
    }

}