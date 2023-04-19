module provision.compat.general;

version (linux) {
    import std.meta;
    alias sysv = AliasSeq!();
} else {
    version (LDC) {
        import ldc.attributes;
        enum sysv = callingConvention("sysv_abi");
    } else version (GNU) {
        import gcc.attributes;
        enum sysv = attribute("sysv_abi");
        import std.meta;
        // alias sysv = AliasSeq!();
    } else {
        static assert(false, "Your compiler is not supported on your platform, please use LDC2 or GDC.");
    }
}

//+
template sysvCall(alias U) {
    version (linux) {
        alias sysvCall = U;
        /+
        import std.traits;
        static if (is(U == function)) {
            enum address = &U;
        } else {
            alias address = U;
        }

        extern (C) ReturnType!U sysvCallWorkaround(const char* p, void* ptr) @sysv {
            import std.stdio;
            import std.string;
            // stderr.writeln(params[0].fromStringz);
            // alias c = params[0];
            asm {
                mov RDI, p;
                mov RSI, p;
                mov RDX, p;
                mov RCX, p;
                mov R8, p;
                mov R9, p;
                jmp ptr; // "jmp *%0" :: "i==" (ptr);
            }
        }

        extern (C) ReturnType!U sysvCall(Parameters!U params) @sysv {
            return sysvCallWorkaround(params, address);
        }
        // +/
    } else version (X86_64) {
        import std.traits;
        static if (is(U == function)) {
            enum address = &U;
        } else {
            alias address = U;
        }

        extern (C) int sysvCallWorkaround(const char* test, void* ptr) @sysv {
            asm {
                jmp ptr; // "jmp *%0" :: "i==" (ptr);
            }
        }

        extern (C) ReturnType!U sysvCall(Parameters!U params) @sysv {
            import std.stdio;
            import std.string;
            stderr.writeln(address);
            return sysvCallWorkaround(params, address);
        }
    } else {
        alias sysvCall = U;
    }
}
// +/

/+
template sysvCall(alias U) {
    version (linux) {
        alias sysvCall = U;
    } else version (X86_64) {
        import std.traits;
        static if (is(U == function)) {
            enum address = &U;
        } else {
            alias address = U;
        }

        void* ptr;

        extern (C) ReturnType!U sysvCallWorkaround(Parameters!U) @sysv @naked {
            asm {
                naked;
                jmp ptr;
            }
        }

        extern (C) ReturnType!U sysvCall(Parameters!U params) {
            ptr = address;
            return sysvCallWorkaround(params);
        }
    } else {
        alias sysvCall = U;
    }
}
// +/