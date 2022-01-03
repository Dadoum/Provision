module provision.androidlibrary;

import core.sys.posix.dlfcn;
import std.algorithm;
import std.conv;
import std.stdio;
import std.path;
import std.traits;
import std.algorithm;
import std.string;
import core.exception;
import provision.utils.loghelper;
import core.sys.linux.elf;
import core.stdc.stdint;

extern (C) {
    void* hybris_dlopen(immutable(char)* path, int flag);
    void hybris_dlclose(void* handle);
    void* hybris_dlsym(const(void*) handle, immutable(char)* symbol);
    immutable(char)* hybris_dlerror();
    void hybris_set_hook_callback(void* function(immutable(char)* symbol_name,
            immutable(char)* requester));
    void hybris_set_skip_props(bool value);

    struct VM;
    struct JavaVM;

    VM* vm_init();

    JavaVM* vm_get_java_vm(VM* vm);

    void destroy(VM* vm);
}

enum LibraryType {
    NATIVE_LINUX_LIBRARY,
    ANDROID_LIBRARY
}

class AndroidLibrary {
    public static VM* vm;

    public const(string) libraryFileName;

    private static AndroidLibrary[] systemLibraries;
    private static void*[string] globalHooks;

    private bool redirectingToSystem = false;
    private void* libraryHandle;

    extern (C) private static void* hookFinder(immutable(char)* s, immutable(char)* l) {
        string symbol = fromStringz(s);
        string lib = fromStringz(l);
        auto hook = globalHooks.get(symbol, null);

        if (hook == null) {
            bool replaced = false;
            if (symbol.canFind("__ndk1")) {
                symbol = symbol.replace("St6__ndk1", "St3__1");
                replaced = true;
            }

            foreach (library; AndroidLibrary.systemLibraries) {
                auto sym = dlsym(library.libraryHandle, symbol.toStringz);
                if (sym != null) {
                    hook = sym;
                }
            }
        }

        return hook;
    }

    static this() {
        vm = vm_init();
        hybris_set_hook_callback(&hookFinder);
        hybris_set_skip_props(true);
    }

    public this(string libraryName, LibraryType type = LibraryType.ANDROID_LIBRARY) {
        if (libraryName == null)
            this.libraryFileName = "(executable)";
        else
            this.libraryFileName = baseName(libraryName).dup;

        if (type == LibraryType.NATIVE_LINUX_LIBRARY) {
            log!(string)("Chargement de %s depuis le système... ",
                    this.libraryFileName, LogPriority.verbeux);

            immutable(char)* lib;
            if (libraryName == null)
                lib = null;
            else
                lib = toStringz(libraryName);
            libraryHandle = dlopen(lib, RTLD_LAZY | RTLD_LOCAL);
            if (libraryHandle == null) {
                throw new LibraryLoadException(to!string(dlerror()));
            }
            AndroidLibrary.systemLibraries ~= this;
            redirectingToSystem = true;

            logln!()("succès !", LogPriority.verbeux);
        } else if (type == LibraryType.ANDROID_LIBRARY) {
            log!string("Chargement de %s... ", this.libraryFileName, LogPriority.verbeux);
            libraryHandle = hybris_dlopen(toStringz(libraryName), RTLD_LAZY);
            if (libraryHandle == null) {
                throw new LibraryLoadException(to!string(hybris_dlerror()));
            }

            try {
                auto JNI_OnLoadFunction = loadSymbol!(int32_t function(JavaVM*, void*))("JNI_OnLoad");
                log!()("invocation du JNI_OnLoad()... ", LogPriority.verbeux);
                JNI_OnLoadFunction(vm_get_java_vm(vm), cast(void*) null);
            } catch (Exception e) {
            }

            logln!()("succès !", LogPriority.verbeux);
        } else {
            throw new LibraryLoadException("Type de bibliothèque inconnu");
        }
    }

    ~this() {
        import core.thread.osthread;
        import core.time;

        if (libraryHandle !is null && !redirectingToSystem)
            hybris_dlclose(libraryHandle);

        if (redirectingToSystem) {
            redirectingToSystem = false;
            if (libraryHandle !is null)
                dlclose(libraryHandle);
        }
    }

    alias ExternC(T, string linkage = "C") = SetFunctionAttributes!(T, linkage,
            functionAttributes!T);
    auto loadSymbol(T, string linkage = "C")(string symbol) const {
        void* sym;
        if (redirectingToSystem) {
            sym = dlsym(cast(void*) libraryHandle, symbol.toStringz);
        } else {
            sym = hybris_dlsym(libraryHandle, toStringz(symbol));
        }
        if (sym == null) {
            string hybris_err;
            if (redirectingToSystem) {
                hybris_err = to!string(dlerror().fromStringz());
            } else {
                hybris_err = hybris_dlerror().fromStringz();
            }
            throw new LibraryLoadException(
            "Symbole \"" ~ symbol ~ "\" introuvable dans \"" ~ libraryFileName ~ "\": " ~ (hybris_err == "" ? "Erreur non renseignée" : hybris_err));
        }
        static if (isCallable!T){
            return cast(ExternC!(T, linkage)) sym;
        } else {
            return cast(T) sym;
        }
    }

    public static void addGlobalHook(T)(string symbol, T replacement)
            if (isCallable!T) {
        globalHooks[symbol] = cast(ExternC!T) replacement;
    }
}

class LibraryLoadException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class NotImplementedException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
