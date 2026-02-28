using Gtk;
using GLib;
using WebKit;

public class ReviewView : AppView {

    public override string get_template(){

        return """
            <interface>
                <object class="GtkVBox" id="main_vbox">

                    <child>
                    <object class="GtkHBox" id="hbox2">     
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

                        <child>
                        <object class="InkButton" id="bury_btn">
                            <property name="label">Bury card</property>
                            <property name="no_show_all">True</property>
                        </object>
                        <packing>
                            <property name="expand">False</property>
                        </packing>
                        </child>

                        <child>
                        <object class="InkButton" id="rebuild_button">
                            <property name="label">Rebuild deck</property>                            
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
                    <object class="WebKitWebView" id="card_content">
                        <property name="no_show_all">True</property>
                        <property name="zoom_level">2</property>
                        
                    </object>
                    <packing>
                        <property name="expand">True</property>
                        <property name="fill">True</property>
                    </packing>
                    </child>                                  
             
                    <child>
                    <object class="GtkLabel" id="stats_lbl">
                        <property name="label"></property>
                        <property name="no_show_all">True</property>
                        <property name="use_markup">True</property>
                    </object>
                    <packing>
                        <property name="expand">False</property>
                        <property name="fill">False</property>
                    </packing>
                    </child>

                    <child>
                    <object class="GtkHBox" id="answer_box">
                        <property name="homogeneous">True</property>
                        <property name="spacing">10</property>
                        <child>
                        <object class="InkButton" id="again_btn">
                            <property name="label">Again</property>
                            <property name="no_show_all">True</property>
                        </object>
                        <packing>
                     
                        </packing>
                        </child>
                        <child>
                        <object class="InkButton" id="hard_btn">
                            <property name="label">Hard</property>
                            <property name="no_show_all">True</property>
                        </object>
                        <packing>
                            
                        </packing>
                        </child>
                        <child>
                        <object class="InkButton" id="good_btn">
                            <property name="label">Good</property>
                            <property name="no_show_all">True</property>
                        </object>
                        <packing>
                            
                        </packing>
                        </child>

                        <child>
                        <object class="InkButton" id="easy_btn">
                            <property name="label">Easy</property>
                            <property name="no_show_all">True</property>
                        </object>
                        <packing>                            
                        </packing>
                        </child>

                        <child>
                        <object class="InkButton" id="show_answer_btn">
                            <property name="label">Show Answer</property>
                            <property name="no_show_all">True</property>
                        </object>
                        <packing>                            
                        </packing>
                        </child>                        

                    </object>
                    <packing>
                        <property name="expand">False</property>
                        <property name="fill">False</property>
                    </packing>
                    </child>

                </object>
            </interface>              
        """;

    }

    private int64 deck_id;

    private WebView card_content;

    private Label stats_lbl;

    private Button bury_btn;
    private Button again_btn;
    private Button hard_btn;
    private Button good_btn;
    private Button easy_btn;
    private Button show_answer_btn;

    private string card_question_text = "";
    private string card_answer_text = "";
    private string card_css = "";

    private string base_uri = "";

    private int64 card_shown_at = 0;
    private uint32 milliseconds_taken = 0;

    private Anki.Scheduler.QueuedCards.QueuedCard? queued_card;

