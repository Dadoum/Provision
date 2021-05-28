module provision.librarybundle;

import provision.androidlibrary;
import provision.utils.loghelper;
import core.memory;
import std.stdio;

class LibraryBundle
{
    public static LibraryBundle instance;

    public AndroidLibrary[string] libraries;

    this()
    {
        libraries["ld-android"] = new AndroidLibrary("lib32/ld-android.so");
        libraries["libdl"] = new AndroidLibrary("lib32/libdl.so");
        libraries["libc"] = new AndroidLibrary("lib32/libc.so");
        libraries["libm"] = new AndroidLibrary("lib32/libm.so");
        libraries["libz"] = new AndroidLibrary("lib32/libz.so");
        libraries["liblog"] = new AndroidLibrary("lib32/liblog.so");
        libraries["libstdc++"] = new AndroidLibrary("lib32/libstdc++.so");
        libraries["libOpenSLES"] = new AndroidLibrary("lib32/libOpenSLES.so");
        libraries["libandroid"] = new AndroidLibrary("lib32/libandroid.so");

        libraries["libCoreADI"] = new AndroidLibrary("apple32/libCoreADI.so");
        libraries["libCoreLSKD"] = new AndroidLibrary("apple32/libCoreLSKD.so");
        libraries["libCoreFP"] = new AndroidLibrary("apple32/libCoreFP.so");
        libraries["libc++_shared"] = new AndroidLibrary("apple32/libc++_shared.so");
        libraries["libicudata_sv_apple"] = new AndroidLibrary("apple32/libicudata_sv_apple.so");
        libraries["libicuuc_sv_apple"] = new AndroidLibrary("apple32/libicuuc_sv_apple.so");
        libraries["libicui18n_sv_apple"] = new AndroidLibrary("apple32/libicui18n_sv_apple.so");
        libraries["libBlocksRuntime"] = new AndroidLibrary("apple32/libBlocksRuntime.so");
        libraries["libxml2"] = new AndroidLibrary("apple32/libxml2.so");
        libraries["libcurl"] = new AndroidLibrary("apple32/libcurl.so");
        libraries["libdispatch"] = new AndroidLibrary("apple32/libdispatch.so");
        libraries["libCoreFoundation"] = new AndroidLibrary("apple32/libCoreFoundation.so");
        libraries["libmediaplatform"] = new AndroidLibrary("apple32/libmediaplatform.so");
        libraries["libstoreservicescore"] = new AndroidLibrary("apple32/libstoreservicescore.so");
        libraries["libdaapkit"] = new AndroidLibrary("apple32/libdaapkit.so");
        libraries["libmedialibrarycore"] = new AndroidLibrary("apple32/libmedialibrarycore.so");
        libraries["libandroidappmusic"] = new AndroidLibrary("apple32/libandroidappmusic.so");

        instance = this;
    }

    ~this()
    {
        destroy(libraries);
    }

    alias libraries this;
}
