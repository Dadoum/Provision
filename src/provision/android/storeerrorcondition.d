module provision.android.storeerrorcondition;

import provision.android.ndkstring;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo("libstoreservicescore", 208) class StoreErrorCondition : AndroidClass
{
    mixin implementDefaultConstructor;

    mixin implementMethod!(StoreErrorCondition function(ref const(NdkString) androidId,
            ref const(NdkString) oldGuidStr, ref const(uint) sdkVersion,
            ref const(bool) hasFairplay), "configure", "_ZN17storeservicescore10DeviceGUID9configureERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES9_RKjRKb",
            );
}
