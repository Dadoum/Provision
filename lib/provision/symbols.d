module provision.symbols;

import core.memory;
import provision.androidlibrary;
import std.algorithm.mutation;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.random;
import std.string;
import std.traits : Parameters, ReturnType;

import slf4d;

import provision.compat.general;
import provision.compat.windows;
import provision.compat.macos;
import provision.compat.linux;

__gshared:

private @sysv extern (C) int __system_property_get_impl(const char* n, char* value) {
    auto name = n.fromStringz;

    enum str = "no s/n number";

    value[0 .. str.length] = str;
    return cast(int) str.length;
}

private @sysv extern (C) uint arc4random_impl() {
    return Random(unpredictableSeed()).front;
}

private @sysv extern (C) int emptyStub() {
    return 0;
}

version (StubMaps) {
    package @sysv noreturn undefinedSymbol(immutable char* symbol) {
        throw new UndefinedSymbolException(symbol.fromStringz());
    }
} else {
    package @sysv noreturn undefinedSymbol() {
        throw new UndefinedSymbolException("(unknown)".fromStringz());
    }
}

private @sysv extern (C) AndroidLibrary dlopenWrapper(const char* name) {
    debug {
        getLogger().traceF!"Attempting to load %s"(name.fromStringz());
    }
    try {
        auto caller = rootLibrary();
        AndroidLibrary lib;
        if (caller) {
            lib = new AndroidLibrary(cast(string) name.fromStringz(), caller.hooks);
            caller.loadedLibraries ~= lib;
        } else {
            lib = new AndroidLibrary(cast(string) name.fromStringz());
        }
        return lib;
    } catch (Exception ex) {
        getLogger().debugF!"Library loading failed! %s. Returning null."(ex);
        return null;
    }
}

private @sysv extern (C) void* dlsymWrapper(AndroidLibrary library, const char* symbolName) {
    debug {
        getLogger().traceF!"Attempting to load symbol %s"(symbolName.fromStringz());
    }
    return library.load(cast(string) symbolName.fromStringz());
}

private @sysv extern (C) void dlcloseWrapper(AndroidLibrary library) {
    if (library) {
        auto caller = rootLibrary();
        if (caller) {
            rootLibrary().loadedLibraries.remove!((lib) => lib == library);
        }
        destroy(library);
    }
}

// gperf generated code:

private enum totalKeywords = 29;
private enum minWordLength = 4;
private enum maxWordLength = 22;
private enum minHashValue = 4;
private enum maxHashValue = 45;
/* maximum key range = 42, duplicates = 0 */

pragma(inline, true) private uint hash(string str, uint len) {
    static ubyte[] asso_values = [
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 10, 46, 25, 46, 3, 0, 20, 10,
        0, 5, 10, 46, 25, 0, 5, 10, 0, 0, 46, 10, 10, 0, 0, 46, 5, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
        46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46
    ];
    uint hval = len;

    switch (hval) {
    default:
        hval += asso_values[cast(ubyte) str[15]];
        goto case;
    case 15:
    case 14:
    case 13:
    case 12:
    case 11:
    case 10:
    case 9:
    case 8:
    case 7:
    case 6:
    case 5:
    case 4:
    case 3:
    case 2:
        hval += asso_values[cast(ubyte) str[1]];
        goto case;
    case 1:
        hval += asso_values[cast(ubyte) str[0]];
        break;
    }
    return hval;
}

private struct FunctionPair {
    string name;
    void* ptr;
}

package void* lookupSymbol(string str) {
    auto len = cast(uint) str.length;
    enum FunctionPair[] wordlist = [
            {""}, {""}, {""}, {""}, {"open", &open}, {"dlsym", &dlsymWrapper},
            {"dlopen", &dlopenWrapper}, {"dlclose", &dlcloseWrapper},
            {"close", &close}, {""}, {"umask", &umask}, {""},
            {"pthread_once", &emptyStub}, {"chmod", &chmod},
            {"pthread_create", &emptyStub}, {"lstat", &lstat}, {""},
            {"strncpy", &strncpy}, {"pthread_mutex_lock", &emptyStub},
            {"ftruncate", &ftruncate}, {"write", &write},
            {"pthread_rwlock_unlock", &emptyStub},
            {"pthread_rwlock_destroy", &emptyStub}, {""}, {"free", &free},
            {"fstat", &fstat}, {"pthread_rwlock_wrlock", &emptyStub},
            {"__errno", &__errno_location}, {""}, {"pthread_rwlock_init", &emptyStub},
            {"pthread_mutex_unlock", &emptyStub},
            {"pthread_rwlock_rdlock", &emptyStub}, {
                "gettimeofday",
                &gettimeofday
            }, {""}, {"read", &read},
            {"mkdir", &mkdir}, {"malloc", &malloc}, {""}, {""}, {""}, {""},
            {"__system_property_get", &__system_property_get_impl}, {""}, {""},
            {""}, {"arc4random", &arc4random_impl},
        ];

    if (len <= maxWordLength && len >= minWordLength) {
        uint key = hash(str, len);

        if (key <= maxHashValue) {
            string s = wordlist[key].name;

            if (str == s)
                return wordlist[key].ptr;
        }
    }
    return null;
}
