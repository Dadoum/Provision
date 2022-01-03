module provision.android.defaultstoreclient;

import provision.androidclass;
import provision.android.requestcontext;

extern(C++, class) extern(C++, storeservices) struct DefaultStoreClient {
    mixin AndroidClass!DefaultStoreClient;
    this(ref const(shared_ptr!RequestContext));

    static DefaultStoreClient make(ref const(shared_ptr!RequestContext));
    const(NdkString) getAnisetteRequestMachineId();

    bool renewAuthToken();
}
