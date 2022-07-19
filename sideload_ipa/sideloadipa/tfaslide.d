module sideloadipa.tfaslide;

import gtk.Box;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Label;

import sideloadipa.loginassistant;
import sideloadipa.iflowslide;

class TFASlide: Box, IFlowSlide {
    import gtkd.Implement;
    import gobject.c.functions : g_object_newv;

    mixin ImplementClass!GtkBox;

    LoginAssistant assistant;
    __gshared Entry[6] entries;

    __gshared private bool b;

    string title() shared { return "2FA code"; }

    this(LoginAssistant assistant) {
        super(Orientation.VERTICAL, 0);
        this.assistant = assistant;

        Box mainBox = new Box(Orientation.VERTICAL, 4);
        mainBox.add(new Label("Please enter the code you received"));

        Box numberBoxes = new Box(Orientation.HORIZONTAL, 4);

        static foreach (a; 0..typeof(entries).length) {{
            entries[a] = new Entry;
            entries[a].setWidthChars(1);
            entries[a].setAlignment(0.5);

            auto font = entries[a].getPangoContext().getFontDescription();
            font.setAbsoluteSize(font.getSize() * 3);
            entries[a].getPangoContext().setFontDescription(font);

            entries[a].setSizeRequest(0, 30);
            entries[a].setMaxLength(1);

            entries[a].addOnChanged((_) {
                import std.ascii;
                auto text = entries[a].getText();
                auto flag = text == "";

                checkNextButton();
                if (b)
                    return;

                if (!(flag || isDigit(text[0]))) {
                    b = true;
                    entries[a].setText("");
                    b = false;
                } else {
                    static if (a != 0) {
                        if (flag) {
                            entries[a - 1].grabFocus();
                        }
                    }

                    static if (a != typeof(entries).length - 1) {
                        if (!flag) {
                            entries[a + 1].grabFocus();
                        }
                    }
                }
            });
            numberBoxes.packStart(entries[a], true, true, 0);
        }}
        mainBox.packStart(numberBoxes, true, true, 0);

        this.add(mainBox);
    }

    void checkNextButton() {
        bool complete = true;

        static foreach (a; 0..typeof(entries).length) {
            complete &= entries[a].getText() != "";
        }

        assistant.setPageComplete(complete);
    }

    void setBusy(bool busy) shared {
        static foreach (a; 0..typeof(entries).length) {
            entries[a].setSensitive(!busy);
        }
    }

    shared(IFlowSlide) run() shared {
        import std.stdio;
        writeln("Validation...");
        return this;
    }
}
