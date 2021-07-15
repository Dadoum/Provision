module provision.androidclass;

public import provision.librarybundle;
import provision.androidlibrary;
import provision.utils.loghelper;
import std.traits;
import std.meta;
import std.exception;
import std.conv;
import provision.glue;

struct OpaquePtr;

abstract class AndroidClass {
    private OpaquePtr* hand;
    @property public const(OpaquePtr*) nativeHandle() const {
        return hand;
    }

    this() {

    }

    this(OpaquePtr* ptr) {
        hand = ptr;
    }
}

struct AndroidClassInfo {
    Library libraryName;
    uint classSize;
}

enum PrivateConstructorOperation {
    ALLOCATE,
    WRAP_OBJECT
}

extern (C++) {
    extern (C++,class) struct shared_ptr(T) {
        ~this() {
        }

        void* ptr;
        void* _control_block;
    }
}

AndroidClass[] toCleanup;

T get(T : AndroidClass)(shared_ptr!T sharedp) {
    return new T(PrivateConstructorOperation.WRAP_OBJECT, cast(OpaquePtr*) sharedp.ptr);
}

shared_ptr!T create_shared(T : AndroidClass)(T instance) {
    alias DestructionDelegate = extern (C) void function(void*);
    auto sharedptr = cast(shared_ptr!T*) shared_ptr_create(
            cast(OpaquePtr*) instance.nativeHandle, cast(DestructionDelegate)(pointer) {
        logln(T.stringof);
        destroy(pointer);
    });
    return *sharedptr;
}

void destroy_shared(T)(shared_ptr!T pointer) {
    return shared_ptr_delete(*(cast(const(OpaquePtr**))&pointer));
}

template Ref(T) if (isCallable!T) {
    alias Ref = SetFunctionAttributes!(T, functionLinkage!T,
            (cast(uint) functionAttributes!T) | (cast(uint) FunctionAttribute.ref_));
}

template Const(T) if (isCallable!T) {
    alias Const = SetFunctionAttributes!(T, functionLinkage!T,
            (cast(uint) functionAttributes!T) | (cast(uint) FunctionAttribute.const_));
}

template ConstRef(T) if (isCallable!T) {
    alias ConstRef = SetFunctionAttributes!(T, functionLinkage!T,
            (cast(uint) functionAttributes!T) | (cast(uint) FunctionAttribute.ref_) | (
                cast(uint) FunctionAttribute.const_));
}

public void cleanup() {
    import std.array;

    foreach (i, toClean; toCleanup) {
        destroy(toClean);
    }
}

mixin template implementDefaultConstructor() {
    import std.conv;
    import core.stdc.stdlib;

    static if (!hasCtorOfType!(typeof(this), PrivateConstructorOperation, OpaquePtr*)) {
        this(PrivateConstructorOperation op, OpaquePtr* ptr = cast(OpaquePtr*) null) {
            if (op == PrivateConstructorOperation.ALLOCATE) {
                super(cast(OpaquePtr*) malloc(getLibrary!(typeof(this)).classSize));
            } else if (op == PrivateConstructorOperation.WRAP_OBJECT) {
                super(ptr);
            } else {
                super();
                throw new InvalidCtorCallException(
                        "Paramètre \"op\" est incorrect ou non supporté (op = \"" ~ to!string(
                        op) ~ "\")");
            }
        }
    }
}

bool hasCtorOfType(T, Ctor...)() {
    foreach (ctor; __traits(getOverloads, T, "__ctor")) {
        if (is(ParameterTypeTuple!ctor : T)) {
            return true;
        }
    }
    return false;
}

mixin template implementMethod(T, string functionName, string librarySymbol,
        string[] methodModifiers = []) if (isCallable!T) {
    import std.conv;
    import std.traits;
    import std.string;
    import std.array;
    import std.algorithm.searching;

    enum isReferenceMethod = cast(bool)(functionAttributes!T & FunctionAttribute.ref_);

    mixin(methodModifiers.join(' ') ~ " " ~ ReturnType!T.stringof ~ " " ~ functionName
            ~ Parameters!T.stringof ~ " { mixin implementNativeMethod!(\"" ~ librarySymbol ~ "\", false, " ~ to!string(
                isReferenceMethod) ~ "); " ~ (is(ReturnType!T == void)
                ? "" : "return ") ~ " execute(); }");
}

