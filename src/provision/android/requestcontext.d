module provision.android.requestcontext;

import provision.glue;
import provision.android.requestcontextconfig;
import provision.android.fairplay;
import provision.android.filepath;
import provision.android.contentbundle;
import provision.android.storeerrorcondition;
import provision.android.androidpresentationinterface;
import provision.android.androidrequestcontextobserver;
import provision.android.mescal;
import provision.android.httpproxy;
import provision.androidclass;

extern(C++, class) extern(C++, storeservicescore) struct RequestContext {
    mixin AndroidClass!RequestContext;
    ~this();

    this(ref const(NdkString));
    @MangledName("_ZN17storeservicescore14RequestContext4initERKNSt6__ndk110shared_ptrINS_20RequestContextConfigEEE")
    StoreErrorCondition initialize(ref const(shared_ptr!RequestContextConfig));
    long preferredAccountDSID();


    @MangledName("_ZNSt6__ndk110shared_ptrIN17storeservicescore14RequestContextEE11make_sharedIJRNS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEEEES3_DpOT_")
    static shared_ptr!RequestContext makeShared(ref NdkString);

    @MangledName("_ZN17storeservicescore14RequestContext24setPresentationInterfaceERKNSt6__ndk110shared_ptrINS_21PresentationInterfaceEEE")
    void setPresentationInterface(ref const shared_ptr!AndroidPresentationInterface);
    StoreErrorCondition getAuthHeader(ref const(NdkString));
    ref shared_ptr!Mescal mescal();
    ref shared_ptr!FairPlay fairPlay();
    ref NdkString deviceIdentifier();
    ref NdkString languageIdentifier() const;
    bool isAccountSubscribed();
}
