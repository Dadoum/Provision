module provision.compat.macos;

version(OSX):

import core.stdc.errno;
import core.stdc.stdlib;
import core.stdc.string;
import core.sys.posix.fcntl;
import core.sys.posix.sys.stat;
import core.sys.posix.sys.time;
import core.sys.posix.unistd;

template traceCall(alias U) {
    import std.traits;
    import slf4d;
    auto ref traceCall(Parameters!U params) {
        getLogger().traceF!"CALL // %s"(__traits(identifier, U));
        return U(params);
    }
}

alias __errno_location = traceCall!(errno);
alias strncpy = traceCall!(core.stdc.string.strncpy);
alias lstat = traceCall!(core.sys.posix.sys.stat.lstat);
alias fstat = traceCall!(core.sys.posix.sys.stat.fstat);
alias malloc = core.stdc.stdlib.malloc;
alias free = core.stdc.stdlib.free;
alias gettimeofday = traceCall!(core.sys.posix.sys.time.gettimeofday);
alias open = traceCall!(core.sys.posix.fcntl.open);
alias close = traceCall!(core.sys.posix.unistd.close);
alias read = traceCall!(core.sys.posix.unistd.read);
alias write = traceCall!(core.sys.posix.unistd.write);
alias mkdir = traceCall!(core.sys.posix.fcntl.mkdir);
alias chmod = traceCall!(core.sys.posix.fcntl.chmod);
alias ftruncate = traceCall!(core.sys.posix.unistd.ftruncate);
alias umask = traceCall!(core.sys.posix.sys.stat.umask);
