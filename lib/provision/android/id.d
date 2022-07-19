module provision.android.id;

import core.stdc.stdio;
import core.stdc.stdint;
import core.sys.posix.dlfcn;

union sd_id128_t {
    uint8_t[16] bytes;
    uint64_t[2] qwords;
}

sd_id128_t* make_id(int b0, int b1, int b2, int b3, int b4, int b5, int b6, int b7,
int b8, int b9, int b10, int b11, int b12, int b13, int b14, int b15) {
    return make_id([
    cast(byte) b0, cast(byte) b1, cast(byte) b2, cast(byte) b3,
    cast(byte) b4, cast(byte) b5, cast(byte) b6, cast(byte) b7,
    cast(byte) b8, cast(byte) b9, cast(byte) b10, cast(byte) b11,
    cast(byte) b12, cast(byte) b13, cast(byte) b14, cast(byte) b15
    ]);
}

sd_id128_t* make_id(byte[16] b) {
    auto id = New!sd_id128_t();
    id.bytes[0] = b[0];
    id.bytes[1] = b[1];
    id.bytes[2] = b[2];
    id.bytes[3] = b[3];
    id.bytes[4] = b[4];
    id.bytes[5] = b[5];
    id.bytes[6] = b[6];
    id.bytes[7] = b[7];
    id.bytes[8] = b[8];
    id.bytes[9] = b[9];
    id.bytes[10] = b[10];
    id.bytes[11] = b[11];
    id.bytes[12] = b[12];
    id.bytes[13] = b[13];
    id.bytes[14] = b[14];
    id.bytes[15] = b[15];
    return id;
}

string toString(sd_id128_t* id) {
    char* outStr;
    sprintf(outStr, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        id.bytes[0], id.bytes[1], id.bytes[2], id.bytes[3], id.bytes[4],
        id.bytes[5], id.bytes[6], id.bytes[7], id.bytes[8], id.bytes[9],
        id.bytes[10], id.bytes[11], id.bytes[12], id.bytes[13], id.bytes[14], id.bytes[15]);
    return cast(string) outStr[0..32];
}

string genAndroidId() {
    auto libsystemd = dlopen("libsystemd.so", RTLD_LAZY);
    if (libsystemd) {
        scope(exit) dlclose(libsystemd);

        scope sd_id128_t* appId = make_id(0x8b, 0x06, 0x7f, 0xdd, 0x3c, 0xbf, 0x40,
        0x8c, 0x90, 0x64, 0xc7, 0x5a, 0x9a, 0xc4, 0xc7, 0x8b), machineId = New!sd_id128_t();

        alias sd_id128_get_machine_app_specific_t = extern(C) int function(sd_id128_t app_id, sd_id128_t* ret);
        sd_id128_get_machine_app_specific_t sd_id128_get_machine_app_specific =
        cast(sd_id128_get_machine_app_specific_t) dlsym(libsystemd, "sd_id128_get_machine_app_specific");
        if (!sd_id128_get_machine_app_specific) {
            goto error;
        }

        if (sd_id128_get_machine_app_specific(*appId, machineId) != 0) {
            goto error;
        }

        return machineId.toString()[0 .. 16];
    }

  error:
    stderr.fprintf("WARN: Generation of unique identifier failed, using a generic one instead. \n");
    return "9774d56d682e549c";
}
