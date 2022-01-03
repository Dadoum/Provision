module provision.android.androidrequestcontextobserver;

import provision.android.storeerrorcondition;
import provision.androidclass;

extern(C++, class) extern(C++, storeservicescore) struct AndroidRequestContextObserver {
    mixin AndroidClass!AndroidRequestContextObserver;
    ~this();
}
