module provision.android.defaultstoreclient;

import provision.androidclass;
import provision.android.requestcontext;

@AndroidClassInfo(Library.LIBANDROIDAPPMUSIC, 0) class DefaultStoreClient: AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementMethod!(shared_ptr!DefaultStoreClient function(shared_ptr!RequestContext), "make", "_ZN13storeservices18DefaultStoreClient4makeERKNSt6__ndk110shared_ptrIN17storeservicescore14RequestContextEEE", ["static"]);
    mixin implementMethod!(string function(), "getAnisetteRequestMachineId", "_ZN13storeservices18DefaultStoreClient27getAnisetteRequestMachineIdEv");
}
