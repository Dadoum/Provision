module provision.c;

import core.runtime;
import core.stdc.string;
import provision.adi;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.string;

extern(C) __gshared {
    void provision_init() {
        Runtime.initialize();
    }

    void provision_dispose() {
        Runtime.terminate();
    }

    ADI* provision_adi_create(immutable char* path) {
        return Mallocator.instance.make!ADI(path.fromStringz);
    }

    ADI* provision_adi_create_with_identifier(immutable char* path, char* identifier) {
        return Mallocator.instance.make!ADI(path.fromStringz, identifier.fromStringz);
    }

    void provision_adi_dispose(ADI* handle) {
        Mallocator.instance.dispose(handle);
    }

    immutable(char)* provision_adi_get_client_info(ADI* handle) {
        return handle.clientInfo.toStringz;
    }

    void provision_adi_set_client_info(ADI* handle, immutable(char)* value) {
        handle.clientInfo = value.fromStringz;
    }

    immutable(char)* provision_adi_get_serial_no(ADI* handle) {
        return handle.serialNo.toStringz;
    }

    void provision_adi_set_serial_no(ADI* handle, immutable(char)* value) {
        handle.serialNo = value.fromStringz;
    }

    immutable(char)* provision_adi_get_provision_path(ADI* handle) {
        return handle.provisionPath.toStringz;
    }

    immutable(char)* provision_adi_get_device_id(ADI* handle) {
        return handle.deviceId.toStringz;
    }

    immutable(char)* provision_adi_get_local_user_uuid(ADI* handle) {
        return handle.localUserUUID.toStringz;
    }

    ulong provision_adi_provision_device(ADI* handle, ulong* routingInfo) {
        try {
            handle.provisionDevice(*routingInfo);
        } catch (Throwable t) {
            return t.toHash();
        }
        return 0;
    }

    ulong provision_adi_get_one_time_password(ADI* handle, ubyte** mid_arr, ulong* mid_length, ubyte** otp_arr, ulong* otp_length) {
        try {
            ubyte[] mid;
            ubyte[] otp;
            handle.getOneTimePassword(mid, otp);
            *mid_arr = mid.ptr;
            *mid_length = mid.length;
            *otp_arr = otp.ptr;
            *otp_length = otp.length;
        } catch (Throwable t) {
            return t.toHash();
        }
        return 0;
    }
}

