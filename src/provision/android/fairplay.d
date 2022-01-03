module provision.android.fairplay;

import provision.androidclass;
import provision.android.requestcontext;

extern(C++, class) extern(C++, storeservicescore) struct FairPlay {
    mixin AndroidClass!FairPlay;
}
