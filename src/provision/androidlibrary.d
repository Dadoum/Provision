module provision.androidlibrary;

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
import core.sys.linux.elf;
import core.stdc.stdint;

extern (C) __gshared @nogc {
    void* hybris_dlopen(immutable(char)* path, int flag);
    void hybris_dlclose(void* handle);
    void* hybris_dlsym(const void* handle, immutable(char)* symbol);
    immutable(char)* hybris_dlerror();
    void hybris_set_hook_callback(void* function(immutable(char)* symbol_name,
            immutable(char)* requester));
    void hybris_set_skip_props(bool value);
}

public struct AndroidLibrary {
    private void* libraryHandle;

    public this(string libraryName, string[] hooks = null) {
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

private static __gshared void* libc;

extern (C) private static void* hookFinder(immutable(char)* s, immutable(char)* l) {

    if (strcmp(s, "dladdr".ptr) == 0 ||
        strcmp(s, "dlclose".ptr) == 0 ||
        strcmp(s, "dlerror".ptr) == 0 ||
        strcmp(s, "dlopen".ptr) == 0 ||
        strcmp(s, "dlsym".ptr) == 0 ||
        strcmp(s, "fflush".ptr) == 0)
        return null;

    return dlsym(libc, s);
}

void initHybris() {
    libc = dlopen("libc.so.6", RTLD_LAZY);
    hybris_set_skip_props(true);
    hybris_set_hook_callback(&hookFinder);
}

void unloadHybris() {
    dlclose(libc);
}
