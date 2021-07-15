module provision.android.defaultstoreclient;

import provision.androidclass;
import provision.android.requestcontext;

@AndroidClassInfo(Library.LIBANDROIDAPPMUSIC, 392) class DefaultStoreClient : AndroidClass {
    mixin implementDefaultConstructor;
    mixin implementConstructor!(void function(ref const(shared_ptr!RequestContext)),
            "_ZN13storeservices18DefaultStoreClientC2ERKNSt6__ndk110shared_ptrIN17storeservicescore14RequestContextEEE");

    mixin implementMethod!(shared_ptr!DefaultStoreClient function(ref shared_ptr!RequestContext), "make",
            "_ZN13storeservices18DefaultStoreClient4makeERKNSt6__ndk110shared_ptrIN17storeservicescore14RequestContextEEE",
            ["static"]);
    static string getAnisetteRequestMachineId(Args...)(Args a) {
        mixin implementMethod!(string function(Args), "getAnisetteRequestMId",
                "_ZN13storeservices18DefaultStoreClient27getAnisetteRequestMachineIdEv", [
                    "static"
                ]);
        return getAnisetteRequestMId(a);
    }

    mixin implementMethod!(bool function(), "renewAuthToken",
            "_ZN13storeservices18DefaultStoreClient14renewAuthTokenEv");
}
