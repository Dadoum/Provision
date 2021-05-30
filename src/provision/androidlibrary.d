module provision.androidlibrary;

import core.sys.posix.dlfcn;
import std.conv;
import std.stdio;
import std.path;
import std.traits;
import std.string;
import core.exception;
import provision.utils.loghelper;

extern (C)
{
    void* hybris_dlopen(immutable(char)* path, int flag);
    void hybris_dlclose(void* handle);
    void* hybris_dlsym(const(void*) handle, immutable(char)* symbol);
    immutable(char)* hybris_dlerror();
    void hybris_set_hook_callback(void* function(immutable(char)* symbol_name,
            immutable(char)* requester));
}

extern (C++,jnivm)
{
    class _jobject
    {
    };
    class _jclass
    {
    };
    class _jstring
    {
    };
    class _jarray
    {
    };
    class _jobjectArray
    {
    };
    class _jbooleanArray
    {
    };
    class _jbyteArray
    {
    };
    class _jcharArray
    {
    };
    class _jshortArray
    {
    };
    class _jintArray
    {
    };
    class _jlongArray
    {
    };
    class _jfloatArray
    {
    };
    class _jdoubleArray
    {
    };
    class _jthrowable
    {
    };
    alias _jobject* jobject;
    alias _jclass* jclass;
    alias _jstring* jstring;
    alias _jarray* jarray;
    alias _jobjectArray* jobjectArray;
    alias _jbooleanArray* jbooleanArray;
    alias _jbyteArray* jbyteArray;
    alias _jcharArray* jcharArray;
    alias _jshortArray* jshortArray;
    alias _jintArray* jintArray;
    alias _jlongArray* jlongArray;
    alias _jfloatArray* jfloatArray;
    alias _jdoubleArray* jdoubleArray;
    alias _jthrowable* jthrowable;
    alias _jobject* jweak;

    struct JNIEnv;
    class VM
    {
        void* GetJavaVM();
        JNIEnv* GetJNIEnv();
    }
}

class AndroidLibrary
{
    public static VM vm;

    private bool redirectingToSystem = false;
    private void* systemLibrary;
    private void* libraryHandle;
    private string libraryName;

    private static void*[string] globalHooks;
    private static void* delegate(string symbol)[string] hookFinderFunctionForLibrary;

    extern (C) private static void* hookFinder(immutable(char)* s, immutable(char)* l)
    {
        string symbol = fromStringz(s);
        string library = baseName(fromStringz(l));

        auto hookFinderFunc = hookFinderFunctionForLibrary.get(library, null);
        if (hookFinderFunc != null)
        {
            auto foundHook = hookFinderFunc(symbol);
            if (foundHook != null)
            {
                return foundHook;
            }
        }

        return globalHooks.get(symbol, null);
    }

    static this()
    {
        vm = new VM();
        hybris_set_hook_callback(&hookFinder);
    }

    private void* findHook(string symbol)
    {
        if (redirectingToSystem)
        {
            auto sym = dlsym(systemLibrary, toStringz(symbol));
            return sym;
        }
        return null;
    }

    public this(string libraryName, bool searchForJNI_OnLoad = true)
    {
        this.libraryName = baseName(libraryName);
        log("Chargement de %s... ", this.libraryName);
        hookFinderFunctionForLibrary[this.libraryName] = &findHook;
        libraryHandle = hybris_dlopen(toStringz(libraryName), RTLD_NOW);
        if (libraryHandle == null)
        {
            throw new LibraryLoadException(to!string(hybris_dlerror()));
        }

        if (searchForJNI_OnLoad)
        {
            try
            {
                auto JNI_OnLoad = loadSymbol!(int function(void*, int))("JNI_OnLoad");
                log("invocation du JNI_OnLoad()... ");
                version (LDC)
                {
                    auto backup = stdout;
                    stdout = cast(File) null; // paliatif pour un bug incompréhensible de ldc
                }
                JNI_OnLoad(vm.GetJavaVM(), 0);
                version (LDC)
                {
                    stdout = backup;
                }
            }
            catch (Exception)
            {
            }
        }
        stdout.flush();
        logln("succès !");
    }

    public this(string libraryName, string redirectSymbolsTo, bool searchForJNI_OnLoad = true)
    {
        systemLibrary = dlopen(toStringz(redirectSymbolsTo), RTLD_NOW);
        if (systemLibrary == null)
        {
            throw new LibraryLoadException(to!string(dlerror()));
        }
        redirectingToSystem = true;
        this(libraryName);
    }

    ~this()
    {
        hookFinderFunctionForLibrary.remove(libraryName);
        hybris_dlclose(libraryHandle);
        if (redirectingToSystem)
        {
            redirectingToSystem = false;
            if (systemLibrary != null)
                dlclose(systemLibrary);
        }
    }

    T loadSymbol(T)(string symbol) const
    {
        auto sym = hybris_dlsym(libraryHandle, toStringz(symbol));
        if (sym == null)
        {
            throw new LibraryLoadException("Symbole \"" ~ symbol ~ "\" introuvable: " ~ to!string(hybris_dlerror()));
        }
        return cast(T) sym;
    }

    alias ExternC(T) = SetFunctionAttributes!(T, "C", functionAttributes!T);
    public static void addGlobalHook(T)(string symbol, T replacement)
            if (isCallable!T)
    {
        globalHooks[symbol] = cast(ExternC!T) replacement;
    }
}

class LibraryLoadException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}
