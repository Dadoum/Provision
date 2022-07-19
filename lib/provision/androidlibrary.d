module provision.androidlibrary;

import core.stdc.stdio;
import core.stdc.string;
import core.sys.posix.dlfcn;
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

public struct AndroidLibrary {
    private void* libraryHandle;

    public this(immutable(char)* libraryName) {
        libraryHandle = hybris_dlopen(libraryName, RTLD_LAZY);
        if (libraryHandle == null) {
            stderr.fprintf("ERR: cannot load library %s", libraryName);
        }
    }

    ~this() {
        if (libraryHandle !is null) {
            hybris_dlclose(libraryHandle);
        }
    }

    void* load(immutable(char)* symbol) const {
        void* sym = hybris_dlsym(libraryHandle, symbol);
        if (sym == null) {
            immutable(char)* hybris_err = hybris_dlerror();
            stderr.fprintf("ERR: cannot load symbol %s: %s", symbol, hybris_err);
        }
        return sym;
    }
}

private static __gshared PosixLibrary libc;

extern(C) int __system_property_getHook(const char* n, char *value) {
    enum str = "no s/n number";

    strncpy(value, str.ptr, str.length);
    return cast(int) str.length;
}

extern(C) uint arc4randomHook() {
    // import std.random;
    return 0; // Random(unpredictableSeed()).front;
}

extern(C) int emptyStub() {
    return 0;
}

struct ADIMessage {
    void** inputPointer;
    uint inputSize;
    void** outputPointer;
    uint outputSize;
    ulong flags;
}

// alias vdfut_t = extern(C) int function(Parameters!vdfut768igHook);
// extern(C) static __gshared vdfut_t vdef;
//
// extern(C) int vdfut768igHook(int functionIdentifier, ADIMessage* message) {
//     // writefln!"%x"(functionIdentifier);
//     return vdef(__traits(parameters));
// }

extern(C) void* hookable_dlsym(void *handle, immutable char *s) {
    // if (strcmp(s, "vdfut768ig".ptr) == 0) {
    //     vdef = cast(vdfut_t) hybris_dlsym(handle, s);
    //     return &vdfut768igHook;
    // }

    return hybris_dlsym(handle, s);
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
        return &hookable_dlsym;

    if (strcmp(s, "__system_property_get".ptr) == 0)
        return &__system_property_getHook;

    if (strcmp(s, "arc4random".ptr) == 0)
        return &arc4randomHook;

    // Hooks to load libandroidappmusic
    // if (strcmp(s, "powf".ptr) == 0 ||
    //     strcmp(s, "sqrtf".ptr) == 0 ||
    //     strcmp(s, "cos".ptr) == 0 ||
    //     strcmp(s, "sin".ptr) == 0 ||
    //     strcmp(s, "log10f".ptr) == 0 ||
    //     strcmp(s, "atan2f".ptr) == 0 ||
    //     strcmp(s, "sqrt".ptr) == 0 ||
    //     strcmp(s, "pow".ptr) == 0 ||
    //     strcmp(s, "log".ptr) == 0 ||
    //     strcmp(s, "roundf".ptr) == 0 ||
    //     strcmp(s, "exp".ptr) == 0 ||
    //     strcmp(s, "lroundf".ptr) == 0)
    //     return &emptyStub;

    return libc.load(cast(char*) s);
}

private static __gshared size_t refCount = 0;

void initHybris() {
    if (!refCount) {
        libc = New!PosixLibrary(null);
        hybris_set_skip_props(true);
        hybris_set_hook_callback(&hookFinder);
    }
    refCount++;
}

void unloadHybris() {
    refCount--;
    if (!refCount) {
        libc.destroy();
    }
}
