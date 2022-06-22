module sideloadipa.loginassistant;

import gtk.Assistant;
import gtk.Box;
import gtk.Window;

class LoginAssistant: Assistant {
    this(Window parent) {
        // this.setParent(parent);
        this.setResizable(false);

        this.addOnCancel((_) {
            this.destroy();
        });

        Box firstPage = new Box(Orientation.VERTICAL, 4);
        this.appendPage(firstPage);
    }
}
