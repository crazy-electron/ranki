using Gtk;
using GLib;
using CrazySpices;

public class SettingsView : AppView {

    public override string get_template(){

        return """
            <interface>
                <object class="GtkVBox" id="main_vbox">

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
                            </packing>                            
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

    public SettingsView ( string data = "") {

        debug("new SettingsView");

        back_button = builder.get_object ("back_button") as Button;
        
        back_button.clicked.connect (() => navigate( new DeckTreeView() ));
        
        username_entry = builder.get_object ("username_entry") as Entry;
        password_entry = builder.get_object ("password_entry") as Entry;
        login_button   = builder.get_object ("login_button") as Button;
        
        content_scale  = builder.get_object ("content_scale") as InkRowHScale;
        content_scale.upper = 5;
        content_scale.lower = 1;

        username_entry.focus_in_event.connect (() => {
            debug("username_entry.focus_in_event");
            do_action(AnkiReviewer.AppViewActions.SHOW_KEYBOARD);
            return false;
        });

        username_entry.focus_out_event.connect (() => {
            debug("username_entry.focus_out_event");
            do_action(AnkiReviewer.AppViewActions.HIDE_KEYBOARD);
            return false;
        });             

        password_entry.focus_in_event.connect (() => {
            password_entry.visibility = true;
            do_action(AnkiReviewer.AppViewActions.SHOW_KEYBOARD);
            return false;
        });

        password_entry.focus_out_event.connect (() => {
            password_entry.visibility = false;
            do_action(AnkiReviewer.AppViewActions.HIDE_KEYBOARD);
            return false;
        });

    }

    public override void ready(){
        login_button.clicked.connect (() => login());

        bind_settings<double> (keyfile, "General", "scale", content_scale, "value", () => { 
            do_action(AnkiReviewer.AppViewActions.SAVE_SETTINGS);
        });
    }

    private async void login() {

        username_entry.set_sensitive(false);
        password_entry.set_sensitive(false);
        login_button.set_sensitive(false);
        back_button.set_sensitive(false);
        
        try {

            var a_sync_synclogin_req = new Anki.Sync.SyncLoginRequest() {
                username = username_entry.text,
                password = password_entry.text,
                endpoint = "https://ankiweb.net/"
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

        username_entry.set_sensitive(true);
        password_entry.set_sensitive(true);
        login_button.set_sensitive(true);
        back_button.set_sensitive(true);

    }

    ~SettingsView() {
        debug("destroying SettingsView");
    }    

}