module provision.android.requestcontextconfig;

import provision.glue;
import provision.android.androidrequestcontextobserver;
import provision.android.contentbundle;
import provision.androidclass;
import provision.androidlibrary;
import provision.librarybundle;
import std.typecons;
import core.stdc.stdlib;
import provision.android.httpproxy;
import std.traits;

extern(C++, class) extern(C++, storeservicescore) struct RequestContextConfig {
    mixin AndroidClass!RequestContextConfig;
    
    @MangledName("_ZN17storeservicescore20RequestContextConfigC2Ev") @disable this();
    ~this();

    void setBaseDirectoryPath(ref const(NdkString));
    void setFairPlayDirectoryPath(ref const(NdkString));
    void setClientIdentifier(ref const(NdkString));
    void setHTTPProxy(ref const(HTTPProxy));
    void setDeviceModel(ref const(NdkString));
    void setVersionIdentifier(ref const(NdkString));
    void setPlatformIdentifier(ref const(NdkString));
    void setProductVersion(ref const(NdkString));
    void setBuildVersion(ref const(NdkString));
    void setLocaleIdentifier(ref const(NdkString));
    void setLanguageIdentifier(ref const(NdkString));

    void setResetHttpCache(bool);

    @MangledName("_ZN17storeservicescore20RequestContextConfig25setRequestContextObserverERKNSt6__ndk110shared_ptrINS_22RequestContextObserverEEE")
    void setRequestContextObserver(ref const(shared_ptr!AndroidRequestContextObserver));

    void setContentBundle(ref const(shared_ptr!ContentBundle));

    ref const(NdkString) baseDirectoryPath() const;
}
