module provision.android.credentialrequest;

import provision.androidclass;
import provision.glue;
import provision.android.requestcontext;
import provision.android.protocolaction;
import provision.android.protocoldialog;

extern(C++, class) extern(C++, storeservicescore) struct CredentialsRequest {
    mixin AndroidClass!CredentialsRequest;

    ref NdkString                   cancelButtonTitle() const;
    shared_ptr!RequestContext       context() const;
    ref NdkString                   initialPassword() const;
    ref NdkString                   initialUserName() const;
    ref NdkString                   message() const;
    ref shared_ptr!ProtocolAction   okButtonAction() const;
    ref NdkString                   okButtonTitle() const;
    ref NdkString                   title() const;
    bool                            requiresHSA2VerificationCode() const;
    shared_ptr!ProtocolDialog       dialog() const;
}