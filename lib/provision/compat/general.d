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
        // enum sysv = attribute("sysv_abi");
        import std.meta;
        alias sysv = AliasSeq!();
    } else {
        static assert(false, "Your compiler is not supported on your platform, please use LDC2 or GDC.");
    }
}

version (Windows) {
    version (X86) {
        version = WindowsHacks;
    }
    version (X86_64) {
        version = WindowsHacks;
    }
}

version (WindowsHacks) {
    import std.traits;
    pragma(inline, false) auto androidInvoke(T, G...)(T delegate_, G params) {
        void* del = cast(void*) delegate_;

        pragma(inline, false) extern(C) ReturnType!T internal(Parameters!T params, void* del) @naked @sysv { // HACK
            asm {
                "jmp *%0" :: "r" (del);
            }
        }

        import slf4d;
        getLogger().traceF!"Calling ? %x%s"(del, G.stringof);
        import std.stdio;
        stdout.flush();
        return internal(params, del);
    }
} else {
    pragma(inline, true) auto androidInvoke(T, G...)(T delegate_, G params) {
        return delegate_(params);
    }
}
