module sideloadipa.imobiledevice;

public import sideloadipa.imobiledevice.libimobiledevice;
public import sideloadipa.imobiledevice.lockdown;
import std.array;
import std.algorithm.iteration;
import std.format;
import std.string;
import std.traits;

class iDeviceException(T): Exception {
    this(T error, string file = __FILE__, int line = __LINE__) {
        super(format!"error %s"(error), file, line);
    }
}

void assertSuccess(alias U)(Parameters!U u) if (is(ReturnType!U == idevice_error_t)) {
    auto error = U(u);
    if (error != 0)
        throw new iDeviceException!(typeof(error))(error);
}

public class iDevice {
    alias iDeviceEventCallback = void delegate(const(idevice_event_t)* event);

    idevice_t handle;

    public static void subscribeEvent(iDeviceEventCallback callback) {
        struct UserData {
            iDeviceEventCallback callback;
        }

        extern(C) void func(const(idevice_event_t)* event, void* user_data) {
            auto del = cast(UserData*) user_data;
            del.callback(event);
        }

        assertSuccess!idevice_event_subscribe(&func, new UserData(callback));
    }

    public static @property string[] deviceList() {
        int len;
        idevice_info_t* names;
        idevice_get_device_list_extended(&names, &len);
        return names[0..len].map!((s) => cast(string) s.udid.fromStringz).array;
    }

    public this(string udid) {
        idevice_new_with_options(&handle, udid.toStringz, idevice_options.IDEVICE_LOOKUP_USBMUX | idevice_options.IDEVICE_LOOKUP_NETWORK);
    }

    ~this() {
        idevice_free(handle);
    }
}

public class LockdowndClient {
    lockdownd_client_t handle;

    public this(iDevice device, string serviceName) {
        lockdownd_client_new_with_handshake(device.handle, &handle, cast(const(char)*) serviceName.toStringz);
    }

    public @property string deviceName() {
        char* name;
        lockdownd_get_device_name(handle, &name);
        return cast(string) name.fromStringz;
    }

    ~this() {
        lockdownd_client_free(handle);
    }
}
