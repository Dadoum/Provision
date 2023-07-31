module provision.compat.macos;

version(OSX):

import core.stdc.errno;
import core.stdc.stdlib;
import core.stdc.string;
import core.sys.posix.fcntl;
import core.sys.posix.sys.stat;
import core.sys.posix.sys.time;
import core.sys.posix.unistd;

import provision.compat.general;

template traceCall(alias U) {
    import std.traits;
    import slf4d;
    extern(C) auto ref traceCall(Parameters!U params) @sysv {
        getLogger().traceF!"CALL // %s"(__traits(identifier, U));
        return U(params);
    }
}

extern(C) ref int __errno_location_hook() @sysv {
    import slf4d;
    getLogger().traceF!"CALL // errno: %d"(errno());
    errno = 0;
    return errno();
}

alias __errno_location = traceCall!(__errno_location_hook);
alias strncpy = traceCall!(core.stdc.string.strncpy);
alias malloc = core.stdc.stdlib.malloc;
alias free = core.stdc.stdlib.free;
alias gettimeofday = traceCall!(core.sys.posix.sys.time.gettimeofday);
alias close = traceCall!(core.sys.posix.unistd.close);
alias read = traceCall!(core.sys.posix.unistd.read);
alias write = traceCall!(core.sys.posix.unistd.write);
alias mkdir = traceCall!(core.sys.posix.fcntl.mkdir);
alias chmod = traceCall!(core.sys.posix.fcntl.chmod);
alias ftruncate = traceCall!(core.sys.posix.unistd.ftruncate);
alias umask = traceCall!(core.sys.posix.sys.stat.umask);

import std_edit.linux_stat;

extern(C) auto lstat_hooked(const(char)* path, stat_linux_t* out_) @sysv {
    stat_t stat_struc;
    auto ret = core.sys.posix.sys.stat.lstat(path, &stat_struc);
    *out_ = stat_linux_t();
    out_.st_dev = stat_struc.st_dev;
    out_.st_ino = stat_struc.st_ino;
    out_.st_mode = stat_struc.st_mode;
    out_.st_nlink = stat_struc.st_nlink;
    out_.st_uid = stat_struc.st_uid;
    out_.st_gid = stat_struc.st_gid;
    out_.st_rdev = stat_struc.st_rdev;
    out_.st_size = stat_struc.st_size;
    out_.st_blksize = stat_struc.st_blksize;
    out_.st_blocks = stat_struc.st_blocks;
    out_.st_atime = stat_struc.st_atime;
    out_.st_atimensec = stat_struc.st_atimensec;
    out_.st_mtime = stat_struc.st_mtime;
    out_.st_mtimensec = stat_struc.st_mtimensec;
    out_.st_ctime = stat_struc.st_ctime;
    out_.st_ctimensec = stat_struc.st_ctimensec;
    out_.st_ino = stat_struc.st_ino;
    return ret;
}
alias lstat = traceCall!lstat_hooked;

extern(C) auto fstat_hooked(int fd, stat_linux_t* out_) @sysv {
    stat_t stat_struc;
    auto ret = core.sys.posix.sys.stat.fstat(fd, &stat_struc);
    *out_ = stat_linux_t();
    out_.st_dev = stat_struc.st_dev;
    out_.st_ino = stat_struc.st_ino;
    out_.st_mode = stat_struc.st_mode;
    out_.st_nlink = stat_struc.st_nlink;
    out_.st_uid = stat_struc.st_uid;
    out_.st_gid = stat_struc.st_gid;
    out_.st_rdev = stat_struc.st_rdev;
    out_.st_size = stat_struc.st_size;
    out_.st_blksize = stat_struc.st_blksize;
    out_.st_blocks = stat_struc.st_blocks;
    out_.st_atime = stat_struc.st_atime;
    out_.st_atimensec = stat_struc.st_atimensec;
    out_.st_mtime = stat_struc.st_mtime;
    out_.st_mtimensec = stat_struc.st_mtimensec;
    out_.st_ctime = stat_struc.st_ctime;
    out_.st_ctimensec = stat_struc.st_ctimensec;
    out_.st_ino = stat_struc.st_ino;
    return ret;
}
alias fstat = traceCall!fstat_hooked;

extern(C) int open_hooked(const(char)* path, int oflag) @sysv {
    import std.conv: octal;
    int flag = 0;

    if (oflag & octal!100) {
        flag |= O_CREAT;
    }

    if (oflag & octal!1) {
        flag |= O_WRONLY;
    } else if (oflag & octal!2) {
        flag |= O_RDWR;
    } else {
        flag |= O_RDONLY;
    }

    return core.sys.posix.fcntl.open(path, flag);
}
alias open = traceCall!(open_hooked);
