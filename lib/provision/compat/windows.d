module provision.compat.windows;

version (Windows):

import core.stdc.stdio;
import core.sys.windows.stat;
import core.sys.windows.stdc.time;
import core.sys.windows.winbase;
import core.sys.windows.winnt;

import std.conv;
import std.datetime;
import std.string;

import std_edit.linux_stat;

import slf4d;

import provision.compat.general;

private extern (C) {
    alias mode_t = uint;

    struct timespec {
        time_t tv_sec;
        long tv_nsec;
    }

    size_t _chsize(ulong handle, ulong length);
    pragma(mangle, "mkdir") int _mkdir(const scope char*, mode_t);
    pragma(mangle, "chmod") int _chmod(const scope char*, mode_t);
    int _read(int fd, void* buf, uint count);
    int _write(int fd, void* buf, uint count);
}

struct timeval {
    size_t tv_sec;
    size_t tv_usec;
}

public import core.stdc.errno;
public import core.stdc.stdlib;
public import core.stdc.string;

enum PROT_NONE = 0x0;
enum PROT_READ = 0x1;
enum PROT_WRITE = 0x2;
enum PROT_EXEC = 0x4;

@sysv:

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

void* malloc(size_t size) {
    return core.stdc.stdlib.malloc(size);
}

void free(void* ptr) {
    return core.stdc.stdlib.free(ptr);
}

ref int __errno_location2() {
    getLogger().traceF!"CALL // errno: %d"(errno());
    errno = 0;
    return errno();
}

alias __errno_location = __errno_location2;

char* strncpy(return scope char* s1, scope const char* s2, size_t n) {
    // getLogger().traceF!"CALL // strncpy 0x%x -(%d)-> 0x%x"(s1, /+ s1[0..n],+/ n, s2);
    return core.stdc.string.strncpy(s1, s2, n);
}

size_t umask(size_t s) {
    getLogger().trace("CALL // umask");
    return s;
}

size_t ftruncate(ulong handle, ulong length) {
    getLogger().trace("CALL // ftruncate");
    return _chsize(handle, length);
}

int gettimeofday(timeval* tv, void* tz) {
    getLogger().trace("CALL // gettimeofday");
    auto time = Clock.currTime();
    *tv = timeval(time.toUnixTime(), time.fracSecs.total!"usecs");
    return 0;
}

int chmod(const(char)* path, int mode) {
    getLogger().trace("CALL // chmod");
    return _chmod(path.toWindowsPath(), mode);
}

int mkdir(const(char)* path, int mode) {
    getLogger().trace("CALL // mkdir");
    return _mkdir(path.toWindowsPath(), mode);
}

const(char)* toWindowsPath(const(char)* c) {
    import std.algorithm.iteration;
    import std.array;
    import std.string;
    import std.conv;

    return c.fromStringz()
        .chompPrefix("//?/")
        .map!((c) => (c == '/') ? '\\' : c)
        .array()
        .to!string()
        .toStringz();
}

int open(const(char)* path, int oflag) {
    getLogger().trace("CALL // open");

    int convertedOflag = 0x8000; // Binary mode

    if (oflag & octal!100) {
        convertedOflag |= O_CREAT;
    }

    if (oflag & octal!1) {
        convertedOflag |= O_WRONLY;
    } else if (oflag & octal!2) {
        convertedOflag |= O_RDWR;
    } else {
        convertedOflag |= O_RDONLY;
    }

    return _open(path, convertedOflag);
}

int close(int fd) {
    getLogger().trace("CALL // close");
    return _close(fd);
}

int read(int fd, void* buf, uint count) {
    getLogger().trace("CALL // read");
    return _read(fd, buf, count);
}

int write(int fd, void* buf, uint count) {
    getLogger().trace("CALL // write");
    return _write(fd, buf, count);
}

int fstat(int fd, stat_linux_t* out_) {
    struct_stat stat_struc;
    getLogger().trace("CALL // fstat");
    int ret = core.sys.windows.stat.fstat(fd, &stat_struc);

    uint mode = octal!555;

    if (stat_struc.st_mode & octal!11) {
        mode |= octal!200;
    }

    if (stat_struc.st_mode & octal!4000) {
        mode |= octal!40000;
    }

    auto atime = stat_struc.st_atime / 10000000;
    auto mtime = stat_struc.st_mtime / 10000000;
    auto ctime = stat_struc.st_ctime / 10000000;

    *out_ = stat_linux_t();
    out_.st_dev = stat_struc.st_dev;
    out_.st_ino = stat_struc.st_ino;
    out_.st_mode = mode;
    out_.st_nlink = stat_struc.st_nlink;
    out_.st_uid = stat_struc.st_uid;
    out_.st_gid = stat_struc.st_gid;
    out_.st_rdev = stat_struc.st_rdev;
    out_.st_size = stat_struc.st_size;
    out_.st_atime = atime;
    out_.st_mtime = mtime;
    out_.st_ctime = ctime;
    out_.st_ino = stat_struc.st_ino;

    return ret;
}

int lstat(const(char)* path, stat_linux_t* out_) {
    struct_stat stat_struc;
    getLogger().traceF!"CALL // lstat: %s"(path.toWindowsPath.fromStringz);
    int ret = stat(path.toWindowsPath(), &stat_struc);

    uint mode = octal!555;

    if (stat_struc.st_mode & 0b11) {
        mode |= octal!200;
    }

    if (stat_struc.st_mode & 0x4000) {
        mode |= octal!40000;
    }

    auto atime = stat_struc.st_atime / 10000000;
    auto mtime = stat_struc.st_mtime / 10000000;
    auto ctime = stat_struc.st_ctime / 10000000;

    *out_ = stat_linux_t();
    out_.st_dev = stat_struc.st_dev;
    out_.st_ino = stat_struc.st_ino;
    out_.st_mode = mode;
    out_.st_nlink = stat_struc.st_nlink;
    out_.st_uid = stat_struc.st_uid;
    out_.st_gid = stat_struc.st_gid;
    out_.st_rdev = stat_struc.st_rdev;
    out_.st_size = stat_struc.st_size;
    out_.st_atime = atime;
    out_.st_mtime = mtime;
    out_.st_ctime = ctime;
    out_.st_ino = stat_struc.st_ino;

    return ret;
}

int mprotect(void* ptr, size_t size, int newProtection) {
    uint oldProtection = void;
    return !VirtualProtect(ptr, size, newProtection.protectionToWindows(), &oldProtection);
}
