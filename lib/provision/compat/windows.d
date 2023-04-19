module provision.compat.windows;

import core.sys.windows.winbase;
import core.sys.windows.winnt;

import provision.compat.general;

extern (C):
@sysv:
version (Windows):

enum PROT_NONE = 0x0;
enum PROT_READ = 0x1;
enum PROT_WRITE = 0x2;
enum PROT_EXEC = 0x4;

pragma(inline, true) uint protectionToWindows(int x) pure {
    final switch (x) {
        case PROT_NONE:
            return PAGE_NOACCESS;
        case PROT_READ:
            return PAGE_READONLY;
        case PROT_WRITE:
            return PAGE_READWRITE;
        case PROT_EXEC:
            return PAGE_EXECUTE;
        case PROT_READ | PROT_WRITE:
            return PAGE_READWRITE;
        case PROT_WRITE | PROT_EXEC:
            return PAGE_EXECUTE_READWRITE;
        case PROT_EXEC | PROT_READ:
            return PAGE_EXECUTE_READ;
        case PROT_READ | PROT_WRITE | PROT_EXEC:
            return PAGE_EXECUTE_READWRITE;
    }
}

void open() {}
void close() {}
void umask() {}
void chmod() {}
void lstat() {}
void ftruncate() {}
void write() {}
void fstat() {}
void gettimeofday() {}
void read() {}
void mkdir() {}
int mprotect(void* ptr, size_t size, int newProtection) {
    uint oldProtection = void;
    return !VirtualProtect(ptr, size, newProtection.protectionToWindows(), &oldProtection);
}
