module provision.android.androidprotocoldialogresponsehandler;

import provision.androidclass;
import provision.android.protocoldialogresponse;
import provision.glue;

extern(C++, class) extern(C++, androidstoreservices) struct AndroidProtocolDialogResponseHandler {
    mixin AndroidClass!AndroidProtocolDialogResponseHandler;

    void handleProtocolDialogResponse(long, shared_ptr!ProtocolDialogResponse);
}