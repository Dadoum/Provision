module object;

public import core.internal.switch_ : __switch_error; //final switch

alias size_t = typeof(int.sizeof);
alias ptrdiff_t = typeof(cast(void*)0 - cast(void*)0);

alias sizediff_t = ptrdiff_t; // For backwards compatibility only.
alias noreturn = typeof(*null);  /// bottom type

alias hash_t = size_t; // For backwards compatibility only.
alias equals_t = bool; // For backwards compatibility only.

alias string  = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];

extern(C) bool _xopEquals(in void*, in void*) { return false; }
extern(C) int _xopCmp(in void*, in void*) { return 0; }

import core.stdc.stdlib;

public class Object {
    public void destroy() {
        free(cast(void*) this);
    }
}

template New(T) {
    static if (is(T == class)) {
        alias TypePtr = T;
        enum size = __traits(classInstanceSize, T);
    } else {
        alias TypePtr = T*;
        enum size = T.sizeof;
    }

    pragma(mangle, "_D" ~ T.mangleof[1..$] ~ "6__initZ")
    __gshared extern immutable ubyte[size] initializer;

    TypePtr New(Args...)(Args a) {
        ubyte[size] memory = (cast(ubyte*) malloc(size))[0..size];
        static foreach (i; 0..size) {
            memory[i] = initializer[i];
        }

        TypePtr t = cast(TypePtr) memory.ptr;
        static if (__traits(hasMember, TypePtr, "__ctor")) {
            t.__ctor(a);
        }

        return cast(TypePtr) t;
    }
}

private U[] _dup(T, U)(T[] a) // pure nothrow depends on postblit
{
    import core.stdc.string : memcpy;
    auto len = T.sizeof * a.length;
    void* arr = malloc(len);
    memcpy(arr, cast(const(void)*)a.ptr, len);
    auto res = *cast(U[]*)&arr;

    static if (__traits(hasPostblit, T))
        _doPostblit(res);
    return res;
}

@property T[] dup(T)(const(T)[] a)
if (is(const(T) : T))
{
    return _dup!(const(T), T)(a);
}
