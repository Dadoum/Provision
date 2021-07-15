module provision.utils.segfault;

/** Public domain.
    Traps SIGSEGV and throws an exception, so you should get a stack trace
    when you segfault.
  */
class SegmentationException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }

    this(string file = __FILE__, size_t line = __LINE__) {
        this("Erreur de segmentation: un pointeur incorrect a été déréférencé", file, line);
    }
}

const int SA_SIGINFO = 4;
const int SIGSEGV = 11;

extern (C) {
    struct sig_action {
        // Dunno if a function* would work here...
        void* action;
        int flags;
        void* restorer;
    }

    int sigaction(int signal, sig_action* action, sig_action* oact);
}

void segv_throw(int i) {
    throw new SegmentationException();
}

static this() {
    debug {
    } else {
        sig_action act;
        act.action = &segv_throw;
        act.flags = SA_SIGINFO;
        sigaction(SIGSEGV, &act, null);
    }
}
