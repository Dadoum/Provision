module std_edit.linux_stat;

import core.stdc.stdint;

static if ( (void*).sizeof > int.sizeof )
{
    enum __c_longlong  : long;
    enum __c_ulonglong : ulong;

    alias long  c_long;
    alias ulong c_ulong;

    alias long   cpp_long;
    alias ulong  cpp_ulong;

    alias __c_longlong  cpp_longlong;
    alias __c_ulonglong cpp_ulonglong;
}
else
{
    enum __c_long  : int;
    enum __c_ulong : uint;

    alias int   c_long;
    alias uint  c_ulong;

    alias __c_long   cpp_long;
    alias __c_ulong  cpp_ulong;

    alias long  cpp_longlong;
    alias ulong cpp_ulonglong;
}

alias c_long slong_t;
alias c_ulong ulong_t;

alias slong_t   linux_time_t;

enum _XOPEN_SOURCE     = 600;
enum _DEFAULT_SOURCE     = false;
enum __USE_FILE_OFFSET64     = true;

struct timespec
{
    linux_time_t  tv_sec;
    c_long  tv_nsec;
}

static if ( __USE_FILE_OFFSET64 )
{
    alias long      blkcnt_t;
    alias ulong     ino_t;
    alias long      off_t;
}
else
{
    alias slong_t   blkcnt_t;
    alias ulong_t   ino_t;
    alias slong_t   off_t;
}
alias slong_t   blksize_t;
alias ulong     dev_t;
alias uint      gid_t;
alias uint      mode_t;
alias ulong_t   nlink_t;
alias int       pid_t;
//size_t (defined in core.stdc.stddef)
alias c_long    ssize_t;
alias uint      uid_t;

