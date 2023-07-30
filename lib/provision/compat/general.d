module provision.compat.general;

version (Windows) {
    version (X86) {
        version = WindowsHacks;
    }
    version (X86_64) {
        version = WindowsHacks;
    }
}

version (WindowsHacks) {
    version (LDC) {
        import ldc.attributes;
        import ldc.llvmasm;
        enum sysv = callingConvention("sysv_abi");
    } else version (GNU) {
        import gcc.attributes;
        // enum sysv = attribute("sysv_abi");
        import std.meta;
        alias sysv = AliasSeq!();
    } else {
        static assert(false, "Your compiler is not supported on your platform, please use LDC2 or GDC.");
    }

    import std.traits;
    pragma(inline, false) auto androidInvoke(alias U)(Parameters!U params) {
        pragma(inline, false) extern(C) ReturnType!U internal(typeof(params)) @naked @sysv { // HACK
            // asm {
            //     "jmp *%0" :: "r" (del);
            // }
            return __asm!(typeof(return))("jmp *%rax", "={rax}");
        }

        debug {
            import slf4d;
            getLogger().traceF!"calling %s"(__traits(identifier, U));
        }

        __asm("mov $0, %rax", "{rax}", U);
        return internal(params);
    }
} else {
    import std.meta;
    alias sysv = AliasSeq!();

    alias androidInvoke(alias U) = U;
}
