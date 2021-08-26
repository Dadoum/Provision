module provision.librarybundle;

import provision.androidlibrary;
import provision.utils.loghelper;
import core.memory;
import std.stdio;
import std.traits;

version (LDC) {
@live:
}

struct LibraryBundle {
    version (X86_64) {
        enum string architectureIdentifier = "x86_64";
    } else version (X86) {
        enum string architectureIdentifier = "x86";
    } else version (AArch64) {
        enum string architectureIdentifier = "arm64-v8a";
    } else version (ARM) {
        enum string architectureIdentifier = "armeabi-v7a";
    } else {
        static assert(false, "Votre architecture n'est pas supportée ^^'.");
    }

    enum string defaultLibPrefix = "../ndk/" ~ architectureIdentifier ~ "/";
    enum string applePrefix = "lib/" ~ architectureIdentifier ~ "/";

    public AndroidLibrary[EnumMembers!Library.length] libraries;

    static LibraryBundle* opCall() {
        scope auto ret = new LibraryBundle();
        ret.libraries = [
            new AndroidLibrary("libc.so.6", LibraryType.NATIVE_LINUX_LIBRARY),
            new AndroidLibrary(defaultLibPrefix ~ "libc.so"),
            new AndroidLibrary(defaultLibPrefix ~ "libdl.so"),
            new AndroidLibrary(defaultLibPrefix ~ "libm.so"),
            new AndroidLibrary(defaultLibPrefix ~ "libz.so"),
            new AndroidLibrary(defaultLibPrefix ~ "liblog.so"),
            new AndroidLibrary(defaultLibPrefix ~ "libstdc++.so"),
            new AndroidLibrary(defaultLibPrefix ~ "libOpenSLES.so"),
            new AndroidLibrary(defaultLibPrefix ~ "libandroid.so"),

            new AndroidLibrary(applePrefix ~ "libc++_shared.so"),
            new AndroidLibrary(applePrefix ~ "libCoreADI.so"),
            new AndroidLibrary(applePrefix ~ "libCoreLSKD.so"),
            new AndroidLibrary(applePrefix ~ "libCoreFP.so"),
            new AndroidLibrary(applePrefix ~ "libxml2.so"),
            new AndroidLibrary(applePrefix ~ "libcurl.so"),
            new AndroidLibrary(applePrefix ~ "libicudata_sv_apple.so"),
            new AndroidLibrary(applePrefix ~ "libicuuc_sv_apple.so"),
            new AndroidLibrary(applePrefix ~ "libicui18n_sv_apple.so"),
            new AndroidLibrary(applePrefix ~ "libBlocksRuntime.so"),
            new AndroidLibrary(applePrefix ~ "libdispatch.so"),
            new AndroidLibrary(applePrefix ~ "libCoreFoundation.so"),
            new AndroidLibrary(applePrefix ~ "libmediaplatform.so"),
            new AndroidLibrary(applePrefix ~ "libstoreservicescore.so"),
            new AndroidLibrary(applePrefix ~ "libdaapkit.so"),
            new AndroidLibrary(applePrefix ~ "libmedialibrarycore.so"),
            new AndroidLibrary(applePrefix ~ "libandroidappmusic.so")
        ];
        return ret;
    }

    ~this() {
        // logln!()("Nettoyage...", LogPriority.verbeux);
        destroy(libraries);
    }

    alias libraries this;
}

enum Library : ushort {
    NATIVE_LIBC,
    LIBC,
    LIBDL,
    LIBM,
    LIBZ,
    LIBLOG,
    LIBSTDCPP,
    LIBOPENSLES,
    LIBANDROID,

    LIBCPP_SHARED,
    LIBCOREADI,
    LIBCORELSKD,
    LIBCOREFP,
    LIBICUDATA_SV_APPLE,
    LIBICUUC_SV_APPLE,
    LIBICUI18N_SV_APPLE,
    LIBBLOCKSRUNTIME,
    LIBXML2,
    LIBCURL,
    LIBDISPATCH,
    LIBCOREFOUNDATION,
    LIBMEDIAPLATFORM,
    LIBSTORESERVICESCORE,
    LIBDAAPKIT,
    LIBMEDIALIBRARYCORE,
    LIBANDROIDAPPMUSIC
}
