module provision.android.requestcontext;

import provision.glue;
import provision.android.ndkstring;
import provision.android.requestcontextconfig;
import provision.android.filepath;
import provision.android.contentbundle;
import provision.android.storeerrorcondition;
import provision.android.androidrequestcontextobserver;
import provision.android.httpproxy;
import provision.androidclass;

@AndroidClassInfo(Library.LIBANDROIDAPPMUSIC, 392) class RequestContext : AndroidClass {
    mixin implementDefaultConstructor;
    mixin implementDestructor!"_ZN17storeservicescore14RequestContextD2Ev";
    mixin implementConstructor!(void function(), "_ZN17storeservicescore14RequestContextC2Ev");
    mixin implementConstructor!(void function(string),
            "_ZN17storeservicescore14RequestContextC2ERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    mixin implementMethod!(StoreErrorCondition function(RequestContext, ref const(shared_ptr!RequestContextConfig)), "initialize",
            "_ZN17storeservicescore14RequestContext4initERKNSt6__ndk110shared_ptrINS_20RequestContextConfigEEE");

    mixin implementMethod!(StoreErrorCondition function(/+RequestContext, +/string), "getAuthHeader",
            "_ZN17storeservicescore14RequestContext13getAuthHeaderERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(shared_ptr!RequestContext function(string), "makeShared", "_ZNSt6__ndk110shared_ptrIN17storeservicescore14RequestContextEE11make_sharedIJRNS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEEEES3_DpOT_",
            ["static"]);

    mixin implementMethod!(void function(), "fairPlay",
            "_ZN17storeservicescore14RequestContext8fairPlayEv");
}
