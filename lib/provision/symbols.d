module provision.symbols;

import core.stdc.errno;
import core.stdc.stdlib;
import core.stdc.string;
import core.sys.posix.fcntl;
import core.sys.posix.sys.stat;
import core.sys.posix.sys.time;
import core.sys.posix.unistd;
import provision.androidlibrary;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.random;
import std.stdio : stderr, writeln;
import std.string;
import std.traits : Parameters, ReturnType;

__gshared:

private extern (C) int __system_property_get_impl(const char* n, char* value) {
    auto name = n.fromStringz;

    enum str = "no s/n number";

    value[0 .. str.length] = str;
    return cast(int) str.length;
}

private extern (C) uint arc4random_impl() {
    return Random(unpredictableSeed()).front;
}

private extern (C) int emptyStub() {
    return 0;
}

private extern (C) noreturn undefinedSymbol() {
    throw new UndefinedSymbolException();
}

private extern (C) AndroidLibrary* dlopenWrapper(const char* name) {
    stderr.writeln("Attempting to load ", name.fromStringz());
    try {
        return Mallocator.instance.make!AndroidLibrary(cast(string) name.fromStringz());
    } catch (Throwable) {
        return null;
    }
}

private extern (C) void* dlsymWrapper(AndroidLibrary* library, const char* symbolName) {
    stderr.writeln("Attempting to load ", symbolName.fromStringz());
    return library.load(cast(string) symbolName.fromStringz());
}

private extern (C) void dlcloseWrapper(AndroidLibrary* library) {
    return Mallocator.instance.dispose(library);
}

public bool doTimeTravel = false;
public timeval targetTime;

private extern (C) ReturnType!gettimeofday gettimeofday_timeTravel(timeval* timeval, void* ptr) {
    auto ret = gettimeofday(timeval, ptr);
    if (doTimeTravel) {
        *timeval = targetTime;
    }

    return ret;
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
            {"__errno", &errno}, {""}, {"pthread_rwlock_init", &emptyStub},
            {"pthread_mutex_unlock", &emptyStub},
            {"pthread_rwlock_rdlock", &emptyStub}, {
                "gettimeofday",
                &gettimeofday_timeTravel
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
    return &undefinedSymbol;
}
