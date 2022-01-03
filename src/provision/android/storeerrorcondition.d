module provision.android.storeerrorcondition;

import provision.androidclass;
import core.stdc.stdint;

extern(C++, class) extern(C++, storeservicescore) struct StoreErrorCondition {
    mixin AndroidClass!StoreErrorCondition;
    ref NdkString errorDescription() const;
    ref ErrorCode errorCode() const;
}

enum ErrorCode: int {
    success = 0,
    unknown = 1,
    canceled = 2,
    new_account = 3,
    bad_requestctx = 4,
    missing_account = 5,
    platform_denied = 6,
    simulator_denied = 7,
    bad_urlbag = 8,
    mediaplatform_error = 9,
    itunes_error = 10,
    fairplay_error = 100,
    fairplay_guid_error = 101,
    fairplay_import_error = 102,
    fairplay_unknown_error = 103,
}
