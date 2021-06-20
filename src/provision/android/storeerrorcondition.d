module provision.android.storeerrorcondition;

import provision.android.ndkstring;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo(Library.LIBSTORESERVICESCORE, 208) class StoreErrorCondition : AndroidClass
{
    mixin implementDefaultConstructor;

    mixin implementMethod!(string function(), "errorDescription", "_ZNK17storeservicescore19StoreErrorCondition16errorDescriptionEv");
    mixin implementMethod!(Ref!(ErrorCode function()), "errorCode", "_ZNK17storeservicescore19StoreErrorCondition9errorCodeEv");
}

enum ErrorCode: int {
    SUCCESS = 0,
    UNKNOWN = 1,
    CANCELED = 2,
    NEW_ACCOUNT = 3,
    BAD_REQUESTCTX = 4,
    MISSING_ACCOUNT = 5,
    PLATFORM_DENIED = 6,
    SIMULATOR_DENIED = 7,
    BAD_URLBAG = 8,
    MEDIAPLATFORM_ERROR = 9,
    ITUNES_ERROR = 10,
    FAIRPLAY_ERROR = 100,
    FAIRPLAY_GUID_ERROR = 101,
    FAIRPLAY_IMPORT_ERROR = 102,
    FAIRPLAY_UNKNOWN_ERROR = 103,
}
