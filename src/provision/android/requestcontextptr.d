module provision.android.requestcontextptr;

import provision.android.filepath;
import provision.android.storeerrorcondition;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;
import ssoulaimane.stdcpp.vector;

@AndroidClassInfo("libandroidappmusic", 0) class RequestContextPtr : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementMethod!(shared_ptr!void function(ref shared_ptr!void, ref basic_string!char), "make_shared_ptr", "_ZNSt6__ndk110shared_ptrIN17storeservicescore14RequestContextEE11make_sharedIJRNS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEEEES3_DpOT_", ["static"]);
}

