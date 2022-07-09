module sideloadipa.loginassistant;

import gdk.Cursor;
import gdk.Threads;

import gobject.ObjectG;

import gtk.Assistant;
import gtk.Box;
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

class LoginAssistant: Assistant {
    AppleLoginSession session;

    IFlowSlide currentSlide;

    Cursor defaultCursor;
    Cursor waitCursor;

    Label title;

    IFlowSlide[] refs;

    private int currentPage = 0;
    private bool initialized = false;

    this(Window parent) {
        this.setModal(true);
        this.setTypeHint(WindowTypeHint.DIALOG);
        this.setTransientFor(parent);
        this.setResizable(false);

        this.addOnCancel((_) {
            this.destroy();
        });

        auto loginSlide = new LoginSlide(this);
        refs ~= loginSlide;
        currentSlide = loginSlide;
        this.appendPage(loginSlide);
        this.title = new Label("");
        title.getStyleContext().addClass(STYLE_CLASS_TITLE);
        import gtk.c.functions;
        HeaderBar bar = ObjectG.getDObject!(HeaderBar)(cast(GtkHeaderBar*) gtk_window_get_titlebar(this.getWindowStruct()));
        bar.setCustomTitle(this.title);
        object.destroy(bar);
        auto twoFactorAuth = new TFASlide(this);
        refs ~= twoFactorAuth;
        this.appendPage(twoFactorAuth);

        defaultCursor = new Cursor(CursorType.LEFT_PTR);
        waitCursor = new Cursor(CursorType.WATCH);

        bool isPreparing = false;

        addOnPrepare((page, self) {
            this.title.setText((cast(IFlowSlide) page).title);

            if (!initialized) {
                initialized = true;
                return;
            }

            if (isPreparing) {
                return;
            }

            bool goBack = this.getCurrentPage() - currentPage < 0;

            if (!goBack) {
                this.setCursor(waitCursor);
                Main.iteration();
                auto avancement = (cast(IFlowSlide) self.getNthPage(currentPage)).run();
                this.setCursor(defaultCursor);
                isPreparing = true;
                if (avancement) {
                    self.setCurrentPage(currentPage + avancement);
                    currentPage = currentPage + avancement;
                } else {
                    self.previousPage();
                }
                isPreparing = false;
            } else {
                currentPage -= 1;
            }
        });
    }
}
