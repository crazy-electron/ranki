
using Gtk;
using GLib;
using CrazySpices;

public class DeckTreeView : AppView {

    private InkTreeView view;

    public override string get_template(){

        return """
            <interface>
                <object class="GtkVBox" id="main_vbox">

                    <child>
                    <object class="GtkHBox" id="hbox2">
                        <property name="spacing">10</property>                   
                        <child>
                        <object class="InkButton" id="exit_button">
                            <property name="label">Exit</property>                            
                        </object>
                        <packing>
                            <property name="expand">False</property>
                        </packing>
                        </child>
                        
                        <child>
                        <object class="InkButton" id="fullscreen_btn">
                            <property name="label">Fullscreen</property>                            
                        </object>
                        <packing>
                            <property name="expand">False</property>
                        </packing>
                        </child>

                        <child>
                        <object class="InkButton" id="settings_button">
                            <property name="label">Settings</property>                            
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

                        <child>
                        <object class="InkButton" id="sync_button">
                            <property name="label">Sync</property>                            
                        </object>
                        <packing>
                            <property name="expand">False</property>
                        </packing>
                        </child>
                    </object>
                    <packing>
                        <property name="expand">False</property>
                    </packing>
                    </child>


                    <child>
                    <object class="InkScrolledWindow" id="scrolled_window">
                        <child>
                        <object class="InkTreeView" id="tree_view">
                            
                        </object>
                        </child>
                    </object>
                    <packing>
        
                    </packing>
                    </child>
                    
                    <child>
                    <object class="GtkSpinner" id="spinner">
                        <property name="no_show_all">True</property>
                        <property name="active">True</property>
                        <property name="width_request">100</property>
                        <property name="height_request">100</property>                        
                    </object>
                    <packing>
                        <property name="fill">False</property>
                    </packing>
                    </child>                 

                </object>
            </interface>              
        """;

    }

    private Button settings_button;
    private Button sync_button;
    private Spinner spinner;
    private ScrolledWindow scrolled_window;

    public DeckTreeView ( string data = "") {

        debug("new DeckTreeView");

        (builder.get_object ("exit_button") as Button).clicked.connect (() => exit_app());

        settings_button = builder.get_object ("settings_button") as Button;
        settings_button.clicked.connect (() => {
            debug("settings_button");
            navigate( new SettingsView() );
        });

        (builder.get_object ("fullscreen_btn") as Button).clicked.connect (() => {
            do_action(AnkiReviewer.AppViewActions.TOGGLE_FULLSCREEN);
        });    

        //  (builder.get_object ("show_modal") as Button).clicked.connect (() => {
        //      do_action(AnkiReviewer.AppViewActions.SAVE_SETTINGS);
        //  });             

        sync_button = builder.get_object ("sync_button") as Button;

        scrolled_window = builder.get_object ("scrolled_window") as ScrolledWindow;

        spinner = builder.get_object ("spinner") as Spinner;


        sync_button.clicked.connect (() => sync_collection_button());

        view = builder.get_object ("tree_view") as InkTreeView;

        var store = new TreeStore (5, 
            typeof (int64),   // 0: _deck_id
            typeof (string),  // 1: "Deck"
            typeof (string),  // 2: "New"
            typeof (string),  // 3: "Learn"
            typeof (string)   // 4: "Due"        
        );
    
        int xpad = (int) (10 * scaling);
        int ypad = (int) (10 * scaling);

        view.set_model (store);        
        view.insert_column_with_attributes (-1, "Deck", new CellRendererText () { ypad = ypad, xpad = xpad }, "text", 1, null);
        view.insert_column_with_attributes (-1, "New", new CellRendererText () { ypad = ypad, xpad = xpad }, "text", 2, null);
        view.insert_column_with_attributes (-1, "Learn", new CellRendererText () { ypad = ypad, xpad = xpad }, "text", 3, null);
        view.insert_column_with_attributes (-1, "Due", new CellRendererText () { ypad = ypad, xpad = xpad }, "text", 4, null);

        //  view.insert_column_with_data_func  (-1, "Deck Id", new CellRendererText (),
        //      (column, cell, model, iter) => {
        //          int64 deck_id;
        //          model.get (iter, 0, out deck_id);        // raw int64 column
        //          ((CellRendererText) cell).text = deck_id.to_string ();
        //      }
        //  );

        view.get_column ( 0 ).set_expand (true);

        view.path_selected.connect((path) => {
            var deck_id = get_deck_id_at_path(path);
            debug("select deck %lld", deck_id);
            navigate( new ReviewView( deck_id ) );
                      
        });

    }

