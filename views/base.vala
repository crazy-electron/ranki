using Gtk;
using GLib;

public abstract class AppView : Gtk.EventBox { // Gtk.Bin ?

    public signal void navigate (owned AppView next);
    public signal void exit_app ();
    public signal void do_action (AnkiReviewer.AppViewActions action);
    
    public virtual void ready(){}

    public virtual double scaling { get {
        return get_screen().get_width() / 600.0;
    } }

    public virtual KeyFile keyfile {  get {
        unowned KeyFile? _keyfile = get_data<KeyFile> ("keyfile");
        return _keyfile;
    } }

    public virtual Backend backend { get {
        unowned Backend? _backend = get_data<Backend> ("backend");
        return _backend;
    } }    

    public abstract string get_template();
    public Gtk.Builder builder;

    public AppView() {

        builder = new Gtk.Builder ();
        builder.add_from_string (get_template(), -1);
        builder.connect_signals(this);

        var main_vbox = builder.get_object ("main_vbox") as VBox;
        main_vbox.spacing      = (int) (20 * scaling); // scale
        main_vbox.border_width = (int) (20 * scaling); // scale        

        add ( main_vbox );
        
    }


}