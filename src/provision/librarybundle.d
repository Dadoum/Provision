module provision.librarybundle;

import provision.androidlibrary;
import provision.utils.loghelper;
import core.memory;
import std.stdio;

class LibraryBundle
{
	version (X86)
	{
		enum string defaultLibPrefix = "lib32/";
		enum string applePrefix = "apple32/";
	}
	else
	{
		enum string defaultLibPrefix = "lib/";
		enum string applePrefix = "apple/";
	}

    public static LibraryBundle instance;

    public AndroidLibrary[string] libraries;

    this()
    {
        libraries["libc"] = new AndroidLibrary(defaultLibPrefix ~ "libc.so");
        libraries["libc-native"] = new AndroidLibrary("libc.so.6", LibraryType.NATIVE_LINUX_LIBRARY);
        libraries["libdl"] = new AndroidLibrary(defaultLibPrefix ~ "libdl.so");
        libraries["libm"] = new AndroidLibrary(defaultLibPrefix ~ "libm.so");
        libraries["libz"] = new AndroidLibrary(defaultLibPrefix ~ "libz.so");
        libraries["liblog"] = new AndroidLibrary(defaultLibPrefix ~ "liblog.so");
        libraries["libstdc++"] = new AndroidLibrary(defaultLibPrefix ~ "libstdc++.so");
        libraries["libOpenSLES"] = new AndroidLibrary(defaultLibPrefix ~ "libOpenSLES.so");
        libraries["libandroid"] = new AndroidLibrary(defaultLibPrefix ~ "libandroid.so");

        libraries["libCoreADI"] = new AndroidLibrary(applePrefix ~ "libCoreADI.so");
        libraries["libCoreLSKD"] = new AndroidLibrary(applePrefix ~ "libCoreLSKD.so");
        libraries["libCoreFP"] = new AndroidLibrary(applePrefix ~ "libCoreFP.so");
        libraries["libc++_shared"] = new AndroidLibrary(applePrefix ~ "libc++_shared.so");
        libraries["libicudata_sv_apple"] = new AndroidLibrary(applePrefix ~ "libicudata_sv_apple.so");
        libraries["libicuuc_sv_apple"] = new AndroidLibrary(applePrefix ~ "libicuuc_sv_apple.so");
        libraries["libicui18n_sv_apple"] = new AndroidLibrary(applePrefix ~ "libicui18n_sv_apple.so");
        libraries["libBlocksRuntime"] = new AndroidLibrary(applePrefix ~ "libBlocksRuntime.so");
        libraries["libxml2"] = new AndroidLibrary(applePrefix ~ "libxml2.so");
        libraries["libcurl"] = new AndroidLibrary(applePrefix ~ "libcurl.so");
        libraries["libdispatch"] = new AndroidLibrary(applePrefix ~ "libdispatch.so");
        libraries["libCoreFoundation"] = new AndroidLibrary(applePrefix ~ "libCoreFoundation.so");
        libraries["libmediaplatform"] = new AndroidLibrary(applePrefix ~ "libmediaplatform.so");
        libraries["libstoreservicescore"] = new AndroidLibrary(applePrefix ~ "libstoreservicescore.so");
        libraries["libdaapkit"] = new AndroidLibrary(applePrefix ~ "libdaapkit.so");
        libraries["libmedialibrarycore"] = new AndroidLibrary(applePrefix ~ "libmedialibrarycore.so");
        libraries["libandroidappmusic"] = new AndroidLibrary(applePrefix ~ "libandroidappmusic.so");

        instance = this;
    }

    ~this()
    {
        destroy(libraries);
    }

    alias libraries this;
}
