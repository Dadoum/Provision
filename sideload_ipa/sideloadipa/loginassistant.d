module sideloadipa.loginassistant;

import gdk.Cursor;
import gdk.Threads;

import gobject.ObjectG;

import gtk.Assistant;
import gtk.Box;
import gtk.Button;
import gtk.EditableIF;
import gtk.Entry;
import gtk.HeaderBar;
import gtk.Label;
import gtk.Main;
import gtk.Widget;
import gtk.Window;

import sideloadipa.appleloginsession;
import sideloadipa.loginslide;
import sideloadipa.iflowslide;
import sideloadipa.tfaslide;
import sideloadipa.utils;

class LoginAssistant: Window {
    shared AppleLoginSession session;

    Button cancelButton;
    Button nextButton;
    Button previousButton;

    Cursor defaultCursor;
    Cursor waitCursor;

    Label title;

    IFlowSlide[] history;
    private bool initialized = false;

    this(Window parent) {
        super("Log-in to Apple");
        this.setModal(true);
        this.setTypeHint(WindowTypeHint.DIALOG);
        this.setTransientFor(parent);
        this.setResizable(false);
        this.setDeletable(false);

        defaultCursor = new Cursor(CursorType.LEFT_PTR);
        waitCursor = new Cursor(CursorType.WATCH);

        HeaderBar bar = new HeaderBar();
        cancelButton = new Button(StockID.CANCEL);
        nextButton = new Button(StockID.GO_FORWARD);
        previousButton = new Button(StockID.GO_BACK);

        cancelButton.setNoShowAll(true);
        nextButton.setNoShowAll(true);
        previousButton.setNoShowAll(true);

        bar.packStart(cancelButton);
        bar.packStart(previousButton);
        bar.packEnd(nextButton);

        nextButton.setSensitive(false);

        cancelButton.show();
        nextButton.show();
        this.setTitlebar(bar);

        previousButton.addOnPressed((btn) {
            import std.range.primitives;
            auto last = history.back();
            history.popBack();
            if (!history.length) {
                previousButton.hide();
            }
            Widget w = this.getChild();
            if (w) {
                this.remove(w);
            }

            this.add(cast(Widget) last);
        });
        nextButton.addOnPressed((btn) {
            setBusy(true);
        });

        auto loginSlide = new LoginSlide(this);

        // this.setPadding(8);
        changeSlide(loginSlide);
    }

    void setBusy(bool busy) {
        cancelButton.setSensitive(!busy);
        nextButton.setSensitive(!busy);
        previousButton.setSensitive(!busy);
        setCursor(busy ? waitCursor : defaultCursor);
    }

    void changeSlide(IFlowSlide slide) {
        Widget w = this.getChild();
        if (w) {
            history ~= cast(IFlowSlide) w;
            previousButton.show();
            this.remove(w);
        }

        this.add(cast(Widget) slide);
    }

    void setPageComplete(bool complete) {
        nextButton.setSensitive(complete);
    }
}
