module provision.android.anisetteprotocolaction;

import provision.glue;
import provision.androidclass;
import provision.android.requestcontext;

enum AnisetteProtocolVersion : int {
    standard = 0,
    anonymous = 1
}

@AndroidClassInfo(Library.LIBANDROIDAPPMUSIC, 0x90) class AnisetteProtocolAction : AndroidClass {
    mixin implementDefaultConstructor;
    mixin implementMethod!(Ref!(AnisetteProtocolAction function(StringStringMultimap* multimap,
            AnisetteProtocolVersion protocolVersion)), "actionForHeaders", "_ZN17storeservicescore22AnisetteProtocolAction16actionForHeadersERKNSt6__ndk18multimapINS1_12basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEES8_N13mediaplatform16HeaderComparisonENS6_INS1_4pairIKS8_S8_EEEEEENS_23AnisetteProtocolVersionE");
    mixin implementMethod!(AnisetteProtocolVersion function(), "protocolVersion",
            "_ZNK17storeservicescore22AnisetteProtocolAction15protocolVersionEv");
    mixin implementMethod!(void function(ref const(shared_ptr!RequestContext)), "_provisionWithContext", "_ZNK17storeservicescore22AnisetteProtocolAction21_provisionWithContextERKNSt6__ndk110shared_ptrINS_14RequestContextEEE");
    mixin implementMethod!(void function(ref const(shared_ptr!RequestContext)), "performWithContext", "_ZNK17storeservicescore22AnisetteProtocolAction18performWithContextERKNSt6__ndk110shared_ptrINS_14RequestContextEEE");

}