mixin template implementConstructor(T, string librarySymbol = "") if (isCallable!T) {
    import std.typecons;
    import std.traits;
    import std.conv;

    mixin implementDefaultConstructor;

    this(ParameterTypeTuple!T) {
        this(PrivateConstructorOperation.ALLOCATE);
        static if (librarySymbol != "") {
            mixin implementNativeMethod!(librarySymbol, true);
            execute();
        }
    }
}

mixin template implementDestructor(string librarySymbol = "") {
    import std.typecons;
    import provision.utils.loghelper;
    import core.stdc.stdlib;
    import std.conv;

    ~this() {
        static if (librarySymbol != "") {
            mixin implementNativeMethod!librarySymbol;
            execute();
        }
        free(cast(void*) nativeHandle);
    }
}

/*
Ce mixin ne devrait etre utilisé que par les autres mixin d'implémentation.
 */
mixin template implementNativeMethod(string librarySymbol,
        bool isConstructor = false, bool isRef = false) {
    static assert(is(typeof(this) : AndroidClass), "Le type doit être derrivé d'AndroidClass !");
    import std.traits;
    import std.string;
    import app;
    import std.typecons;
    import std.meta;
    import provision.android.ndkstring;

    alias thisFunc = __traits(parent, {});
    enum isStatic = __traits(isStaticFunction, thisFunc);

    static if (!isConstructor) {
        alias UnqualifiedReturnType = Unqual!(typeof(return));
        static if (__traits(hasMember, typeof(return), "nativeHandle")) {
            alias RetType = void*;
        } else static if (is(UnqualifiedReturnType == string)) {
            alias RetType = NdkString;
        } else {
            alias RetType = typeof(return);
        }
    } else {
        alias RetType = void;
    }

    static if (isStatic) {
        alias ObjectType = AliasSeq!();
    } else {
        alias ObjectType = void*;
    }

    alias Arguments = TranslateToAndroidCpp!(thisFunc);

    alias BasicExternFunction = extern (C) RetType function(ObjectType, Parameters!Arguments);
    static if (isRef) {
        alias ExternCFunction = SetFunctionAttributes!(BasicExternFunction,
                functionLinkage!BasicExternFunction,
                functionAttributes!BasicExternFunction | FunctionAttribute.ref_);
    } else {
        alias ExternCFunction = BasicExternFunction;
    }

    static if (isConstructor) {
        alias ExecuteReturn = void;
    } else {
        alias ExecuteReturn = typeof(return);
    }

    alias PassedArguments1 = Parameters!Arguments;
    alias PassedArguments = MakeAllMutable!PassedArguments1;

    Tuple!(ObjectType, PassedArguments) getParams() {
        pragma(inline, true);
        Tuple!(PassedArguments) params;
        static if (is(typeof(thisFunc) Params == __parameters)) {
            static foreach (i, Param; Params) {
                static if (__traits(hasMember, Param, "nativeHandle")) {
                    params[i] = cast(PassedArguments[i]) mixin("_param_" ~ to!string(i))
                        .nativeHandle;
                } else static if (is(Param : string)) {
                    {
                        auto str = new NdkString(mixin("_param_" ~ to!string(i)));
                        params[i] = cast(PassedArguments[i]) str.nativeHandle;
                        toCleanup ~= str;
                    }
                } else {
                    params[i] = cast(PassedArguments[i]) mixin("_param_" ~ to!string(i));
                }
            }
        }

        Tuple!ObjectType h;
        static if (is(ObjectType == void*)) {
            h[0] = cast(void*) nativeHandle;
        }

        return tuple(h.expand, params.expand);
    }

    ExecuteReturn execute() {
        pragma(inline, true);
        import provision.androidlibrary;

        auto params = getParams();
        AndroidLibrary library = bundle.libraries[getLibrary!(typeof(this)).libraryName];
        auto func = (library.loadSymbol!ExternCFunction(librarySymbol));
        static if (!is(ExecuteReturn == void)) {
            import provision.utils.loghelper;

            static if (
                librarySymbol == "_ZN13storeservices18DefaultStoreClient27getAnisetteRequestMachineIdEv") {
                logln("IN");
            }
            auto ret = func(params.expand);
            static if (
                librarySymbol == "_ZN13storeservices18DefaultStoreClient27getAnisetteRequestMachineIdEv") {
                logln("OUT");
            }
            alias UnqualifiedReturnType = Unqual!ExecuteReturn;
            cleanup();
            alias Template = TemplateOf!ExecuteReturn;
            static if (is(Template == void)) {
                static if (is(ExecuteReturn : AndroidClass)) {
                    return new ExecuteReturn(PrivateConstructorOperation.WRAP_OBJECT,
                            cast(OpaquePtr*) ret);
                } else static if (is(UnqualifiedReturnType == string)) {
                    return new NdkString(PrivateConstructorOperation.WRAP_OBJECT,
                            cast(OpaquePtr*) ret).toDString();
                } else {
                    return ret;
                }
            } else {
                alias SharedPtredArr = TemplateArgsOf!ExecuteReturn;
                alias SharedPtred = SharedPtredArr[0];

                static if (__traits(isSame, Template, shared_ptr) && is(SharedPtred : AndroidClass)) {
                    return cast(ExecuteReturn) ret;
                } else {
                    return ret;
                }
            }
        } else {
            func(params.expand);
        }
    }
}

