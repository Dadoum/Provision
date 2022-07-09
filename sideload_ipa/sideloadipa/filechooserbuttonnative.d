module sideloadipa.filechooserbuttonnative;

import pango.c.types;
import gtk.Box;
import gtk.Button;
import gtk.FileChooserNative;
import gtk.Image;
import gtk.Label;
import gtk.Window;

class FileChooserButtonNative: Button {
    void delegate(FileChooserButtonNative)[] fileSetHandlers;
    Label fileNameLabel;
    FileChooserNative fileDialog;

    this() {
        auto topLevel = cast(Window) this.getToplevel();
        this.setHexpand(false);
        fileDialog = new FileChooserNative("Select IPA", topLevel, FileChooserAction.OPEN, "Open", "Cancel");
        auto boxInsideButton = new Box(Orientation.HORIZONTAL, 8);
        boxInsideButton.setHexpand(false);
        fileNameLabel = new Label("Select an IPA file...");
        fileNameLabel.setHexpand(false);
        fileNameLabel.setEllipsize(PangoEllipsizeMode.MIDDLE);
        // fileNameLabel.setProperty("expand", true);
        fileNameLabel.setHalign(Align.START);
        fileNameLabel.setProperty("ellipsize", PangoEllipsizeMode.MIDDLE);
        boxInsideButton.packStart(fileNameLabel, false, false, 0);
        auto image = new Image("folder-open-symbolic", IconSize.BUTTON);
        image.setHalign(Align.END);
        boxInsideButton.packEnd(image, false, false, 0);
        add(boxInsideButton);
        addOnPressed(&pressed);
    }

    void pressed(Button) {
        fileDialog.setTransientFor(cast(Window) this.getToplevel());
        ResponseType result = cast(ResponseType) fileDialog.run();
        if (result == ResponseType.ACCEPT) {
            fileNameLabel.setText(fileDialog.getFile().getPath());
            foreach (dlg; fileSetHandlers) {
                dlg(this);
            }
        }
    }

    void addOnFileSet(void delegate(FileChooserButtonNative) dlg) {
        fileSetHandlers ~= dlg;
    }

    alias fileDialog this;
}
