module provision.android.protocolaction;

import provision.androidclass;
import provision.android.requestcontext;
import provision.glue;

extern(C++, class) extern(C++, storeservicescore) struct ProtocolAction {
    mixin AndroidClass!ProtocolAction;

    ref NdkString actionType() const;
    void performWithContext(ref const shared_ptr!RequestContext) const;
}
