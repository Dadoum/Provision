module provision.androidclass;

public import provision.librarybundle;

public import core.stdc.stdlib;
public import std.algorithm;
public import std.array;
public import std.conv;
public import std.exception;
public import std.meta;
public import std.traits;
public import std.typecons;
public import provision.androidlibrary;
public import provision.glue;
public import provision.utils.loghelper;

struct OpaquePtr;
extern(C++) struct AndroidClassPtr { void[392] __padding; }

public struct MangledName {
    @disable this();
    @disable this(this);

    string symbol;

    this(string symbol) {
        this.symbol = symbol;
    }
}

public struct Hook {
    @disable this(this);

    string symbol = "";

    this(string symbol) {
        this.symbol = symbol;
    }
}

class AggregatedException : Exception {
    this(Exception[] ex, string file = __FILE__, size_t line = __LINE__) {
        super(cast(string) ("Plusieurs exceptions ont eu lieu et ensemble, ont causé cette exception: \n\t - " ~ ex.map!(e => e.message()).join("\n\t - ")), file, line);
    }
}

mixin template importNativeCpp(alias U) {
    import std.format;
    import std.stdio;

    mixin(q{alias ParentClass = __traits(parent, U);});
    enum isCtor = __traits(identifier, U) == "__ctor";
    static if (isCtor) {

    }

    enum isDtor = __traits(identifier, U) == "__dtor";
    enum isRef = hasFunctionAttributes!(U, "ref") && !isCtor && !isDtor;
    enum isStatic = __traits(isStaticFunction, U);
    static if (isCtor) {
        alias Args = Parameters!U;
        alias RetType = void;
    } else {
        static if (isDtor) {
            alias Args = ParentClass;
        } else {
            alias Args = Parameters!U;
        }
        alias RetType = ReturnType!U;
    }

    enum mangledName = getAttribute!(MangledName, U);
    static if (is(typeof(mangledName) == typeof(null))) {
        enum name = U.mangleof;
    } else {
        enum name = mangledName.symbol;
    }

    template loadMethod(alias methodToLoad) {
        alias loadFunction = loadSymbolGlobal!(typeof(&methodToLoad));

        private static ReturnType!loadFunction __symbol = null;

        @property static ReturnType!loadFunction symbol() {
            pragma(inline, true);
            if (__symbol == null)
                __symbol = loadFunction(name);
            return __symbol;
        }

        private static auto loadSymbolGlobal(T)(string symbol) {
            pragma(inline, true);
            Exception[] ex;
            alias TRet = TranslateToAndroidCpp!T;
            for (int i = EnumMembers!Library.length - 1; i >= 0; i--) {
                try {
                    auto ret = libraryBundleInstance[i].loadSymbol!TRet(symbol);
                    // lib = cast(Library) i;
                    return ret;
                } catch (Exception e) {
                    ex ~= e;
                }
            }
            throw new AggregatedException(ex);
        }

        static if (isRef) {
            static ref ReturnType!methodToLoad loadedMethod(Parameters!methodToLoad params) {
                pragma(inline, true);

                auto params_translated = translateTuple!(void delegate(Parameters!methodToLoad))(params);

                static if (is(typeof(return) == void))
                    symbol()(params_translated.expand);
                else {
                    return translateBackRef!(typeof(return))(symbol()(params_translated.expand));
                }

                // throw new LibraryLoadException(format!"Not implemented. (%s, %s)"(name, typeof(symbol).stringof));
            }
        } else {
            static ReturnType!methodToLoad loadedMethod(Parameters!methodToLoad params) {
                pragma(inline, true);
                void*[Parameters!methodToLoad.length] array;
                static foreach(i, param; Parameters!methodToLoad) {
                    array[i] = cast(void*) &params[i];
                }

                auto sym = symbol();
                // pragma(msg, typeof(&methodToLoad).stringof.replace("function", __traits(identifier, U)) ~ " -> " ~ typeof(&symbol).stringof.replace("function", __traits(identifier, U)));

                import std.stdio;
                auto params_translated = translateTuple!(void delegate(Parameters!methodToLoad))(params);

                import std.stdio;
                static if (is(typeof(return) == void)) {
                    sym(params_translated.expand);
                }
                else {
                    return translateBack!(typeof(return))(sym(params_translated.expand));
                }
            }
        }

        alias loadMethod = loadedMethod;
    }

    static if (isDtor) {
        pragma(mangle, U.mangleof) extern(C++) static RetType __dtorImpl(ParentClass* self) {
            pragma(inline, true);
            import std.stdio;
            loadMethod!(__traits(parent, {}))(self);
        }

        pragma(mangle,ParentClass.__dtor.mangleof) ~this() {
            __dtorImpl(&this);
        }
    } else static if (isCtor) {
        extern(C++) {
            static ParentClass* create(Args e) {
                pragma(inline, true);
                ParentClass* ret = ParentClass.allocate();
                return create(ret, e);
            }

            pragma(mangle,U.mangleof) static ParentClass* create(ParentClass* ret, Args e) {
                import std.experimental.allocator;
                static void __impl(ParentClass* self, Args a2) {
                    loadMethod!__impl(self, a2);
                }
                __impl(ret, e);
                return ret;
            }
        }
    }
    else static if (isRef) {
        static if (isStatic) {
            pragma(mangle,U.mangleof) extern(C++) static ref RetType impl(Args e) {
                static if (is(RetType == void))
                    loadMethod!(__traits(parent, {}))(e);
                else
                    return loadMethod!(__traits(parent, {}))(e);
            }
        } else {
            pragma(mangle,U.mangleof) extern(C++) static ref RetType impl(ParentClass* self, Args e) {
                static if (is(RetType == void))
                    loadMethod!(__traits(parent, {}))(self, e);
                else
                    return loadMethod!(__traits(parent, {}))(self, e);
            }
        }
    }
    else {
        static if (isStatic) {
            pragma(mangle,U.mangleof) extern(C++) static RetType impl(Args e) {
                static if (is(RetType == void))
                    loadMethod!(__traits(parent, {}))(e);
                else
                    return loadMethod!(__traits(parent, {}))(e);
            }
        } else {
            pragma(mangle,U.mangleof) extern(C++) static RetType impl(ParentClass* self, Args e) {
                static if (is(RetType == void))
                    loadMethod!(__traits(parent, {}))(self, e);
                else
                    return loadMethod!(__traits(parent, {}))(self, e);
            }
        }
    }
    // pragma(msg, format!"Generated function: %s %s.%s%s from %s"(RetType.stringof, ParentClass.stringof, __traits(identifier, U), Args.stringof, typeof(U).stringof));
}

