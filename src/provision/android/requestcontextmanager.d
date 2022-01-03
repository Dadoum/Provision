module provision.android.requestcontextmanager;

import provision.glue;
import provision.android.filepath;
import provision.android.requestcontext;
import provision.android.storeerrorcondition;
import provision.androidclass;

extern(C++, class) struct RequestContextManager {
    mixin AndroidClass!RequestContextManager;
    static void configure(ref const(shared_ptr!RequestContext));
}
