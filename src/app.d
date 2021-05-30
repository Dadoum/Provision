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

extern (C)
{
	uint _ZNSt6__ndk113random_deviceclEvHook() {
		return 0;
	}

	int randHook() 
	{
		return 0;
	}

	uint arc4randomHook() 
	{
		return 0;
	}

    bool _ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook()
    {
        return true;
    }

    void __android_log_writeHook(int prio, const(char)* tag, const(char)* text)
    {
        logln!(const(char)[], const(char)[])("%s >> %s", fromStringz(tag), fromStringz(text), cast(LogPriority) prio);
    }
}

LibraryBundle bundle;

void main()
{
	AndroidLibrary.addGlobalHook("_ZNSt6__ndk113random_deviceclEv", &_ZNSt6__ndk113random_deviceclEvHook);
    AndroidLibrary.addGlobalHook("rand", &randHook);
    AndroidLibrary.addGlobalHook("arc4random", &arc4randomHook);
    AndroidLibrary.addGlobalHook("_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE",
          &_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook);
	AndroidLibrary.addGlobalHook("__android_log_write", &__android_log_writeHook);
	
    bundle = new LibraryBundle();
    import std.traits;

    logln("Création d'un contexte de requete");
    logln(
            "Création d'une configuration de contexte de requete (afin de créer un contexte de requete)");

    {
    	import provision.android.ndkstring;
        import provision.android.requestcontextconfig;
        import std.file;
        
        auto rcConfig = new RequestContextConfig();

        log("(Re)configuration du dossier...");
        const(string) bdp = expandTilde("~/.config/octocertif");
        if (!bdp.exists)
        {
            bdp.mkdir();
        }
        logln("(localisé à %s)", bdp);

        NdkString androidId = toNdkString("9774d56d682e549c");
        NdkString oldGuid = toNdkString("");
//         const(uint) sdkVersion = 29;
//         const(bool) hasFairplay = true;
        const(uint) sdkVersion = 24;
        const(bool) hasFairplay = false;

        logln("Configuration du contexte de requete... ");

        NdkString baseDirectoryPath = toNdkString(bdp);
        rcConfig.setBaseDirectoryPath(baseDirectoryPath);
        
        import provision.android.requestcontext;
        RequestContext context = new RequestContext(baseDirectoryPath);
        
        NdkString clientIdentifier = toNdkString("Music");
        rcConfig.setClientIdentifier(clientIdentifier);
        NdkString versionIdentifier = toNdkString("4.3");
        rcConfig.setVersionIdentifier(versionIdentifier); // 11.2
        NdkString platformIdentifier = toNdkString("Android");
        rcConfig.setPlatformIdentifier(platformIdentifier); // Linux
        NdkString productVersion = toNdkString("7.0.0");
        rcConfig.setProductVersion(productVersion); // 5.11.2
        NdkString deviceModel = toNdkString("Google Pixel");
        rcConfig.setDeviceModel(deviceModel); // HP ProBook 430 G5
        NdkString buildVersion = toNdkString("5803371"); // C'est celui Android 10 mais jsp en vrai si c'est pas le 7 ou quoi
        rcConfig.setBuildVersion(buildVersion); // 0
        NdkString localeIdentifier = toNdkString("fr");
        rcConfig.setLocaleIdentifier(localeIdentifier); // fr
        NdkString languageIdentifier = toNdkString("fr");
        rcConfig.setLanguageIdentifier(languageIdentifier); // fr

        import provision.android.httpproxy;

        NdkString url = toNdkString("");
        const(ushort) port = 80;
        auto httpProxy = new HTTPProxy(0, url, port);

        rcConfig.setHTTPProxy(httpProxy);
        rcConfig.setResetHttpCache(true);
        
        import provision.android.androidrequestcontextobserver;
        import provision.androidclass;
        
        AndroidRequestContextObserver observer = new AndroidRequestContextObserver(null);
		rcConfig.setRequestContextObserver(observer.handle);
		
        import provision.android.foothillconfig;

        FootHillConfig.config(androidId);

        import provision.android.deviceguid;

        auto guidPtr = DeviceGUID.instance();
        if (guidPtr != null && guidPtr.ptr != null)
        {
            auto deviceGuid = new DeviceGUID(guidPtr.ptr);
            if (!deviceGuid.isConfigured())
            {
                DeviceGUID.configure(androidId, oldGuid, sdkVersion, hasFairplay);
            }
            destroy(deviceGuid);
        }
		
		import provision.android.filepath;
		import provision.android.contentbundle;
		import ssoulaimane.stdcpp.vector;
		
		NdkString baseDirStr = toNdkString(expandTilde("~/.config/octocertif"));
		const(FilePath) baseDir = new FilePath(baseDirStr);
		NdkString cacheDirStr = toNdkString(expandTilde("~/.config/octocertif/cache"));
		const(FilePath) cacheDir = new FilePath(cacheDirStr);
		NdkString filesDirStr = toNdkString(expandTilde("~/.config/octocertif"));
		const(FilePath) filesDir = new FilePath(filesDirStr);
		// basic_string!char lang = "fr";
		vector!(void*) langs = vector!(void*)([ ]);
		// langs.push_back(lang);
		ContentBundle contentBundle = new ContentBundle(baseDir, cacheDir, filesDir, langs);
		rcConfig.setContentBundle(contentBundle.handle);
		
        NdkString fairPlayDirectoryPath = toNdkString(expandTilde("~/.config/octocertif/fairPlay"));
		rcConfig.setFairPlayDirectoryPath(fairPlayDirectoryPath);
		
		logln("Application de la configuration...");
		import provision.android.requestcontextmanager;
		RequestContextManager.configure(context.handle);
		
		context.init(rcConfig.handle);
		
        destroy(url);
        destroy(clientIdentifier);
        destroy(versionIdentifier);
        destroy(platformIdentifier);
        destroy(productVersion);
        destroy(deviceModel);
        destroy(buildVersion);
        destroy(localeIdentifier);
        destroy(languageIdentifier);
        destroy(androidId);
        destroy(oldGuid);
        destroy(baseDirectoryPath);
		destroy(contentBundle);
		destroy(langs);
		destroy(baseDirStr);
		destroy(cacheDirStr);
		destroy(filesDirStr);
		destroy(fairPlayDirectoryPath);
		
		destroy(filesDir);
		destroy(cacheDir);
		destroy(baseDir);

		destroy(observer);
        destroy(httpProxy);
        destroy(androidId);
        destroy(rcConfig);
        destroy(context);
    }

    destroy(bundle);
}