mixin template exportNativeCpp(string text, alias U) {
    static if (isCallable!U) {
        extern(D) shared static this() {
            static if (text == "") {
                enum symbol = U.mangleof;
            } else {
                enum symbol = text;
            }
            AndroidLibrary.addGlobalHook(symbol, U);
        }
    }
}

mixin template AndroidClassImpl(alias method)
{
    static if (functionLinkage!method == "C++")
    {
        enum attrs = __traits(getAttributes, method);
        static if (staticIndexOf!(Hook, attrs) != -1) {
            mixin exportNativeCpp!method;
        } else {
            mixin importNativeCpp!method;
        }
    }
}

mixin template parserWorkaroundAndroidClass(T) {
    mixin(q{
        static foreach (methodStr; __traits(allMembers, T))
        {
            static foreach (method; __traits(getOverloads, T, methodStr))
            {
                static if (is(__traits(parent, method) == T))
                {
                    mixin AndroidClassImpl!method;
                }
            }
        }
    });
}

mixin template AndroidClass(T) {
    extern(D)
    {
        mixin parserWorkaroundAndroidClass!T;

        public AndroidClassPtr* handle;
        package bool owned;

        import core.memory;

        public static final T* allocate() {
            import core.stdc.string;
            auto ret = cast(T*) GC.malloc(T.sizeof, GC.BlkAttr.NO_MOVE);
            ret.handle = cast(AndroidClassPtr*) GC.malloc(392, GC.BlkAttr.NO_MOVE);
            ret.handle.memset(0, 392);
            ret.owned = true;
            return ret;
        }

        public static final T* wrap(AndroidClassPtr* ptr) {
            import std.experimental.allocator;
            alias RPtr = T*;
            T* ret = cast(T*) GC.malloc(T.sizeof, GC.BlkAttr.NO_MOVE);
            ret.handle = ptr;
            ret.owned = false;
            return ret;
        }

        public final void finalize() {
            if (owned)
                free(handle);
        }
    }
}

