module provision.android.androidpresentationinterface;

import provision.android.androidcredentialsresponsehandler;
import provision.android.androidprotocoldialogresponsehandler;
import provision.android.credentialrequest;
import provision.android.protocoldialog;
import provision.androidclass;
import provision.glue;

extern(C++, class) extern(C++, androidstoreservices) struct AndroidPresentationInterface {
    mixin AndroidClass!AndroidPresentationInterface;
    @MangledName("_ZNSt6__ndk110shared_ptrIN20androidstoreservices28AndroidPresentationInterfaceEE11make_sharedIJEEES3_DpOT_")
    static shared_ptr!AndroidPresentationInterface makeShared();

    void setDialogHandler(void function(long, shared_ptr!ProtocolDialog, shared_ptr!AndroidProtocolDialogResponseHandler) var1);
    void setCredentialsHandler(void function(shared_ptr!CredentialsRequest, shared_ptr!AndroidCredentialsResponseHandler) var1);
}