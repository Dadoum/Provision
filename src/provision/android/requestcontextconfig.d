module provision.android.requestcontextconfig;

import provision.androidclass;
import provision.androidlibrary;
import provision.librarybundle;
import std.typecons;
import core.stdcpp.allocator;
import core.stdcpp.string;
import core.stdc.stdlib;
import provision.android.httpproxy;
import std.traits;

ref const(basic_string!char) mathox1Music();

@AndroidClassInfo("libandroidappmusic", 392) class RequestContextConfig : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementConstructor!(void function(), "_ZN17storeservicescore20RequestContextConfigC2Ev");

    mixin implementDestructor!"_ZN17storeservicescore20RequestContextConfigD2Ev";

    mixin implementMethod!(void function(ref const(basic_string!char)), "setBaseDirectoryPath", "_ZN17storeservicescore20RequestContextConfig20setBaseDirectoryPathERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    
//     public static ref const(basic_string!char) baseDirectoryPath(void* handle) {
//     	import app;
// 		auto del = bundle["libandroidappmusic"].loadSymbol!(typeof(&baseDirectoryPath))("_ZNK17storeservicescore20RequestContextConfig17baseDirectoryPathEv");
//     	return del(handle);
//     }
	alias baseDirectoryPath_type = typeof(&mathox1Music);
    mixin implementMethod!(baseDirectoryPath_type, "baseDirectoryPath", "_ZNK17storeservicescore20RequestContextConfig17baseDirectoryPathEv");
    
    mixin implementMethod!(void function(ref const(basic_string!char)), "setFairPlayDirectoryPath", "_ZN17storeservicescore20RequestContextConfig24setFairPlayDirectoryPathERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    
    mixin implementMethod!(void function(ref const(basic_string!char)), "setClientIdentifier", "_ZN17storeservicescore20RequestContextConfig19setClientIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(HTTPProxy)), "setHTTPProxy",
            "_ZN17storeservicescore20RequestContextConfig12setHTTPProxyERKN13mediaplatform9HTTPProxyE");

    mixin implementMethod!(void function(ref const(basic_string!char)), "setDeviceModel", "_ZN17storeservicescore20RequestContextConfig14setDeviceModelERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(basic_string!char)), "setVersionIdentifier", "_ZN17storeservicescore20RequestContextConfig20setVersionIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(basic_string!char)), "setPlatformIdentifier", "_ZN17storeservicescore20RequestContextConfig21setPlatformIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(basic_string!char)), "setProductVersion", "_ZN17storeservicescore20RequestContextConfig17setProductVersionERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(basic_string!char)), "setBuildVersion", "_ZN17storeservicescore20RequestContextConfig15setBuildVersionERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(basic_string!char)), "setLocaleIdentifier", "_ZN17storeservicescore20RequestContextConfig19setLocaleIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(basic_string!char)), "setLanguageIdentifier", "_ZN17storeservicescore20RequestContextConfig21setLanguageIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    
    mixin implementMethod!(void function(bool), "setResetHttpCache", "_ZN17storeservicescore20RequestContextConfig17setResetHttpCacheEb");
    
    mixin implementMethod!(void function(ref const(shared_ptr!void)), "setRequestContextObserver", "_ZN17storeservicescore20RequestContextConfig25setRequestContextObserverERKNSt6__ndk110shared_ptrINS_22RequestContextObserverEEE");
    
    mixin implementMethod!(void function(ref const(shared_ptr!void)), "setContentBundle", "_ZN17storeservicescore20RequestContextConfig16setContentBundleERKNSt6__ndk110shared_ptrIN13mediaplatform13ContentBundleEEE");
}
