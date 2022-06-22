module sideloadipa.sideloadwindow;

import gio.Menu;

import gtk.Application;
import gtk.ApplicationWindow;
import gtk.Box;
import gtk.Button;
import gtk.ComboBox;
import gtk.CellRendererText;
import gtk.Entry;
import gtk.FileChooserButton;
import gtk.FileFilter;
import gtk.HeaderBar;
import gtk.ListStore;
import gtk.MenuButton;
import gtk.SeparatorMenuItem;
import gtk.TreeIter;

import sideloadipa.identity;
import sideloadipa.imobiledevice;

import std.format;
import std.typecons;

class SideloadWindow: ApplicationWindow {
    HeaderBar bar;
    MenuButton hamburgerButton;

    ComboBox deviceComboBox;
    ListStore deviceListModel;

    FileChooserButton selectIpaButton;
    Button startButton;

    TreeIter[string] devicesIter;

    this(Application app) {
        super(app);
        this.setTitle(APPLICATION_NAME);
        this.setResizable(false);
        this.setSizeRequest(480, 0);

        bar = new HeaderBar();
        bar.setShowCloseButton(true);
        bar.setTitle(APPLICATION_NAME);

        hamburgerButton = new MenuButton();
        hamburgerButton.setProperty("direction", ArrowType.NONE);

        Menu menu = new Menu();
        Menu appleActions = new Menu();
        appleActions.append("Delete App ID", "app.delete-app-id");
        appleActions.append("Revoke certificates", "app.revoke-certificates");
        menu.appendSection(null, appleActions);
        Menu appActions = new Menu();
        appActions.append("About " ~ APPLICATION_NAME, "app.about");
        menu.appendSection(null, appActions);

        hamburgerButton.setMenuModel(menu);

        bar.packEnd(hamburgerButton);
        this.setTitlebar(bar);

        Box mainBox = new Box(Orientation.VERTICAL, 4);
        mainBox.setProperty("margin", 6);

        deviceComboBox = new ComboBox(false);
        deviceListModel = new ListStore([GType.STRING, GType.STRING]);
        deviceComboBox.setModel(deviceListModel);
        deviceComboBox.setIdColumn(0);
        auto textRenderer = new CellRendererText();
        deviceComboBox.packStart(textRenderer, true);
        deviceComboBox.addAttribute(textRenderer, "text", 0);
        mainBox.add(deviceComboBox);

        Box box = new Box(Orientation.HORIZONTAL, 4);
        box.setProperty("expand", true);

        selectIpaButton = new FileChooserButton("Select IPA", FileChooserAction.OPEN);
        selectIpaButton.setProperty("expand", true);
        selectIpaButton.addOnFileSet((FileChooserButton) => checkStartButton());
        auto ipaFileFilter = new FileFilter();
        ipaFileFilter.addPattern("*.ipa");
        ipaFileFilter.setName("iOS App Store Package (*.ipa)");
        selectIpaButton.addFilter(ipaFileFilter);
        box.add(selectIpaButton);

        startButton = new Button("Start");
        startButton.setSensitive(false);
        box.add(startButton);

        mainBox.add(box);

        this.add(mainBox);
    }

    void checkStartButton() {
        startButton.setSensitive(deviceComboBox.getActive() != -1 && selectIpaButton.getFile() !is null);
    }

    void remakeDeviceComboBox() {
        deviceListModel.clear();
        auto deviceList = iDevice.deviceList;
        foreach (device; deviceList) {
            addDevice(device);
        }

        if (deviceList.length) {
            deviceComboBox.setActive(0);
        }

        checkStartButton();
    }

    void addDevice(string udid) {
        assert(udid !in devicesIter);

        TreeIter iter = null;
        deviceListModel.append(iter);

        devicesIter[udid] = iter;

        auto idevice = scoped!iDevice(udid);
        auto lockdowndClient = scoped!LockdowndClient(idevice, "sideload_ipa");
        string deviceName = lockdowndClient.deviceName;
        string name;
        if (deviceName != "")
            name = format!"%s (%s)"(deviceName, udid);
        else
            name = udid;
        deviceListModel.setValue(iter, 0, name);
        deviceListModel.setValue(iter, 1, udid);

        if (deviceListModel.iterNChildren(null) == 1) {
            deviceComboBox.setActive(0);
            checkStartButton();
        }
    }

    void removeDevice(string udid) {
        deviceListModel.remove(devicesIter[udid]);
        devicesIter.remove(udid);

        checkStartButton();
    }
}
