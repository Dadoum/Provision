module provision.androidlibrary;

import core.exception;
import core.memory;
import core.stdc.stdint;
import core.sys.elf;
import core.sys.linux.link;
import core.sys.posix.sys.mman;
import std.algorithm;
import std.conv;
import std.mmfile;
import std.path;
import std.random;
import std.stdio;
import std.string;
import std.traits;
import provision.posixlibrary;

public struct AndroidLibrary {
    package MmFile elfFile;
    package void[] allocation;

    public this(string libraryName) {
        elfFile = new MmFile(libraryName);

        auto elfHeader = elfFile.identify!(ElfW!"Ehdr")(0);
        auto programHeaders = elfFile.identifyArray!(ElfW!"Phdr")(elfHeader.e_phoff, elfHeader.e_phnum);

        size_t minimum = size_t.max;
        size_t maximumFile = size_t.min;
        size_t maximumMemory = size_t.min;

        size_t headerStart;
        size_t headerEnd;
        size_t headerMemoryEnd;

        foreach (programHeader; programHeaders) {
            if (programHeader.p_type == PT_LOAD) {
                headerStart = programHeader.p_vaddr;
                headerEnd = programHeader.p_vaddr + programHeader.p_filesz;
                headerMemoryEnd = programHeader.p_vaddr + programHeader.p_memsz;

                if (headerStart < minimum) {
                    minimum = headerStart;
                }
                if (headerEnd > maximumFile) {
                    maximumFile = headerEnd;
                }
                if (headerMemoryEnd > maximumMemory) {
                    maximumMemory = headerMemoryEnd;
                }
            }
        }

        auto alignedMinimum = pageFloor(minimum);
        auto alignedMaximumMemory = pageCeil(maximumMemory);

        auto allocSize = alignedMaximumMemory - alignedMinimum;
        allocation = GC.malloc(allocSize)[0..allocSize];
        writefln!("Allocated %1$d bytes (%1$x) of memory, at %2$x")(allocSize, allocation.ptr);
        allocation[minimum - alignedMinimum..maximumFile - alignedMinimum] = elfFile[minimum..maximumFile];

        size_t pageStart;
        size_t pageEnd;

        foreach (programHeader; programHeaders) {
            if (programHeader.p_type == PT_LOAD) {
                pageStart = pageFloor(programHeader.p_vaddr);
                pageEnd = pageCeil(programHeader.p_vaddr + programHeader.p_memsz);

                mprotect(allocation.ptr + pageStart, allocSize, programHeader.memoryProtection());
            }
        }

        auto sectionHeaders = elfFile.identifyArray!(ElfW!"Shdr")(elfHeader.e_shoff, elfHeader.e_shnum);
        foreach (sectionHeader; sectionHeaders) {
            switch (sectionHeader.sh_type) {
                case SHT_DYNSYM:
                    break;
                case SHT_STRTAB:
                    break;
                case SHT_GNU_HASH:
                    break;
                case SHT_REL:
                    this.relocate!(ElfW!"Rel")(sectionHeader);
                    break;
                case SHT_RELA:
                    this.relocate!(ElfW!"Rela")(sectionHeader);
                    break;
                default:
                    break;
            }
        }
    }

    void* load(string symbol) const {
        return null;
    }
}

private size_t pageMask;

shared static this()
{
    pageMask = ~(pageSize - 1);
}

int memoryProtection(ref ElfW!"Phdr" phdr)
{
    int prot = 0;
    if (phdr.p_flags & PF_R)
        prot |= PROT_READ;
    if (phdr.p_flags & PF_W)
        prot |= PROT_WRITE;
    if (phdr.p_flags & PF_X)
        prot |= PROT_EXEC;

    return prot;
}

template ELFW(string func) {
    alias ELFW = mixin("ELF" ~ to!string(size_t.sizeof * 8) ~ "_" ~ func);
}

version (X86_64) {
    private enum string relocationArch = "X86_64";
    private enum R_GENERIC_NATIVE_ABS = R_X86_64_64;
} else version (X86) {
    private enum string relocationArch = "386";
    private enum R_GENERIC_NATIVE_ABS = R_386_32;
} else version (AArch64) {
    private enum string relocationArch = "AARCH64";
    private enum R_GENERIC_NATIVE_ABS = R_AARCH64_ABS64;
} else version (ARM) {
    private enum string relocationArch = "ARM";
    private enum R_GENERIC_NATIVE_ABS = R_ARM_ABS32;
}

