module provision.androidlibrary;

version (linux):

import core.stdc.string;
import core.sys.posix.dlfcn;
import std.algorithm;
import std.conv;
import std.stdio;
import std.path;
import std.traits;
import std.algorithm;
import std.string;
import core.exception;
import core.stdc.stdint;
import provision.ilibrary;
import provision.posixlibrary;

extern (C) __gshared @nogc {
    int hybris_dladdr(const void *addr, void *info);
    void* hybris_dlopen(immutable(char)* path, int flag);
    void hybris_dlclose(void* handle);
    void* hybris_dlsym(const void* handle, immutable(char)* symbol);
    immutable(char)* hybris_dlerror();
    void hybris_set_hook_callback(void* function(immutable(char)* symbol_name,
            immutable(char)* requester));
    void hybris_set_skip_props(bool value);
}

public class AndroidLibrary: ILibrary {
    private void* libraryHandle;

    public this(string libraryName) {
        libraryHandle = hybris_dlopen(libraryName.ptr, RTLD_LAZY);
        if (libraryHandle == null) {
            stderr.writefln!"ERR: cannot load library %s"(libraryName);
        }
    }

    ~this() {
        if (libraryHandle !is null) {
            hybris_dlclose(libraryHandle);
        }
    }

    void* load(string symbol) const {
        void* sym = hybris_dlsym(libraryHandle, toStringz(symbol));
        if (sym == null) {
            string hybris_err = hybris_dlerror().fromStringz();
            stderr.writefln!"ERR: cannot load symbol %s: %s"(symbol, hybris_err);
        }
        return sym;
    }
}

private static __gshared PosixLibrary libc;

extern(C) int __system_property_getHook(const char* n, char *value) {
    auto name = n.fromStringz;

    enum str = "0 c'est trop court apparement";

    strcpy(value, str.ptr);
    return cast(int) str.length;
}

extern(C) int emptyStub() {
    return 0;
}

extern(C) private static void* hookFinder(immutable(char)* s, immutable(char)* l) {
    import core.stdc.errno;

    if (strcmp(s, "__errno".ptr) == 0)
        return &errno;

    if (strcmp(s, "dladdr".ptr) == 0)
        return &hybris_dladdr;

    if (strcmp(s, "dlclose".ptr) == 0)
        return &hybris_dlclose;

    if (strcmp(s, "dlerror".ptr) == 0)
        return &hybris_dlerror;

    if (strcmp(s, "dlopen".ptr) == 0)
        return &hybris_dlopen;

    if (strcmp(s, "dlsym".ptr) == 0)
        return &hybris_dlsym;

    if (strcmp(s, "__system_property_get".ptr) == 0)
        return &__system_property_getHook;

    if (strcmp(s, "arc4random".ptr) == 0)
        return &emptyStub;

    return libc.load(s.fromStringz);
}

uint count = 0;
void initHybris() {
    count++;
    if (count == 1) {
        libc = new PosixLibrary("libc.so.6");
        hybris_set_skip_props(true);
        hybris_set_hook_callback(&hookFinder);
    }
}

void unloadHybris() {
    count--;
    if (count == 0) {
        destroy(libc);
    }
}
