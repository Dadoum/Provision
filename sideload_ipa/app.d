module app;

import gio.Application: GApp = Application;
import gio.SimpleAction;

import glib.Variant;
import glib.VariantType;

import gtk.c.functions;
import gtk.Application;
import gtk.LinkButton;
import gtk.MessageDialog;

import provision;

import sideloadipa.identity;
import sideloadipa.imobiledevice;
import sideloadipa.loginassistant;
import sideloadipa.sideloadwindow;

import std.algorithm;
import std.array;
import file = std.file;
import std.path;
import std.string;

class SideloadApplication: Application {
    SideloadWindow window;
    public __gshared ADI* adi;

    this() {
        super("dadoum.sideloader", ApplicationFlags.NON_UNIQUE);
        addOnActivate(&onActivate);
    }

    void onActivate(GApp app) {
        window = new SideloadWindow(this);
        iDevice.subscribeEvent((const(idevice_event_t)* event) {
            if (event.event == idevice_event_type.IDEVICE_DEVICE_ADD) {
                window.addDevice(cast(string) event.udid.fromStringz);
            } else if (event.event == idevice_event_type.IDEVICE_DEVICE_REMOVE) {
                window.removeDevice(cast(string) event.udid.fromStringz);
            }
        });

        auto deleteAppId = new SimpleAction("delete-app-id", null);
        deleteAppId.addOnActivate((_, __) {
            LoginAssistant assistant = new LoginAssistant(window);
            assistant.showAll();
        });
        this.addAction(deleteAppId);

        auto revokeCertAction = new SimpleAction("revoke-certificates", null);
        revokeCertAction.addOnActivate((_, __) {

        });
        this.addAction(revokeCertAction);

        auto debugAction = new SimpleAction("enable-debug", null, new Variant(true));
        this.addAction(debugAction);

        auto aboutAction = new SimpleAction("about", null);
        aboutAction.addOnActivate((_, __) {
            gtk_show_about_dialog(window.getWindowStruct(),
            "program-name".ptr, APPLICATION_NAME.ptr,
            "version".ptr, VERSION.ptr,
            "comments".ptr, "Sideload applications to Apple devices".ptr,
            "authors".ptr, (AUTHORS.map!((s) => s.ptr).array ~ null).ptr,
            "license-type".ptr, License.GPL_2_0_ONLY,
            null);
        });
        this.addAction(aboutAction);

        window.showAll();

        try {
            adi = new ADI(expandTilde("~/.adi/"));
        } catch (file.FileException) {
            auto dialog = new MessageDialog(window,
                DialogFlags.DESTROY_WITH_PARENT,
                MessageType.ERROR,
                ButtonsType.CLOSE,
                "ADI libraries are not correctly installed."
            );
            auto box = dialog.getContentArea();
            box.add(new LinkButton("https://github.com/Dadoum/Provision/tree/main/docs/en/sipa_setup.md", "Click here to see how to set-up SideloadIPA."));
            box.setSpacing(0);
            dialog.showAll();
            dialog.run();
            this.quit();
        }
    }
}

__gshared SideloadApplication appInstance;

int main(string[] args) {
    appInstance = new SideloadApplication();
    return appInstance.run(args);
}
