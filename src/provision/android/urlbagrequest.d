module provision.android.urlbagrequest;

import provision.glue;
import provision.android.requestcontext;
import provision.androidclass;

enum URLBagCacheOption: int {
    none = 0,
    allowsExpiredBag = 1,
    ignoresCache = 2
}

extern(C++, class) extern(C++, storeservicescore) struct URLBagRequest {
    mixin AndroidClass!URLBagRequest;
    ~this();
    this(shared_ptr!RequestContext);

    void setCacheOptions(URLBagCacheOption);
    void run();
}
