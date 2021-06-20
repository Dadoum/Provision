module provision.android.requestcontextmanager;

import provision.glue;
import provision.android.filepath;
import provision.android.requestcontext;
import provision.android.storeerrorcondition;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo(Library.LIBANDROIDAPPMUSIC, 0) class RequestContextManager : AndroidClass
{
    mixin implementMethod!(void function(ref const(shared_ptr!RequestContext)), "configure", "_ZN21RequestContextManager9configureERKNSt6__ndk110shared_ptrIN17storeservicescore14RequestContextEEE", ["static"]);
}
