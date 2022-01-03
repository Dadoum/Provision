module provision.android.authenticateflow;

import provision.androidclass;
import provision.android.requestcontext;
import provision.glue;

extern(C++, class) extern(C++, storeservicescore) struct AuthenticateFlow {
    mixin AndroidClass!AuthenticateFlow;

    this(ref const(shared_ptr!RequestContext));
    void run();

    void runWithTimeout(std_duration);
    void _authenticateUsingExistingAccount(std_duration);
    void _promptForCredentials();
}
