module provision.android.requestcontext;

import provision.android.ndkstring;
import provision.android.filepath;
import provision.android.storeerrorcondition;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;
import ssoulaimane.stdcpp.vector;

@AndroidClassInfo("libandroidappmusic", 392) class RequestContext : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementDestructor!"_ZN17storeservicescore14RequestContextD2Ev";
    mixin implementConstructor!(void function(), "_ZN17storeservicescore14RequestContextC2Ev");
    mixin implementConstructor!(void function(ref const(NdkString)), "_ZN17storeservicescore14RequestContextC2ERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    mixin implementMethod!(StoreErrorCondition function(ref const(shared_ptr!void)), "init", "_ZN17storeservicescore14RequestContext4initERKNSt6__ndk110shared_ptrINS_20RequestContextConfigEEE");
}
