module provision.android.storeerrorcondition;

import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo("libstoreservicescore", 208) class StoreErrorCondition : AndroidClass
{
    mixin implementDefaultConstructor;

    mixin implementMethod!(StoreErrorCondition function(ref const(basic_string!char) androidId,
            ref const(basic_string!char) oldGuidStr, ref const(uint) sdkVersion,
            ref const(bool) hasFairplay), "configure", "_ZN17storeservicescore10DeviceGUID9configureERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES9_RKjRKb",
            );

    mixin implementMethod!(shared_ptr!void function(), "instance",
            "_ZN17storeservicescore10DeviceGUID8instanceEv", ["static"]);
    mixin implementMethod!(bool function(), "isConfigured",
            "_ZN17storeservicescore10DeviceGUID12isConfiguredEv");
}