template R_GENERIC(string relocationType) {
    enum R_GENERIC = mixin("R_" ~ relocationArch ~ "_" ~ relocationType);
}

void relocate(RelocationType)(ref AndroidLibrary library, ref ElfW!"Shdr" shdr) {
    auto relocations = library.elfFile.identifyArray!(RelocationType)(shdr.sh_offset, shdr.sh_size / RelocationType.sizeof);

    foreach (relocation; relocations) {
        auto relocationType = ELFW!"R_TYPE"(relocation.r_info);

        auto offset = relocation.r_offset;

        switch (relocationType) {
            case R_GENERIC!"RELATIVE":
                break;
            case R_GENERIC!"GLOB_DAT":
            case R_GENERIC!"JUMP_SLOT":
                break;
            case R_GENERIC_NATIVE_ABS:
                break;
            default:
                throw new LoaderException("Unknown relocation type: " ~ to!string(relocationType));
        }
    }
}

size_t pageFloor(size_t number) {
    return number & pageMask;
}

size_t pageCeil(size_t number) {
    return (number + pageSize - 1) & pageMask;
}

RetType[] identifyArray(RetType, FromType)(FromType obj, size_t offset, size_t length) {
    return (cast(RetType[]) obj[offset..offset + (RetType.sizeof * length)]).ptr[0..length];
}

RetType identify(RetType, FromType)(FromType obj, size_t offset) {
    return obj[offset..offset + RetType.sizeof].reinterpret!(RetType);
}

RetType reinterpret(RetType, FromType)(FromType[] obj) {
    return (cast(RetType[]) obj)[0];
}

private static __gshared PosixLibrary* libc;

extern(C) int __system_property_get_impl(const char* n, char *value) {
    auto name = n.fromStringz;

    enum str = "no s/n number";

    value[0..str.length] = str;
    // strncpy(value, str.ptr, str.length);
    return cast(int) str.length;
}

extern(C) uint arc4random_impl() {
    return Random(unpredictableSeed()).front;
}

extern(C) int emptyStub() {
    return 0;
}

extern(C) noreturn undefinedSymbol() {
    throw new UndefinedSymbolException();
}

extern(C) private static void* hookFinder(string symbolName) {
    import core.stdc.errno;
    import core.stdc.stdlib;
    import core.stdc.string;
    import core.sys.posix.fcntl;
    import core.sys.posix.sys.stat;
    import core.sys.posix.sys.time;
    import core.sys.posix.unistd;

    auto defaultHooks = [
        "arc4random": cast(void*) &arc4random_impl,
        "chmod": cast(void*) &chmod,
        "__system_property_get": cast(void*) &__system_property_get_impl,
        "__errno": cast(void*) &errno,
        "close": cast(void*) &close,
        "free": cast(void*) &free,
        "fstat": cast(void*) &fstat,
        "ftruncate": cast(void*) &ftruncate,
        "gettimeofday": cast(void*) &gettimeofday,
        "lstat": cast(void*) &lstat,
        "malloc": cast(void*) &malloc,
        "mkdir": cast(void*) &mkdir,
        "open": cast(void*) &open,
        "read": cast(void*) &read,
        "strncpy": cast(void*) &strncpy,
        "umask": cast(void*) &umask,
        "write": cast(void*) &write,
        "pthread_rwlock_destroy": cast(void*) &emptyStub,
        "pthread_rwlock_init": cast(void*) &emptyStub,
        "pthread_rwlock_rdlock": cast(void*) &emptyStub,
        "pthread_rwlock_unlock": cast(void*) &emptyStub,
        "pthread_rwlock_wrlock": cast(void*) &emptyStub,
        "pthread_create": cast(void*) &emptyStub,
        "pthread_mutex_lock": cast(void*) &emptyStub,
        "pthread_mutex_unlock": cast(void*) &emptyStub,
        "pthread_once": cast(void*) &emptyStub,
        "pthread_rwlock_init": cast(void*) &emptyStub,
        "pthread_rwlock_unlock": cast(void*) &emptyStub,
        "pthread_rwlock_wrlock": cast(void*) &emptyStub,
    ];

    auto symbol = symbolName in defaultHooks;

    if (symbol) return *symbol;

    return &undefinedSymbol;
}

class LoaderException: Exception {
    this(string message, string file = __FILE__, size_t line = __LINE__) {
        super("Cannot load library: " ~ message, file, line);
    }
}

class UndefinedSymbolException: Exception {
    this(string file = __FILE__, size_t line = __LINE__) {
        super("An undefined symbol has been called!", file, line);
    }
}
