module provision.android.foothillconfig;

import provision.glue;
import provision.androidclass;

extern(C++, class) struct FootHillConfig {
    mixin AndroidClass!FootHillConfig;
    static int config(ref const(NdkString));
}