    public ReviewView ( int64 _deck_id = 0 ) { 
        
        deck_id = _deck_id;

        (builder.get_object ("back_button") as Button).clicked.connect (() => {
            navigate( new DeckTreeView() );
        });

        bury_btn = builder.get_object ("bury_btn") as Button;
        bury_btn.clicked.connect (() => bury_card());
        

        card_content  = builder.get_object ("card_content") as WebView;

        //  card_content.motion_notify_event.connect( () => {
        //      debug("motion_notify_event");
        //      return false;
        //  });

        var answer_box  = builder.get_object ("answer_box") as HBox;
        answer_box.height_request = (int) (90 * scaling);

        stats_lbl  = builder.get_object ("stats_lbl") as Label;

        again_btn = builder.get_object ("again_btn") as Button;
        hard_btn  = builder.get_object ("hard_btn") as Button;
        good_btn  = builder.get_object ("good_btn") as Button;
        easy_btn  = builder.get_object ("easy_btn") as Button;

        again_btn.clicked.connect (() => answer_card(Anki.Scheduler.CardAnswer.Rating.AGAIN));
        hard_btn.clicked.connect (() => answer_card(Anki.Scheduler.CardAnswer.Rating.HARD));
        good_btn.clicked.connect (() => answer_card(Anki.Scheduler.CardAnswer.Rating.GOOD));
        easy_btn.clicked.connect (() => answer_card(Anki.Scheduler.CardAnswer.Rating.EASY));

        show_answer_btn = builder.get_object ("show_answer_btn") as Button;

        show_answer_btn.clicked.connect (() => show_answer());

    }

    public override void ready() {

        debug("DeckTreeView ready");

        try { 
            card_content.set_zoom_level(
                (float) (keyfile.get_double("General", "scale") * scaling)
            );
        } catch (Error e) {
            //
        }

        var collection_media_dir = get_data<string> ("collection_media_dir");
        base_uri = "file://" + Path.build_filename (collection_media_dir, "") + "/";

        debug(@"base_uri $base_uri");

        var selected_deck_id_req = new Anki.Decks.DeckId(){ did = deck_id };

        backend.run_command( 7, 22, selected_deck_id_req);

        next_card();

    }

    private void next_card() {

        bury_btn.hide();

        stats_lbl.hide();
        again_btn.hide();
        hard_btn.hide();
        good_btn.hide();
        easy_btn.hide();

        //show_answer_btn.hide();

        var queued_req = new Anki.Scheduler.GetQueuedCardsRequest(){
            fetch_limit = 1,
            intraday_learning_only = false
        };

        var queued = new Anki.Scheduler.QueuedCards();

        backend.run_command( 13, 3, queued_req, queued);

        if (queued.cards.length() == 0) {
            debug("Congrats");
            
            card_content.hide();

            queued_card = null;
            return;
        }
        
        queued_card = queued.cards.nth_data(0);

        debug("QueuedCards %s", queued.to_string() );
        debug("queued card %s", queued_card.card.to_string() );

        var rreq = new Anki.Card_rendering.RenderExistingCardRequest(){
            card_id = queued_card.card.id,
            browser = false,
            partial_render = false
        };

        var rresp = new Anki.Card_rendering.RenderCardResponse();

        backend.run_command( 27, 6, rreq, rresp);

        card_question_text = rresp.question_nodes.length() > 0 ? rresp.question_nodes.nth_data(0).text : "";
        card_answer_text   = rresp.answer_nodes.length() > 0 ? rresp.answer_nodes.nth_data(0).text : "";
        card_css = rresp.css;
        debug("rresp.question_nodes.length() %d", (int) rresp.question_nodes.length() );

        bury_btn.show();

        card_content.show();

        string html_content = @"
            <!doctype html>
            <html>
                <head>
                    <meta charset=\"utf-8\">
                    <style>$card_css</style>
                </head>
                <body>
                    <div class=\"card kindle\">$card_question_text</div>
                </body>
            </html>
        ";

        card_content.load_html_string (html_content, base_uri);

        string stats_lbl_text = "";
        stats_lbl_text += (queued_card.card.queue == Anki.Scheduler.QueuedCards.Queue.NEW) ? @"<u>$(queued.new_count)</u>" : @"$(queued.new_count)";
        stats_lbl_text += " + ";
        stats_lbl_text += (queued_card.card.queue == Anki.Scheduler.QueuedCards.Queue.LEARNING) ? @"<u>$(queued.learning_count)</u>" : @"$(queued.learning_count)";
        stats_lbl_text += " + ";
        stats_lbl_text += (queued_card.card.queue == Anki.Scheduler.QueuedCards.Queue.REVIEW) ? @"<u>$(queued.review_count)</u>" : @"$(queued.review_count)";
        // TODO add today
        stats_lbl.set_markup ( stats_lbl_text );
        stats_lbl.show();

        var next_states = new Anki.Generic.StringList();

        backend.run_command( 13, 24, queued_card.states, next_states);

        again_btn.set_label( next_states.vals.nth_data(Anki.Scheduler.CardAnswer.Rating.AGAIN).replace("\u2068", "").replace("\u2069", "") + "\nAgain" );
        hard_btn.set_label( next_states.vals.nth_data(Anki.Scheduler.CardAnswer.Rating.HARD).replace("\u2068", "").replace("\u2069", "") + "\nHard" );
        good_btn.set_label( next_states.vals.nth_data(Anki.Scheduler.CardAnswer.Rating.GOOD).replace("\u2068", "").replace("\u2069", "") + "\nGood" );
        easy_btn.set_label( next_states.vals.nth_data(Anki.Scheduler.CardAnswer.Rating.EASY).replace("\u2068", "").replace("\u2069", "") + "\nEasy" );        

        show_answer_btn.show();

        card_shown_at = get_real_time();
    }

