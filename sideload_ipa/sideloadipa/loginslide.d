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

    __gshared LoginAssistant assistant;

    __gshared Label errorLabel;

    __gshared Entry appleId;
    __gshared Entry password;

    string title() shared { return "Log-in to your Apple account"; }

    this(LoginAssistant assistant) {
        super(Orientation.VERTICAL, 4);
        this.assistant = assistant;

        errorLabel = new Label("");
        errorLabel.setNoShowAll(true);
        errorLabel.setLineWrap(true);
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

    shared(IFlowSlide) run() shared {
        string appleIdStr = appleId.getText();
        string passwordStr = password.getText();

        if (assistant.session) {
            object.destroy(assistant.session);
        }

        __gshared string errorStr;
        assistant.session = new shared AppleLoginSession();

        auto res = assistant.session.login(appleIdStr, passwordStr, errorStr);
        import glib.Idle;
        new Idle(() {
            if (res == AppleLoginResponse.errored) {
                this.errorLabel.show();
                this.errorLabel.setText(errorStr);
            }
            return false;
        }, true);
        return this;
    }

    void setBusy(bool busy) shared {
        appleId.setSensitive(!busy);
        password.setSensitive(!busy);
    }

    void checkNextButton(EditableIF) {
        string appleIdStr = appleId.getText();
        string passwordStr = password.getText();
        assistant.setPageComplete(appleIdStr != "" && passwordStr != "");
    }
}
