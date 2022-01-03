module provision.android.anisetteprotocolaction;

import provision.glue;
import provision.androidclass;
import provision.android.requestcontext;

extern(C++, storeservicescore) {
    extern(C++, class) struct AnisetteProtocolAction {
        mixin AndroidClass!AnisetteProtocolAction;

        AnisetteProtocolAction* actionForHeaders(ref const(headers_multimap) multimap, AnisetteProtocolVersion protocolVersion);

        AnisetteProtocolVersion protocolVersion() const;
        void _provisionWithContext(ref const(shared_ptr!RequestContext)) const;

        void performWithContext(ref const(shared_ptr!RequestContext)) const;
    }

    enum AnisetteProtocolVersion : int {
        standard = 0,
        anonymous = 1
    }
}