    private void show_answer() {

        string html_content = @"
            <!doctype html>
            <html>
                <head>
                    <meta charset=\"utf-8\">
                    <style>$card_css</style>
                </head>
                <body>
                    <div class=\"card kindle\">$card_answer_text</div>
                </body>
            </html>
        ";

        card_content.load_html_string (html_content, base_uri);

        again_btn.show();
        hard_btn.show();
        good_btn.show();
        easy_btn.show();
        show_answer_btn.hide();

        milliseconds_taken = (uint32) ((get_real_time() - card_shown_at) / 1000);

        if ( milliseconds_taken > 60 * 1000 ) {
            milliseconds_taken = 60 * 1000; // get max from config
        }
        
        debug (@"milliseconds_taken $(milliseconds_taken)");

    }

    private void answer_card(Anki.Scheduler.CardAnswer.Rating rating) {

        // pylib/anki/scheduler/v3.py
        Anki.Scheduler.SchedulingState new_state;

        if (rating == Anki.Scheduler.CardAnswer.Rating.AGAIN) {
            new_state = queued_card.states.again;
        }
        else if (rating == Anki.Scheduler.CardAnswer.Rating.HARD) {
            new_state = queued_card.states.hard;
        }
        else if (rating == Anki.Scheduler.CardAnswer.Rating.GOOD) {
            new_state = queued_card.states.good;
        }              
        else if (rating == Anki.Scheduler.CardAnswer.Rating.EASY) {
            new_state = queued_card.states.easy;
        }
        else {
            // throw
            return;
        }

        var card_answer = new Anki.Scheduler.CardAnswer() {
            card_id=queued_card.card.id,
            current_state=queued_card.states.current,
            new_state=new_state,
            rating=rating,
            answered_at_millis=get_real_time() / 1000,
            milliseconds_taken=milliseconds_taken
        };

        var op_changes = new Anki.Collection.OpChanges();

        backend.run_command( 13, 4, card_answer, op_changes);

        debug("op_changes %s", op_changes.to_string());

        next_card();
    }

    private void bury_card() {

        if ( queued_card == null ) {
            return;
        }

        var card_ids = new List<int64?> ();

        card_ids.append( queued_card.card.id );

        var bury_req = new Anki.Scheduler.BuryOrSuspendCardsRequest(){
            mode = Anki.Scheduler.BuryOrSuspendCardsRequest.Mode.BURY_USER,
            card_ids = (owned) card_ids
        };

        var op_changes_count = new Anki.Collection.OpChangesWithCount();

        backend.run_command( 13, 14, bury_req, op_changes_count);

        debug("op_changes %s", op_changes_count.to_string());

        next_card();
    }

    ~ReviewView() {
        debug("destroying ReviewView");
    }
}