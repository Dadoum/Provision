module sideloadipa.loginslide;

import gtk.Box;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Label;

import sideloadipa.appleloginsession;
import sideloadipa.iflowslide;
import sideloadipa.loginassistant;
import sideloadipa.tfaslide;

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

        if (!assistant.session) {
            assistant.session = new AppleLoginSession();
        }

        string errorStr;
        auto res = assistant.session.login(appleIdStr, passwordStr, errorStr);

        if (res == AppleLoginResponse.errored) {
            this.errorLabel.show();
            this.errorLabel.setText(errorStr);
        }

        return cast(int) res;
    }

    void checkNextButton(EditableIF) {
        string appleIdStr = appleId.getText();
        string passwordStr = password.getText();
        assistant.setPageComplete(this, appleIdStr != "" && passwordStr != "");
    }
}
