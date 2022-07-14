module sideloadipa.loginslide;

import gtk.Box;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Label;

import sideloadipa.appleloginsession;
import sideloadipa.iflowslide;
import sideloadipa.loginassistant;
import sideloadipa.tfaslide;
import sideloadipa.utils;

class LoginSlide: Box, IFlowSlide {
    import gtkd.Implement;
    import gobject.c.functions : g_object_newv;

    mixin ImplementClass!GtkBox;

    LoginAssistant assistant;

    Label errorLabel;

    Entry appleId;
    Entry password;

    string title() { return "Log-in to your Apple account"; }

    this(LoginAssistant assistant) {
        super(Orientation.VERTICAL, 4);
        this.assistant = assistant;

        errorLabel = new Label("");
        errorLabel.setNoShowAll(true);
        errorLabel.getStyleContext().addClass(STYLE_CLASS_ERROR);
        this.packStart(errorLabel, false, false, 0);

        auto internBox = new Box(Orientation.VERTICAL, 4);
        appleId = new Entry();
        appleId.setPlaceholderText("Apple ID");
        appleId.addOnChanged(&checkNextButton);
        internBox.add(appleId);
        password = new Entry();
        password.setVisibility(false);
        password.setPlaceholderText("Password");
        password.addOnChanged(&checkNextButton);
        internBox.add(password);

        this.packStart(internBox, false, false, 0);

        Label label = new Label("<small>your credentials are <b>only</b> sent to Apple</small>");
        label.setUseMarkup(true);
        this.add(label);
    }

    int run() {
        string appleIdStr = appleId.getText();
        string passwordStr = password.getText();
        setButtonsEnabled(false);

        import std.concurrency;
        spawn(function (AppleLoginSession* appleLoginSession, string appleIdStr, string passwordStr, shared(void*) slide) {
            import glib.Idle;
            new Idle(() {
                auto assistant = (cast(LoginSlide) slide).assistant;
                assistant.setCursor(assistant.waitCursor);
                return false;
            }, true);

            if (*appleLoginSession) {
                object.destroy(*appleLoginSession);
            }

            *appleLoginSession = new shared AppleLoginSession();

            __gshared string errorStr;
            auto res = appleLoginSession.login(appleIdStr, passwordStr, errorStr);

            new Idle(() {
                if (slide == null) {
                    return false;
                }

                auto self = cast(LoginSlide) slide;
                if (self.assistant is null) {
                    return false;
                }

                if (res == AppleLoginResponse.errored) {
                    self.errorLabel.show();
                    self.errorLabel.setText(errorStr);
                }
                self.setButtonsEnabled(true);
                self.assistant.setCursor(self.assistant.defaultCursor);
                return false;
            }, true);
        }, &assistant.session, appleIdStr, passwordStr, cast(shared void*) this);

        // import glib.Idle;
        // new Idle(() {
        //     if (assistant.session) {
        //         object.destroy(assistant.session);
        //     }

        //     __gshared string errorStr;
        //     assistant.session = new shared AppleLoginSession();

        //     auto res = assistant.session.login(appleIdStr, passwordStr, errorStr);
        //     if (res == AppleLoginResponse.errored) {
        //         this.errorLabel.show();
        //         this.errorLabel.setText(errorStr);
        //     }
        //     this.setButtonsEnabled(true);
        //     return false;
        // }, true);
        return 0;
    }

    void setButtonsEnabled(bool enabled) {
        assistant.setCursor(enabled ? assistant.defaultCursor : assistant.waitCursor);
        appleId.setSensitive(enabled);
        password.setSensitive(enabled);
        assistant.setPageComplete(enabled);
    }

    void checkNextButton(EditableIF) {
        string appleIdStr = appleId.getText();
        string passwordStr = password.getText();
        assistant.setPageComplete(appleIdStr != "" && passwordStr != "");
    }
}
