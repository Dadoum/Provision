module provision.android.foothillconfig;

import provision.android.ndkstring;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo("libandroidappmusic", 392) class FootHillConfig : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementMethod!(int function(ref const(NdkString)), "config",
            "_ZN14FootHillConfig6configERKNSt6__ndk112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEE",
            ["static"]);
}
