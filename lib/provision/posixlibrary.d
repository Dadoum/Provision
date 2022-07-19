module provision.posixlibrary;

import core.stdc.stdio;
import core.sys.posix.dlfcn;

class PosixLibrary {
    private void* libraryHandle;

    public this(char* libraryName) {
        libraryHandle = dlopen(libraryName, RTLD_LAZY);
        if (libraryHandle == null) {
            stderr.fprintf("ERR: cannot load library %s", libraryName);
        }
    }

    ~this() {
        if (libraryHandle !is null) {
            dlclose(libraryHandle);
        }
    }

    void* load(char* symbol) const {
        return dlsym(cast(void*) libraryHandle, symbol);
    }
}
