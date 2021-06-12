module provision.android.requestcontextconfig;

import provision.glue;
import provision.android.androidrequestcontextobserver;
import provision.android.contentbundle;
import provision.android.ndkstring;
import provision.androidclass;
import provision.androidlibrary;
import provision.librarybundle;
import std.typecons;
import core.stdcpp.allocator;
import core.stdcpp.string;
import core.stdc.stdlib;
import provision.android.httpproxy;
import std.traits;

@AndroidClassInfo("libandroidappmusic", 392) class RequestContextConfig : AndroidClass
{
    mixin implementDefaultConstructor;
    mixin implementConstructor!(void function(), "_ZN17storeservicescore20RequestContextConfigC2Ev");

    mixin implementDestructor!"_ZN17storeservicescore20RequestContextConfigD2Ev";

    mixin implementMethod!(void function(string), "setBaseDirectoryPath", "_ZN17storeservicescore20RequestContextConfig20setBaseDirectoryPathERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    
    mixin implementMethod!(void function(string), "setFairPlayDirectoryPath", "_ZN17storeservicescore20RequestContextConfig24setFairPlayDirectoryPathERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    
    mixin implementMethod!(void function(string), "setClientIdentifier", "_ZN17storeservicescore20RequestContextConfig19setClientIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(ref const(HTTPProxy)), "setHTTPProxy",
            "_ZN17storeservicescore20RequestContextConfig12setHTTPProxyERKN13mediaplatform9HTTPProxyE");

    mixin implementMethod!(void function(string), "setDeviceModel", "_ZN17storeservicescore20RequestContextConfig14setDeviceModelERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(string), "setVersionIdentifier", "_ZN17storeservicescore20RequestContextConfig20setVersionIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(string), "setPlatformIdentifier", "_ZN17storeservicescore20RequestContextConfig21setPlatformIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(string), "setProductVersion", "_ZN17storeservicescore20RequestContextConfig17setProductVersionERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(string), "setBuildVersion", "_ZN17storeservicescore20RequestContextConfig15setBuildVersionERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(string), "setLocaleIdentifier", "_ZN17storeservicescore20RequestContextConfig19setLocaleIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

    mixin implementMethod!(void function(string), "setLanguageIdentifier", "_ZN17storeservicescore20RequestContextConfig21setLanguageIdentifierERKNSt6__ndk112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");
    
    mixin implementMethod!(void function(bool), "setResetHttpCache", "_ZN17storeservicescore20RequestContextConfig17setResetHttpCacheEb");
    
    mixin implementMethod!(void function(ref const(shared_ptr!AndroidRequestContextObserver)), "setRequestContextObserver", "_ZN17storeservicescore20RequestContextConfig25setRequestContextObserverERKNSt6__ndk110shared_ptrINS_22RequestContextObserverEEE");
    
    mixin implementMethod!(void function(ref const(shared_ptr!ContentBundle)), "setContentBundle", "_ZN17storeservicescore20RequestContextConfig16setContentBundleERKNSt6__ndk110shared_ptrIN13mediaplatform13ContentBundleEEE");
    
    mixin implementMethod!(string function(), "baseDirectoryPath", "_ZNK17storeservicescore20RequestContextConfig17baseDirectoryPathEv");
}

@AndroidClassInfo("libandroidappmusic", 392) class RequestContextConfigPtr : AndroidClass
{
}