import provision.android.ndkstring;

string toDString(NdkString str) {
    import std.string;

    struct cpp_str {
        size_t[2] __padding;
        char* c_str;
    }

    auto native = cast(cpp_str*) str.nativeHandle;
    return to!string(fromStringz(native.c_str));
}

template TranslateToAndroidCpp(Arguments...) {
    alias TranslateToAndroidCpp = TranslateToAndroidCppPriv!(Arguments).result;
}

template TranslateToAndroidCppPriv(FuncArguments...) {
    import std.traits;
    import std.typecons;
    import std.conv;
    import std.array;
    import std.string;

    alias Arguments = Parameters!(FuncArguments);
    static if (Arguments.length) {
        // Conserver les attributs ref, out...
        alias Arg = Arguments[0 .. 1];
        alias UnqualifiedArg = Unqual!Arg;
        static if (__traits(hasMember, Arg, "nativeHandle")) {
            alias FinalArg = CopyTypeQualifiers!(Arg, OpaquePtr)*;
        } else static if (is(UnqualifiedArg == string)) {
            alias CppStrified = Parameters!(void function(ref const(Arg)));
            alias FinalArg = CopyTypeQualifiers!(CppStrified, OpaquePtr)*;
        } else {
            alias FinalArg = Arg;
        }
        alias result = void function(FinalArg,
                Parameters!(TranslateToAndroidCppPriv!(void function(Arguments[1 .. $])).result));
    } else {
        alias result = void function();
    }
}

package template MakeAllMutable(Args...) {
    static if (Args.length) {
        alias Arg = Args[0];
        alias T(U) = Arg;
        alias MakeAllMutable = AliasSeq!(MakeMutable!(T, Arg), MakeAllMutable!(Args[1 .. $]));
    } else {
        alias MakeAllMutable = AliasSeq!();
    }
}

package template MakeMutable(alias Modifier, T) {
    static if (is(T U == immutable U))
        alias MakeMutable = U;
    else static if (is(T U == shared inout const U))
        alias MakeMutable = shared inout U;
    else static if (is(T U == shared inout U))
        alias MakeMutable = shared inout U;
    else static if (is(T U == shared const U))
        alias MakeMutable = shared U;
    else static if (is(T U == shared U))
        alias MakeMutable = shared U;
    else static if (is(T U == inout const U))
        alias MakeMutable = inout U;
    else static if (is(T U == inout U))
        alias MakeMutable = inout U;
    else static if (is(T U == const U))
        alias MakeMutable = U;
    else
        alias MakeMutable = T;
}

AndroidClassInfo getLibrary(T)() {
    enum attributes = __traits(getAttributes, T);
    static if (attributes.length != 0) {
        static foreach (attr; attributes) {
            static if (is(typeof(attr) == AndroidClassInfo)) {
                return cast(AndroidClassInfo) attr;
            }
        }
    } else {
        throw new InvalidClassException("La couche de compatibilité de la classe native \"" ~ T.stringof
                ~ "\" est mal conçue. Elle doit avoir l'attribut AndroidClassInfo(string libraryName, int classSize)");
    }
}

class InvalidClassException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class InvalidCtorCallException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
