module provision.android.mescal;

import provision.glue;
import provision.android.data;
import provision.android.requestcontext;
import provision.androidclass;

extern(C++, class) extern(C++, storeservicescore) struct Mescal {
    mixin AndroidClass!Mescal;
    ~this();
    this(ref const shared_ptr!RequestContext);
    void establishSession();
    void sign(ref const(shared_ptr!Data));
    void sign(ref const(NdkString));
}
