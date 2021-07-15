module provision.android.mescal;

import provision.glue;
import provision.android.requestcontext;
import provision.androidclass;

@AndroidClassInfo(Library.LIBSTORESERVICESCORE, 392) class Mescal : AndroidClass {
    mixin implementDefaultConstructor;
    mixin implementDestructor!"_ZN17storeservicescore6MescalD2Ev";
    mixin implementConstructor!(void function(ref shared_ptr!RequestContext),
            "_ZN17storeservicescore6MescalC2ERKNSt6__ndk110shared_ptrINS_14RequestContextEEE");
    mixin implementMethod!(void function(), "establishSession",
            "_ZN17storeservicescore6Mescal16establishSessionEv");
    mixin implementMethod!(void function(string), "sign",
            "_ZN17storeservicescore6Mescal4signERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
}