version (X86)
{
    struct stat_linux_t
    {
        dev_t       st_dev;
        ushort      __pad1;
        static if (!__USE_FILE_OFFSET64)
        {
            ino_t       st_ino;
        }
        else
        {
            uint        __st_ino;
        }
        mode_t      st_mode;
        nlink_t     st_nlink;
        uid_t       st_uid;
        gid_t       st_gid;
        dev_t       st_rdev;
        ushort      __pad2;
        off_t       st_size;
        blksize_t   st_blksize;
        blkcnt_t    st_blocks;
        static if (_DEFAULT_SOURCE || _XOPEN_SOURCE >= 700)
        {
            timespec    st_atim;
            timespec    st_mtim;
            timespec    st_ctim;
            extern(D) @safe @property inout pure nothrow
            {
                ref inout(linux_time_t) st_atime() return { return st_atim.tv_sec; }
                ref inout(linux_time_t) st_mtime() return { return st_mtim.tv_sec; }
                ref inout(linux_time_t) st_ctime() return { return st_ctim.tv_sec; }
            }
        }
        else
        {
            linux_time_t      st_atime;
            ulong_t     st_atimensec;
            linux_time_t      st_mtime;
            ulong_t     st_mtimensec;
            linux_time_t      st_ctime;
            ulong_t     st_ctimensec;
        }
        static if (__USE_FILE_OFFSET64)
        {
            ino_t       st_ino;
        }
        else
        {
            c_ulong     __unused4;
            c_ulong     __unused5;
        }
    }
}
else version (X86_64)
{
    struct stat_linux_t {
        ulong st_dev;
        ulong st_ino;
        ulong st_nlink;
        uint st_mode;
        uint st_uid;
        uint st_gid;
        uint __pad0;
        ulong st_rdev;
        long st_size;
        long st_blksize;
        long st_blocks;
        long st_atime;
        long st_atimensec;
        long st_mtime;
        long st_mtimensec;
        long st_ctime;
        long st_ctimensec;
        long[3] __unused;
    }

    struct stat_linux_t_new
    {
        dev_t       st_dev;
        ino_t       st_ino;
        nlink_t     st_nlink;
        mode_t      st_mode;
        uid_t       st_uid;
        gid_t       st_gid;
        uint        __pad0;
        dev_t       st_rdev;
        off_t       st_size;
        blksize_t   st_blksize;
        blkcnt_t    st_blocks;
        static if (_DEFAULT_SOURCE || _XOPEN_SOURCE >= 700)
        {
            timespec    st_atim;
            timespec    st_mtim;
            timespec    st_ctim;
            extern(D) @safe @property inout pure nothrow
            {
                ref inout(linux_time_t) st_atime() return { return st_atim.tv_sec; }
                ref inout(linux_time_t) st_mtime() return { return st_mtim.tv_sec; }
                ref inout(linux_time_t) st_ctime() return { return st_ctim.tv_sec; }
            }
        }
        else
        {
            linux_time_t      st_atime;
            ulong_t     st_atimensec;
            linux_time_t      st_mtime;
            ulong_t     st_mtimensec;
            linux_time_t      st_ctime;
            ulong_t     st_ctimensec;
        }
        slong_t[3]     __unused;
    }
}
else version (ARM)
{
    private
    {
        alias __dev_t = ulong;
        alias __ino_t = c_ulong;
        alias __ino64_t = ulong;
        alias __mode_t = uint;
        alias __nlink_t = size_t;
        alias __uid_t = uint;
        alias __gid_t = uint;
        alias __off_t = c_long;
        alias __off64_t = long;
        alias __blksize_t = c_long;
        alias __blkcnt_t = c_long;
        alias __blkcnt64_t = long;
        alias __timespec = timespec;
        alias __linux_time_t = linux_time_t;
    }
    struct stat_linux_t
    {
        __dev_t st_dev;
        ushort __pad1;

        static if (!__USE_FILE_OFFSET64)
        {
            __ino_t st_ino;
        }
        else
        {
            __ino_t __st_ino;
        }
        __mode_t st_mode;
        __nlink_t st_nlink;
        __uid_t st_uid;
        __gid_t st_gid;
        __dev_t st_rdev;
        ushort __pad2;

        static if (!__USE_FILE_OFFSET64)
        {
            __off_t st_size;
        }
        else
        {
            __off64_t st_size;
        }
        __blksize_t st_blksize;

        static if (!__USE_FILE_OFFSET64)
        {
            __blkcnt_t st_blocks;
        }
        else
        {
            __blkcnt64_t st_blocks;
        }

        static if ( _DEFAULT_SOURCE || _XOPEN_SOURCE >= 700)
        {
            __timespec st_atim;
            __timespec st_mtim;
            __timespec st_ctim;
            extern(D) @safe @property inout pure nothrow
            {
                ref inout(linux_time_t) st_atime() return { return st_atim.tv_sec; }
                ref inout(linux_time_t) st_mtime() return { return st_mtim.tv_sec; }
                ref inout(linux_time_t) st_ctime() return { return st_ctim.tv_sec; }
            }
        }
        else
        {
            __linux_time_t st_atime;
            c_ulong st_atimensec;
            __linux_time_t st_mtime;
            c_ulong st_mtimensec;
            __linux_time_t st_ctime;
            c_ulong st_ctimensec;
        }

        static if (!__USE_FILE_OFFSET64)
        {
            c_ulong __unused4;
            c_ulong __unused5;
        }
        else
        {
            __ino64_t st_ino;
        }
    }
    static if (__USE_FILE_OFFSET64)
        static assert(stat_linux_t.sizeof == 104);
    else
        static assert(stat_linux_t.sizeof == 88);
}
else version (AArch64)
{
    private
    {
        alias __dev_t = ulong;
        alias __ino_t = c_ulong;
        alias __ino64_t = ulong;
        alias __mode_t = uint;
        alias __nlink_t = uint;
        alias __uid_t = uint;
        alias __gid_t = uint;
        alias __off_t = c_long;
        alias __off64_t = long;
        alias __blksize_t = int;
        alias __blkcnt_t = c_long;
        alias __blkcnt64_t = long;
        alias __timespec = timespec;
        alias __linux_time_t = linux_time_t;
    }
    struct stat_linux_t
    {
        __dev_t st_dev;

        static if (!__USE_FILE_OFFSET64)
        {
            __ino_t st_ino;
        }
        else
        {
            __ino64_t st_ino;
        }
        __mode_t st_mode;
        __nlink_t st_nlink;
        __uid_t st_uid;
        __gid_t st_gid;
        __dev_t st_rdev;
        __dev_t __pad1;

        static if (!__USE_FILE_OFFSET64)
        {
            __off_t st_size;
        }
        else
        {
            __off64_t st_size;
        }
        __blksize_t st_blksize;
        int __pad2;

        static if (!__USE_FILE_OFFSET64)
        {
            __blkcnt_t st_blocks;
        }
        else
        {
            __blkcnt64_t st_blocks;
        }

        static if (_DEFAULT_SOURCE)
        {
            __timespec st_atim;
            __timespec st_mtim;
            __timespec st_ctim;
            extern(D) @safe @property inout pure nothrow
            {
                ref inout(linux_time_t) st_atime() return { return st_atim.tv_sec; }
                ref inout(linux_time_t) st_mtime() return { return st_mtim.tv_sec; }
                ref inout(linux_time_t) st_ctime() return { return st_ctim.tv_sec; }
            }
        }
        else
        {
            __linux_time_t st_atime;
            c_ulong st_atimensec;
            __linux_time_t st_mtime;
            c_ulong st_mtimensec;
            __linux_time_t st_ctime;
            c_ulong st_ctimensec;
        }
        int[2] __unused;
    }
    version (D_LP64)
        static assert(stat_linux_t.sizeof == 128);
    else
        static assert(stat_linux_t.sizeof == 104);
}