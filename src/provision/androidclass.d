module provision.androidclass;

import provision.androidlibrary;
import provision.librarybundle;
import std.traits;
import std.exception;
import std.conv;
import core.stdcpp.xutility;
import std.meta;

abstract class AndroidClass
{
    public shared_ptr!void handle;

    this()
    {

    }

	this(shared_ptr!void ptr)
    {
        handle = ptr;
    }
    
    this(void* ptr)
    {
        handle.ptr = ptr;
    }
}

struct AndroidClassInfo
{
    string libraryName;
    ulong classSize;
}

extern (C++,(StdNamespace))
{

    /// Simple binding to `std::shared_ptr`
    extern (C++,class) struct shared_ptr(T)
    {
        static if (is(T == class) || is(T == interface))
            private alias TPtr = T;
        else
            private alias TPtr = T*;

        ~this()
        {
        }

        TPtr ptr;
        void* _control_block;
        alias ptr this;
    }

    /// Simple binding to `std::unique_ptr`
    extern (C++,class) struct unique_ptr(T)
    {
        static if (is(T == class) || is(T == interface))
            private alias TPtr = T;
        else
            private alias TPtr = T*;

        TPtr ptr;
        alias ptr this;
    }
}

extern (C++,(StdNamespace))
{
    shared_ptr!T make_shared(T, Args...)(Args args);
}

mixin template implementDefaultConstructor()
{
    import std.conv;
    import core.stdc.stdlib;

    mixin("this(shared_ptr!void ptr) { super(ptr); } this(void* ptr) { if (ptr == null) { super(malloc(" ~ to!string(
            getLibrary!(typeof(this)).classSize) ~ ")); } else { super(ptr); } }");
}

mixin template implementMethod(T, string functionName, string librarySymbol,
        string[] methodModifiers = []) if (isCallable!T)
{
	import std.conv;
    import std.traits;
    import std.string;
    import std.array;
    import std.algorithm.searching;

    enum isReferenceMethod = [__traits(getFunctionAttributes, T)].canFind("ref");
    mixin(methodModifiers.join(' ') ~ " " ~ ReturnType!T.stringof ~ " " ~ functionName
            ~ Parameters!T.stringof ~ " { mixin implementNativeMethod!(\"" ~ librarySymbol ~ "\", false, " ~ to!string(isReferenceMethod) ~ "); " ~ (
                is(ReturnType!T == void) ? "" : "return ") ~ " execute(); }");
}

mixin template implementConstructor(T, string librarySymbol = "") if (isCallable!T)
{
    import std.typecons;
    import std.traits;
    import std.conv;

    alias void* Void;
    static if (!hasCtorOfType!(typeof(this), Void))
    {
        mixin implementDefaultConstructor;
    }
    mixin("this " ~ ParameterTypeTuple!T.stringof ~ " { this(cast(void*) null); static if (" ~ to!string(
            librarySymbol != "") ~ ") { mixin implementNativeMethod!(\""
            ~ librarySymbol ~ "\", true); execute(); } }");
}

bool hasCtorOfType(T, Ctor...)()
{
    foreach (ctor; __traits(getOverloads, T, "__ctor"))
    {
        if (is(ParameterTypeTuple!ctor : T))
        {
            return true;
        }
    }
    return false;
}

mixin template implementDestructor(string librarySymbol = "")
{
    import std.typecons;
    import provision.utils.loghelper;
    import core.stdc.stdlib;
    import std.conv;

    mixin("~this() { static if (" ~ to!string(librarySymbol != "")
            ~ ") { mixin implementNativeMethod!\"" ~ librarySymbol
            ~ "\"; execute(); } free(handle.ptr); }");
}

/*
exemple de code généré:
alias extern(C) void function(void* handle) ExternCFunction;
void execute() { 
	(LibraryBundle.instance.libraries["libandroidappmusic"].loadSymbol!(ExternCFunction)("_ZN17storeservicescore20RequestContextConfigC2Ev"))(handle.ptr); 
}
Ce mixin ne devrait etre utilisé que par les autres mixin d'implémentation.
 */
