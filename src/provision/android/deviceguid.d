module provision.android.deviceguid;

import provision.glue;
import provision.android.data;
import provision.android.storeerrorcondition;
import provision.androidclass;

extern(C++, class) extern(C++, storeservicescore) struct DeviceGUID {
    mixin AndroidClass!DeviceGUID;
    StoreErrorCondition configure(ref const(NdkString) androidId,
        ref const(NdkString) oldGuidStr, ref const(uint) sdkVersion, ref const(bool) hasFairplay);

    static shared_ptr!DeviceGUID instance();
    bool isConfigured();
    shared_ptr!Data guid();
}
