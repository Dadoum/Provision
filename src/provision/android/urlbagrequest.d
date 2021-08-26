module provision.android.urlbagrequest;

import provision.glue;
import provision.android.requestcontext;
import provision.androidclass;

enum URLBagCacheOption: int {
    none = 0,
    allowsExpiredBag = 1,
    ignoresCache = 2
}

@AndroidClassInfo(Library.LIBSTORESERVICESCORE, 392) class URLBagRequest : AndroidClass {
    mixin implementDefaultConstructor;
    mixin implementDestructor!"_ZN17storeservicescore13URLBagRequestD2Ev";
    mixin implementConstructor!(void function(shared_ptr!RequestContext),
            "_ZN17storeservicescore13URLBagRequestC2ENSt6__ndk110shared_ptrINS_14RequestContextEEE");

    mixin implementMethod!(void function(URLBagCacheOption), "setCacheOptions",
            "_ZN17storeservicescore13URLBagRequest15setCacheOptionsENS_18URLBagCacheOptionsE");
    mixin implementMethod!(void function(), "run", "_ZN17storeservicescore13URLBagRequest3runEv");
}