mixin template implementNativeMethod(string librarySymbol, bool isConstructor = false, bool isRef = false)
{
    static assert(is(typeof(this) : AndroidClass), "Le type doit être derrivé d'AndroidClass !");
    import std.traits;
    import std.string;
    import core.stdcpp.string;
    import app;
    import std.typecons;
    import std.meta;

    static if (!isConstructor)
    {
        static if (is(Unqual!(typeof(return)) : AndroidClass))
        {
            alias RetType = void*;
        }
        else
        {
            alias RetType = typeof(return);
        }
    }
    else
    {
        alias RetType = void;
    }

    static if (mixin("__traits(isStaticFunction, " ~ mixin(
            "__traits(identifier, __traits(parent, {}))") ~ ")"))
    {
        alias ObjectType = AliasSeq!();
    }
    else
    {
        alias ObjectType = void*;
    }

    alias Arguments = TranslateToAndroidCpp!(__traits(parent, {}));

	alias BasicExternCppFunction = extern (C++) RetType function(ObjectType, Parameters!Arguments);
    static if (isRef) 
    {
    	alias ExternCFunction = extern (C++) SetFunctionAttributes!(BasicExternCppFunction, functionLinkage!BasicExternCppFunction, functionAttributes!BasicExternCppFunction | FunctionAttribute.ref_);
    }
    else 
    {
    	alias ExternCFunction = BasicExternCppFunction;
    }

    mixin((isRef ? "ref " : "") ~ (isConstructor ? "void" : (typeof(return))
            .stringof) ~ " execute() { " ~ ((typeof(return)).stringof == "void"
            || isConstructor ? "" : "return ") ~ (is(typeof(return) : AndroidClass)
            && !isConstructor ? "new " ~ typeof(return).stringof ~ "(" : "") // Charger le symbole qu'on nous a donné
             ~ "(bundle[\"" ~ getLibrary!(typeof(this))
            .libraryName ~ "\"].loadSymbol!(ExternCFunction)(\"" ~ librarySymbol ~ "\"))(" // Invoquer la fonction avec tous les arguments du parent.
            // d'abord on vérifie si on met la handle
             ~ (
                mixin("__traits(isStaticFunction, " ~ mixin(
                "__traits(identifier, __traits(parent, {}))") ~ ")") ? "" : "handle.ptr, ") // puis on passe tous les arguments avec les bons noms
             ~ getCallString!(Parameters!(__traits(parent, {})))() // retrieveParamNames( params.stringof[1..$-1]).join( ", ")
             ~ ")" ~ (is(typeof(return) : AndroidClass) && !isConstructor ? ")" : "") ~ ";}");
}

template TranslateToAndroidCpp(Arguments...)
{
    alias TranslateToAndroidCpp = TranslateToAndroidCppPriv!(Arguments).result;
}

template TranslateToAndroidCppPriv(FuncArguments...)
{
    import std.traits;
    import std.typecons;
    import std.conv;
    import std.array;
    import std.string;
    import core.stdcpp.allocator;

    alias Arguments = Parameters!(FuncArguments);
    static if (Arguments.length)
    {
        // Conserver les attributs ref, out...
        alias Arg = Arguments[0 .. 1];
        static if (is(Unqual!Arg : AndroidClass))
        {
            alias FinalArg = CopyTypeQualifiers!(Arg, void*);
        }
        else
        {
            alias FinalArg = Arg;
        }
        alias result = void function(FinalArg,
                Parameters!(TranslateToAndroidCppPriv!(void function(Arguments[1 .. $])).result));
    }
    else
    {
        alias result = void function();
    }
}

string[] splitWithoutParenthesis(string s, char delim)()
{
    import std.string;

    string[] ret = [];
    string token = "";
    int nested = 0;
    foreach (c; s)
    {
        if (c == '(')
        {
            nested++;
        }
        else if (c == ')')
        {
            nested--;
        }
        else if (nested == 0)
        {
            if (c == delim)
            {
                ret ~= token.strip();
                token = "";
                continue;
            }
        }
        token ~= c;
    }
    ret ~= token.strip();
    token = "";

    return ret;
}

string getCallString(Args...)()
{
    import std.conv;
    import std.traits;

    string call = "";
    int i = 0;
    static foreach (T; Args)
    {
        call ~= "_param_" ~ to!string(i);
        if (is(Unqual!(T) : AndroidClass))
        {
            call ~= ".handle.ptr";
        }
        call ~= ", ";
        i++;
    }
    return call;
}

AndroidClassInfo getLibrary(T)()
{
    foreach (attr; __traits(getAttributes, T))
    {
        if (is(typeof(attr) == AndroidClassInfo))
        {
            return cast(AndroidClassInfo) attr;
        }
    }
    throw new InvalidClassException("La couche de compatibilité de la classe native \"" ~ T.stringof
            ~ "\" est mal conçue. Elle doit avoir l'attribut AndroidClassInfo(string libraryName, int classSize)");
}

class InvalidClassException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}
