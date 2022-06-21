module provision.posixlibrary;

import core.sys.posix.dlfcn;
import provision.ilibrary;
import std.stdio;
import std.string;

class PosixLibrary: ILibrary {
    private void* libraryHandle;

    public this(string libraryName) {
        libraryHandle = dlopen(libraryName.ptr, RTLD_LAZY);
        if (libraryHandle == null) {
            stderr.writefln!"ERR: cannot load library %s"(libraryName);
        }
    }

    ~this() {
        if (libraryHandle !is null) {
            dlclose(libraryHandle);
        }
    }

    void* load(string symbol) const {
        return dlsym(cast(void*) libraryHandle, toStringz(symbol));
    }
}
