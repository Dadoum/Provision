module provision.android.filepath;

import provision.android.ndkstring;
import provision.android.storeerrorcondition;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo("libandroidappmusic", 120) class FilePath : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementDestructor!"_ZN13mediaplatform8FilePathD2Ev";
    mixin implementConstructor!(void function(ref const(NdkString)), "_ZN13mediaplatform8FilePathC2ERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    
}
