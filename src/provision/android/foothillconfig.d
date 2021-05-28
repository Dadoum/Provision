module provision.android.foothillconfig;

import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo("libandroidappmusic", 392) class FootHillConfig : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementMethod!(void function(ref const(basic_string!char)), "config",
            "_ZN14FootHillConfig6configERKNSt6__ndk112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE",
            ["static"]);
}
