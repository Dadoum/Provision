module provision.android.httpproxy;

import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo("libmediaplatform", 0x60) class HTTPProxy : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementDestructor;

    mixin implementConstructor!(void function(int,
            ref const(basic_string!char) std_string, ref const(ushort) ushort_const_ref), "_ZN13mediaplatform9HTTPProxyC2ENS0_4TypeERKNSt6__ndk112basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEERKt");
}
