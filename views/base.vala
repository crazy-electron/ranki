using Gtk;
using GLib;
using CrazySpices;

public abstract class AppView : EventBox, Initable { // Bin ?

    public signal void navigate (Type view_type, owned Parameter[] parameters = {});    
    public signal void exit_app ();
    public signal void do_action (AnkiReviewer.AppViewActions action);

    public virtual double scaling { get {
        return get_screen().get_width() / 600.0;
    } }

    public virtual KeyFile keyfile { get {
        return store.get_item<unowned KeyFile> ("keyfile");
    } }

    public virtual Backend backend { get {
        return store.get_item<unowned Backend> ("backend");
    } }    

    public abstract string get_template();
    public Builder builder;
    public Array<Cancellable> cancellables = new Array<Cancellable>();

    public unowned Store store { get; construct; }

    public virtual void ready( /* Store store, ... */ ) throws Error {}

    public virtual bool init (Cancellable? cancellable = null) throws Error {

        builder = new Builder ();
        builder.add_from_string (get_template(), -1);
        builder.connect_signals(this);

        var main_vbox = builder.get_object ("main_vbox") as VBox;
        main_vbox.spacing      = (int) (20 * scaling); // scale
        main_vbox.border_width = (int) (20 * scaling); // scale        

        add ( main_vbox );

        ready();

        return true;
        
    }

    ~AppView() {
        debug("destroy AppView");
    }

}