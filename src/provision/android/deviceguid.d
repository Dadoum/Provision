module provision.android.deviceguid;

import provision.glue;
import provision.android.data;
import provision.android.ndkstring;
import provision.android.storeerrorcondition;
import provision.androidclass;

@AndroidClassInfo(Library.LIBSTORESERVICESCORE, 392) class DeviceGUID : AndroidClass {
    mixin implementDefaultConstructor;

    mixin implementMethod!(StoreErrorCondition function(string androidId,
            string oldGuidStr, ref const(uint) sdkVersion, ref const(bool) hasFairplay), "configure", "_ZN17storeservicescore10DeviceGUID9configureERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES9_RKjRKb");

    mixin implementMethod!(shared_ptr!DeviceGUID function(), "instance",
            "_ZN17storeservicescore10DeviceGUID8instanceEv", ["static"]);
    mixin implementMethod!(bool function(), "isConfigured",
            "_ZN17storeservicescore10DeviceGUID12isConfiguredEv");
    mixin implementMethod!(shared_ptr!Data function(), "guid",
            "_ZN17storeservicescore10DeviceGUID4guidEv");
}
