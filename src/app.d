module app;

import std.stdio;
import std.string;
import std.conv;
import std.path;
import provision.librarybundle;
import provision.androidlibrary;
import provision.utils.loghelper;
import core.memory;
import core.stdc.stdlib;
import std.typecons;
import core.stdcpp.string;
import provision.androidclass;
import provision.android.ndkstring;

extern (C)
{
    uint _ZNSt6__ndk113random_deviceclEvHook() => 0;
    int randHook() => 0;
    uint arc4randomHook() => 0;
    void __android_log_writeHook(int prio, const(char) * tag, const(char) * text) => logln!(
            const(char)[], const(char)[])("%s >> %s", fromStringz(tag),
            fromStringz(text), cast(LogPriority) prio);

    debug
    {
        bool _ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook(LogPriority prio) => true;
    }
    else
    {
        bool _ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook(LogPriority prio) => prio > 4;
    }
}

LibraryBundle bundle;

void main()
{
    debug
    {
        AndroidLibrary.addGlobalHook("_ZNSt6__ndk113random_deviceclEv",
                &_ZNSt6__ndk113random_deviceclEvHook);
        AndroidLibrary.addGlobalHook("rand", &randHook);
        AndroidLibrary.addGlobalHook("arc4random", &arc4randomHook);
    }
    AndroidLibrary.addGlobalHook("_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE",
            &_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook);
    AndroidLibrary.addGlobalHook("__android_log_write", &__android_log_writeHook);

    bundle = new LibraryBundle();
    scope (exit)
        destroy(bundle);
    import std.traits;

    logln("Création d'un contexte de requete");
    logln(
            "Création d'une configuration de contexte de requete (afin de créer un contexte de requete)");

	procedure();
}

void procedure()
{
	import provision.glue;
    import provision.android.requestcontextconfig;
    import provision.android.requestcontext;
    import std.file;
    
    auto rcConfigPtr = create_shared(new RequestContextConfig());
    scope (exit)
        destroy_shared(rcConfigPtr);

    log("(Re)configuration du dossier...");
    const(string) bdp = expandTilde("~/.config/octocertif");
    if (!bdp.exists)
    {
        bdp.mkdir();
    }
    logln("(localisé à %s)", bdp);

    string linuxId = to!string(read("/etc/machine-id", 16));

    const(uint) sdkVersion = 29;
    const(bool) hasFairplay = true;

    logln("Configuration du contexte de requete... ");
    
    shared_ptr!RequestContext contextPtr = RequestContext.makeShared(bdp);
    scope (exit)
       destroy_shared(contextPtr);

    rcConfigPtr.get().setBaseDirectoryPath(bdp);
    rcConfigPtr.get().setClientIdentifier("Music");
    rcConfigPtr.get().setVersionIdentifier("4.3"); // 11.2
    rcConfigPtr.get().setPlatformIdentifier("Android"); // Linux
    rcConfigPtr.get().setProductVersion("7.0.0"); // 5.11.2
    rcConfigPtr.get().setDeviceModel("Google Pixel"); // HP ProBook 430 G5
    rcConfigPtr.get().setBuildVersion("5803371"); // 0
    rcConfigPtr.get().setLocaleIdentifier("fr"); // fr
    rcConfigPtr.get().setLanguageIdentifier("fr"); // fr

    import provision.android.httpproxy;
    
    const(ushort) port = 80;
    auto httpProxy = new HTTPProxy(0, "", port);
    scope (exit)
        destroy(httpProxy);

    rcConfigPtr.get().setHTTPProxy(httpProxy);
    rcConfigPtr.get().setResetHttpCache(true);

    import provision.android.androidrequestcontextobserver;

    shared_ptr!AndroidRequestContextObserver observerPtr = create_shared(new AndroidRequestContextObserver(
            PrivateConstructorOperation.ALLOCATE));
    scope (exit)
        destroy_shared(observerPtr);
    rcConfigPtr.get().setRequestContextObserver(observerPtr);

    import provision.android.foothillconfig;

    FootHillConfig.config(linuxId);
    logln(rcConfigPtr.get().baseDirectoryPath());
    
    import provision.android.deviceguid;

    auto deviceGuid = DeviceGUID.instance();
    if (deviceGuid.get() !is null)
    {
        if (!deviceGuid.get().isConfigured())
        {
            // deviceGuid.get().configure(linuxId, "", sdkVersion, hasFairplay);
        }
    }

    import provision.android.filepath;
    import provision.android.contentbundle;
    const(FilePath) baseDir = new FilePath(expandTilde("~/.config/octocertif"));
    scope (exit)
        destroy(baseDir);

    const(FilePath) cacheDir = new FilePath(expandTilde("~/.config/octocertif/cache"));
    scope (exit)
        destroy(cacheDir);
        
    const(FilePath) filesDir = new FilePath(expandTilde("~/.config/octocertif"));
    scope (exit)
        destroy(filesDir);

    auto langs = string_vector_create();
    scope (exit)
        string_vector_delete(langs);
    string_vector_push_back(langs, toStringz("fr"));

    ContentBundle contentBundle = new ContentBundle(baseDir, cacheDir, filesDir, langs);
    scope (exit)
        destroy(contentBundle);
    auto contentBundlePtr = create_shared(contentBundle);
    rcConfigPtr.get().setContentBundle(contentBundlePtr);
    
    rcConfigPtr.get().setFairPlayDirectoryPath(expandTilde("~/.config/octocertif/fairPlay"));

    logln("Application de la configuration...");
    import provision.android.requestcontextmanager;
    RequestContextManager.configure(contextPtr);
    
    contextPtr.get().init(rcConfigPtr);
    
    logln("On passe à l'approvisionnement...");
    import provision.android.defaultstoreclient;
    auto dscPtr = DefaultStoreClient.make(contextPtr);
    auto str = dscPtr.get().getAnisetteRequestMachineId();
    
    logln!()("Nettoyage...", LogPriority.verbeux);
}
