module provision.android.foothillconfig;

import provision.glue;
import provision.android.ndkstring;
import provision.androidclass;

@AndroidClassInfo(Library.LIBANDROIDAPPMUSIC, 392) class FootHillConfig : AndroidClass {
    mixin implementDefaultConstructor;
    mixin implementMethod!(int function(string), "config",
            "_ZN14FootHillConfig6configERKNSt6__ndk112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE",
            ["static"]);
}
