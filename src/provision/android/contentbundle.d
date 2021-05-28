module provision.android.contentbundle;

import provision.android.filepath;
import provision.android.storeerrorcondition;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;
import ssoulaimane.stdcpp.vector;

@AndroidClassInfo("libandroidappmusic", 0x90) class ContentBundle : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementDestructor!"_ZN13mediaplatform13ContentBundleD2Ev";
    mixin implementConstructor!(void function(ref const(FilePath), ref const(FilePath), ref const(FilePath), ref const(vector!(basic_string!char))), "_ZN13mediaplatform13ContentBundleC2ERKNS_8FilePathES3_S3_RKNSt6__ndk16vectorINS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEENS9_ISB_EEEE");
}
