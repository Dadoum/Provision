module sideloadipa.loginassistant;

import gdk.Cursor;
import gdk.Threads;

import gobject.ObjectG;

import gtk.Alignment;
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

    HeaderBar bar;

    Label title;
    Alignment content;

    shared IFlowSlide slide;

    shared(IFlowSlide)[] history;
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

        bar = new HeaderBar();
        cancelButton = new Button(StockID.CANCEL);
        nextButton = new Button(StockID.GO_FORWARD);
        previousButton = new Button(StockID.GO_BACK);

        enum margin = 8;
        content = new Alignment(0.5, 0.5, 1, 1);
        content.setMarginTop(margin);
        content.setMarginBottom(margin);
        content.setMarginLeft(margin);
        content.setMarginRight(margin);
        add(content);

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
            Widget w = content.getChild();
            if (w) {
                content.remove(w);
            }

            content.add(cast(Widget) last);
            this.slide = last;
        });
        nextButton.addOnPressed((btn) {
            setBusy(true);
            this.slide.setBusy(true);

            import std.concurrency;
            spawn(delegate(shared(IFlowSlide) slide) shared {
                shared(IFlowSlide) nextSlide = slide.run();
                import glib.Idle;
                new Idle(() {
                    this.slide.setBusy(false);
                    if (nextSlide is null) {
                        // go next
                    } else {
                        if (slide != nextSlide)
                            changeSlide(nextSlide);
                        this.slide.setBusy(false);
                    }
                    setBusy(false);
                    return false;
                }, true);
            }, this.slide);
        });

        __gshared LoginSlide loginSlide;
        loginSlide = new LoginSlide(this);

        // this.setPadding(8);
        changeSlide(cast(shared LoginSlide) loginSlide);
    }

    void setBusy(bool busy) {
        cancelButton.setSensitive(!busy);
        nextButton.setSensitive(!busy);
        previousButton.setSensitive(!busy);
        setCursor(busy ? waitCursor : defaultCursor);
    }

    void changeSlide(shared IFlowSlide slide) {
        bar.setTitle(slide.title());

        Widget w = content.getChild();
        if (w) {
            history ~= cast(shared IFlowSlide) w;
            previousButton.show();
            content.remove(w);
        }

        content.add(cast(Widget) slide);
        this.slide = slide;
    }

    void setPageComplete(bool complete) {
        nextButton.setSensitive(complete);
    }
}