NdkString* toHybrisStr(string s) {
    pragma(inline, true);
    import std.string;
    static NdkString* str;
    str = NdkString.create(s.toStringz());
    return str;
}

bool hasCtorOfType(T, Ctor...)() {
    foreach (ctor; __traits(getOverloads, T, "__ctor")) {
        if (is(ParameterTypeTuple!ctor : T)) {
            return true;
        }
    }
    return false;
}

string toDString(ref const(NdkString) str) {
    import std.string;

    auto native = std_string_c_str(str.handle);
    return to!string(native.fromStringz); // std_string_c_str(&(cast(void*) str.handle))
}

template IteratedNormalizePSC(ParameterStorageClass[] PSC0, T...) if (T.length == PSC0.length && T.length != 0) {
    static if (T.length > 1) {
        alias IteratedNormalizePSC = AliasSeq!(NormalizePSC!(PSC0[0], T[0]), IteratedNormalizePSC!(PSC0[1..$], T[1..$]));
    } else {
        alias IteratedNormalizePSC = NormalizePSC!(PSC0[0], T[0]);
    }
}

template NormalizePSC(ParameterStorageClass PSC0, T) {
    static if (PSC0 != ParameterStorageClass.none) {
        static if (PSC0 == ParameterStorageClass.in_) {
            alias NormalizePSC = Parameters!(void function(T*));
        }
        static if (PSC0 == ParameterStorageClass.lazy_) {
            alias NormalizePSC = Parameters!(void function(lazy T));
        }
        static if (PSC0 == ParameterStorageClass.out_) {
            alias NormalizePSC = Parameters!(void function(T*));
        }
        static if (PSC0 == ParameterStorageClass.ref_) {
            alias NormalizePSC = Parameters!(void function(T*));
        }
        static if (PSC0 == ParameterStorageClass.return_) {
            alias NormalizePSC = Parameters!(void function(return T));
        }
    } else {
        alias NormalizePSC = T;
    }
}

template TranslateType(FuncArguments) {
    static if (is(FuncArguments == delegate)) {
        alias Arg = Parameters!FuncArguments[0..1];
        static if (is(Arg[0] == void))
            alias TranslateType = void;
        else {
            alias Translated1Step = ReturnType!(translate!(void delegate(Arg)));
            enum PSC0 = ParameterStorageClassTuple!FuncArguments[0];
            alias Translated2Step = CopyTypeQualifiers!(FuncArguments[0], Translated1Step);
            alias TranslateType = NormalizePSC!(PSC0, Translated2Step);
        }
    } else {
        static if (is(FuncArguments == void))
            alias TranslateType = void;
        else {
            alias TranslateType = TranslateType!(void delegate(FuncArguments));
        }
    }
}