    private void show_modal() {

        warning ("[error]: %s", "e.message");

        var dialog = new Gtk.MessageDialog (
            null,
            Gtk.DialogFlags.MODAL,
            Gtk.MessageType.ERROR,
            Gtk.ButtonsType.CLOSE,
            "[error]: %s",
            "e.message"
        );

        dialog.response.connect ((response_id) => {
            debug("response_id %d", (int)response_id);
			switch (response_id) {
				case Gtk.ResponseType.OK:
					print ("Ok\n");
					break;
				case Gtk.ResponseType.CANCEL:
					print ("Cancel\n");
					break;
				case Gtk.ResponseType.DELETE_EVENT:
					print ("Delete\n");
					break;
			}
            dialog.destroy();
        });     

        dialog.title = "L:A_N:application_ID:modal_PC:N";
        dialog.run();

    }

    public override void ready() {
        debug("DeckTreeView ready");
        populate_decktree();
    }

    private void populate_decktree() {

        var dtree_req = new Anki.Decks.DeckTreeRequest();
        dtree_req.now = (int64) (get_real_time () / 1e6);

        var dtree_node = new Anki.Decks.DeckTreeNode();

        backend.run_command( 7, 4, dtree_req, dtree_node);

        debug("dtree_node %s", dtree_node.to_string() );

        var store = view.get_model() as TreeStore;
        store.clear();
        
        foreach (Anki.Decks.DeckTreeNode child in dtree_node.children)
            append_deck (null, child);

        view.expand_all ();

    }

    private void append_deck (TreeIter? parent_iter, Anki.Decks.DeckTreeNode deck) {
        
        TreeIter iter;
        var store = view.get_model() as TreeStore;

        store.append (out iter, parent_iter);
        store.set (iter,
            0, deck.deck_id,
            1, deck.name ?? "Unnamed",
            2, @"$(deck.new_count)",    // New     
            3, @"$(deck.learn_count)",  // Learn
            4, @"$(deck.review_count)", // review
            -1);

        foreach (Anki.Decks.DeckTreeNode child in deck.children)
            append_deck (iter, child);
    }

    private int64 get_deck_id_at_path(TreePath path) {

        TreeIter iter;
        var model = view.get_model(); // TreeModel

        if (!model.get_iter(out iter, path)) {
            return -1;
        }
        int64 deck_id;

        model.get(iter, 0, out deck_id);

        return deck_id;
    }

    private async void sync_collection_button () {

        string hkey = "";

        try { 
            hkey = keyfile.get_string("General", "hkey") ;
            if ( hkey == null || hkey == "" ) {
                navigate( new SettingsView() );
                return;
            }
        } catch (Error e) {
            //
        }

        sync_button.set_sensitive(false);
        settings_button.set_sensitive(false);
        scrolled_window.hide();
        spinner.show();

        try {        

            var a_sync_syncauth = new Anki.Sync.SyncAuth() {
                hkey = hkey,
                endpoint = "https://ankiweb.net/"
            };

            yield run_thread<void>(
                () => backend.sync_collection(a_sync_syncauth)
            );

            populate_decktree();

        } catch (Error e) {

            // show_alert()

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

        }

        settings_button.set_sensitive(true);
        sync_button.set_sensitive(true);
        scrolled_window.show();
        spinner.hide();
    }

    ~DeckTreeView() {
        debug("destroying DeckTreeView");
    }

}