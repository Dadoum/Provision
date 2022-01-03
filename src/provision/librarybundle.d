module provision.librarybundle;

import provision.androidlibrary;
import provision.utils.loghelper;
import core.memory;
import std.file;
import std.path;
import std.stdio;
import std.traits;

version (LDC) {
@live:
}

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

enum string defaultLibPrefix = "ndk/" ~ architectureIdentifier ~ "/";
enum string applePrefix = "lib/" ~ architectureIdentifier ~ "/";

alias LibraryBundle = AndroidLibrary[EnumMembers!Library.length];
private LibraryBundle __instance;

public LibraryBundle libraryBundleInstance() {
    return __instance;
}

void initLibBundle() {
    string processPath = dirName(thisExePath());

    __instance = [
        new AndroidLibrary("libc.so.6", LibraryType.NATIVE_LINUX_LIBRARY),
        //new AndroidLibrary(null, LibraryType.NATIVE_LINUX_LIBRARY),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "libc.so")),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "libdl.so")),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "libm.so")),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "libz.so")),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "liblog.so")),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "libstdc++.so")),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "libOpenSLES.so")),
        new AndroidLibrary(buildPath(processPath, defaultLibPrefix ~ "libandroid.so")),

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
}

enum Library : ushort {
    NATIVE_LIBC,
    //NATIVE_LIBCPP,
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