template TranslateToAndroidCpp(Arguments...) {
    alias RetType = ReturnType!Arguments;

    template __impl(FuncArguments...) {
        import std.traits;
        import std.typecons;
        import std.conv;
        import std.array;
        import std.string;

        alias Arguments = Parameters!(FuncArguments);
        static if (Arguments.length) {
            alias Arg = Arguments[0 .. 1];
            // pragma(msg, Arg);
            alias __impl = RetType function(TranslateType!(void delegate(Arg)),
            Parameters!(__impl!(RetType function(Arguments[1 .. $]))));
        } else {
            alias __impl = RetType function();
        }
    }

    alias TranslateToAndroidCppWithoutRet = __impl!(Arguments);
    alias TranslateToAndroidCpp1 = extern(C++) TranslateType!RetType function(Parameters!TranslateToAndroidCppWithoutRet);
    alias TranslateToAndroidCpp = SetFunctionAttributes!(TranslateToAndroidCpp1, functionLinkage!TranslateToAndroidCpp1, functionAttributes!Arguments);
}

auto translateTuple(FuncArgs)(ref Parameters!FuncArgs a) if (is(FuncArgs == delegate)) {
    alias Args = Parameters!FuncArgs;
    pragma(inline, true);
    import std.stdio;
    static if (Args.length) {
        return tuple(translate!(void delegate(Args[0..1]), ParameterStorageClassTuple!FuncArgs[0])(a[0..1]), translateTuple!(void delegate(Args[1..$]))(a[1..$]).expand);
    } else {
        return tuple();
    }
}

template isAndroidClass(T) {
    enum isAndroidClass = __traits(hasMember, T, "handle");
}

ref auto translate(FuncArg, ParameterStorageClass sc0 = ParameterStorageClass.none)(Parameters!FuncArg object) if (is(FuncArg == delegate)) {
    static if (sc0 == ParameterStorageClass.ref_) {
        return &translate!FuncArg(object);
    } else {
        import std.stdio;
        alias T = Parameters!FuncArg[0];
        static if (isAndroidClass!T) {
            static if (isPointer!T) {
                static if (!isPointer!(PointerTarget!T)) {
                    return object[0].handle;
                } else {
                    Unqual!(ReturnType!(translate!(typeof(*object)))) __temp;
                    __temp = translate(*object);
                    return &__temp;
                }
            } else {
                return *(object[0].handle);
            }
        } else {
            return object[0];
        }
    }
}

T translateBack(T)(TranslateType!T object) {
    return translateBackRef!T(object);
}

ref T translateBackRef(T)(return ref TranslateType!T object) {
    static if (isAndroidClass!T) {
        static if (isPointer!(T)) {
            // TODO: remove this hack
            static T __temp;
            __temp = &translateBackRef!(PointerTarget!T)(*object);
            return __temp;
        } else {
            return *T.wrap(cast (Parameters!(T.wrap)[0]) &object);
        }
    } else {
        return object;
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

template getAttribute(Attribute, alias T) {
    enum attributes = __traits(getAttributes, T);
    static if (attributes.length != 0) {
        static foreach (attr; attributes) {
            static if (is(typeof(attr) == Attribute)) {
                enum getAttribute = cast(Attribute) attr;
            }
        }
    } else {
        enum getAttribute = null;
    }
}

enum StdNamespace = AliasSeq!("std", "__ndk1");
extern(C++, class) extern(C++, (StdNamespace)) {
    private struct char_traits(T) {

    }

    struct allocator(T) {

    }

    private struct basic_string(T, TTraits, TAllocator)
    {
        mixin AndroidClass!(basic_string!(T, TTraits, TAllocator));
        @MangledName("_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC2IDnEEPKc") this(const(char)*);
        @MangledName("_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC2ERKS5_") this(ref const(basic_string));
        @MangledName("_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED2Ev") ~this();

        extern(D) {
            void opAssign(const(T)[] str) {
                import std.string;
                __dtor();
                mixin(q{basic_string.create(str.toStringz);});
            }
        }
    }
}

alias NdkString = basic_string!(char, char_traits!char, allocator!char);
alias RefNdkString = Parameters!(void function(ref basic_string!(char, char_traits!char, allocator!char)));
