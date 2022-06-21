module app;

import gio.Application: GApp = Application;
import gtk.Application;

import sideloadipa.sideloadwindow;

class SideloadApplication: Application {
    this() {
        super("dadoum.SideloadIPA", ApplicationFlags.FLAGS_NONE);
        addOnActivate(&onActivate);
    }

    void onActivate(GApp app) {
        new SideloadWindow(this).showAll();
    }
}

int main(string[] args) {
    auto app = new SideloadApplication();
    return app.run(args);
}
