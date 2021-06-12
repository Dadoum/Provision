module provision.android.ndkstring;

import std.string;
import provision.android.storeerrorcondition;
import provision.androidclass;
import core.stdcpp.allocator;
import core.stdcpp.string;

@AndroidClassInfo("libandroidappmusic", 392) class NdkString : AndroidClass
{
	alias CCharPointer = extern(C) const(char)*;
    mixin implementDefaultConstructor;
    mixin implementConstructor!(void function(CCharPointer), "_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC2IDnEEPKc");
    mixin implementDestructor!"_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED2Ev";
    mixin ndkStringCtorWorkaround;
}

mixin template ndkStringCtorWorkaround() 
{
    this(string s)
    {
    	this(s.toStringz());
    }
}
