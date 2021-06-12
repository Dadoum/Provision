module provision.androidlibrary;

import core.sys.posix.dlfcn;
import std.conv;
import std.stdio;
import std.path;
import std.traits;
import std.string;
import core.exception;
import provision.utils.loghelper;
import core.sys.linux.elf;
import core.stdc.stdint;

extern (C)
{
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

extern (C++)
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

    alias uint8_t jboolean;
    alias int8_t jbyte;
    alias uint16_t jchar;
    alias int16_t jshort;
    alias int32_t jint;
    alias int64_t jlong;
    alias float jfloat;
    alias double jdouble;
    alias jint jsize;
}

enum LibraryType
{
	NATIVE_LINUX_LIBRARY,
	ANDROID_LIBRARY
}

class AndroidLibrary
{
    public static VM* vm;

    private bool redirectingToSystem = false;
    private void* libraryHandle;
    private string libraryName;

    private static void*[AndroidLibrary] systemLibraries;
    private static void*[string] globalHooks;

    extern (C) private static void* hookFinder(immutable(char)* s, immutable(char)* l)
    {
        foreach (library; AndroidLibrary.systemLibraries)
        {
            auto sym = dlsym(library, s);
            if (sym != null)
            {
                return sym;
            }
        }

        string symbol = fromStringz(s);
        return globalHooks.get(symbol, null);
    }

    static this()
    {
        vm = vm_init();
        hybris_set_hook_callback(&hookFinder);
        hybris_set_skip_props(true);
    }

    public this(string libraryName, LibraryType type = LibraryType.ANDROID_LIBRARY)
    {
        if (type == LibraryType.NATIVE_LINUX_LIBRARY)
        {
            this.libraryName = baseName(libraryName);
            log!(string)("Chargement de %s depuis le système... ", this.libraryName, LogPriority.verbeux);
            import provision.glue;

            auto systemLibrary = dlopen(toStringz(libraryName), RTLD_LAZY);
            if (systemLibrary == null)
            {
                throw new LibraryLoadException(to!string(dlerror()));
            }
            AndroidLibrary.systemLibraries[this] = systemLibrary;
            redirectingToSystem = true;
            
            logln!()("succès !", LogPriority.verbeux);
        }
        else if (type == LibraryType.ANDROID_LIBRARY)
        {
            this.libraryName = baseName(libraryName);
            log!string("Chargement de %s... ", this.libraryName, LogPriority.verbeux);
            libraryHandle = hybris_dlopen(toStringz(libraryName), RTLD_LAZY);
            if (libraryHandle == null)
            {
                throw new LibraryLoadException(to!string(hybris_dlerror()));
            }

            try
            {
                auto JNI_OnLoadFunction = loadSymbol!(jint function(JavaVM*, void*))("JNI_OnLoad");
                log!()("invocation du JNI_OnLoad()... ", LogPriority.verbeux);
                JNI_OnLoadFunction(vm_get_java_vm(vm), cast(void*) null);
            }
            catch (Exception e)
            {
            }

            logln!()("succès !", LogPriority.verbeux);
        }
        else
        {
        	throw new LibraryLoadException("Type de bibliothèque inconnu");
        }
    }

    ~this()
    {
        hybris_dlclose(libraryHandle);
        if (redirectingToSystem)
        {
            redirectingToSystem = false;
            if (AndroidLibrary.systemLibraries[this] != null)
                dlclose(AndroidLibrary.systemLibraries[this]);
        }
    }

    alias ExternC(T, string linkage = "C") = SetFunctionAttributes!(T, linkage,
            functionAttributes!T);
    ExternC!(T, linkage) loadSymbol(T, string linkage = "C")(string symbol) const
    {
        auto sym = hybris_dlsym(libraryHandle, toStringz(symbol));
        if (sym == null)
        {
            throw new LibraryLoadException(
                    "Symbole \"" ~ symbol ~ "\" introuvable: " ~ to!string(hybris_dlerror()));
        }
        return cast(typeof(return)) sym;
    }

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

class NotImplementedException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}
