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
	uint arc4random() 
	{
		return 0;
	}

    bool _ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE()
    {
        return true;
    }

    void __android_log_write(int prio, const(char)* tag, const(char)* text)
    {
        logln("[Android::%s] [%s] >> %s", fromStringz(tag), prio, fromStringz(text));
    }
}

LibraryBundle bundle;

void main()
{
	version(Debug) 
	{
    	AndroidLibrary.addGlobalHook("arc4random", &arc4random);
    	AndroidLibrary.addGlobalHook("__android_log_write", &__android_log_write);
    	AndroidLibrary.addGlobalHook("_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE",
    	        &_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE);
	}

    bundle = new LibraryBundle();
    import std.traits;

    logln("Création d'un contexte de requete");
    logln(
            "Création d'une configuration de contexte de requete (afin de créer un contexte de requete)");

    {
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

        const(basic_string!char) androidId = "9774d56d682e549c";
        const(basic_string!char) oldGuid = "";
        const(uint) sdkVersion = 29;
        const(bool) hasFairplay = true;

        logln("Configuration du contexte de requete... ");

        const(basic_string!char) baseDirectoryPath = bdp;
        rcConfig.setBaseDirectoryPath(baseDirectoryPath);
        
        import provision.android.requestcontext;
        RequestContext context = new RequestContext(baseDirectoryPath);
        auto str = rcConfig.baseDirectoryPath();
	pragma(msg, typeof(rcConfig.baseDirectoryPath).stringof);
        writeln("yes: ");
        stdout.flush();
        writeln(str.toString());
        stdout.flush();
        
        const(basic_string!char) clientIdentifier = "Music";
        rcConfig.setClientIdentifier(clientIdentifier);
        const(basic_string!char) versionIdentifier = "4.3";
        rcConfig.setVersionIdentifier(versionIdentifier); // 11.2
        const(basic_string!char) platformIdentifier = "Android";
        rcConfig.setPlatformIdentifier(platformIdentifier); // Linux
        const(basic_string!char) productVersion = "7.0.0";
        rcConfig.setProductVersion(productVersion); // 5.11.2
        const(basic_string!char) deviceModel = "Google Pixel";
        rcConfig.setDeviceModel(deviceModel); // HP ProBook 430 G5
        const(basic_string!char) buildVersion = "5803371"; // C'est celui Android 10 mais jsp en vrai si c'est pas le 7 ou quoi
        rcConfig.setBuildVersion(buildVersion); // 0
        const(basic_string!char) localeIdentifier = "fr";
        rcConfig.setLocaleIdentifier(localeIdentifier); // fr
        const(basic_string!char) languageIdentifier = "fr";
        rcConfig.setLanguageIdentifier(languageIdentifier); // fr

        import provision.android.httpproxy;

        const(basic_string!char) url = "";
        const(ushort) port = 80;
        auto httpProxy = new HTTPProxy(0, url, port);

        rcConfig.setHTTPProxy(httpProxy);
        rcConfig.setResetHttpCache(true);
        
        import provision.android.androidrequestcontextobserver;
        import provision.androidclass;
        
        AndroidRequestContextObserver observer = new AndroidRequestContextObserver(null);
		rcConfig.setRequestContextObserver(observer.handle);
		
//         import provision.android.foothillconfig;
// 
//         FootHillConfig.config(androidId);
// 
//         import provision.android.deviceguid;
// 
//         auto guidPtr = DeviceGUID.instance();
//         if (guidPtr != null && guidPtr.ptr != null)
//         {
//             auto deviceGuid = new DeviceGUID(guidPtr.ptr);
//             if (!deviceGuid.isConfigured())
//             {
//                 DeviceGUID.configure(androidId, oldGuid, sdkVersion, hasFairplay);
//             }
//             destroy(deviceGuid);
//         }
		
		import provision.android.filepath;
		import provision.android.contentbundle;
		import ssoulaimane.stdcpp.vector;
		
		const(basic_string!char) baseDirStr = expandTilde("~/.config/octocertif");
		const(FilePath) baseDir = new FilePath(baseDirStr);
		const(basic_string!char) cacheDirStr = expandTilde("~/.config/octocertif/cache");
		const(FilePath) cacheDir = new FilePath(cacheDirStr);
		const(basic_string!char) filesDirStr = expandTilde("~/.config/octocertif");
		const(FilePath) filesDir = new FilePath(filesDirStr);
		// basic_string!char lang = "fr";
		vector!(basic_string!char) langs = vector!(basic_string!char)([ ]);
		// langs.push_back(lang);
		ContentBundle contentBundle = new ContentBundle(baseDir, cacheDir, filesDir, langs);
		rcConfig.setContentBundle(contentBundle.handle);
		
        const(basic_string!char) fairPlayDirectoryPath = expandTilde("~/.config/octocertif/fairPlay");
		rcConfig.setFairPlayDirectoryPath(fairPlayDirectoryPath);
		
		logln("Application de la configuration...");
		import provision.android.requestcontextmanager;
		RequestContextManager.configure(context.handle);
		
		context.init(rcConfig.handle);
		
		destroy(contentBundle);
		destroy(langs);
		
		destroy(filesDir);
		destroy(cacheDir);
		destroy(baseDir);

		destroy(observer);
        destroy(httpProxy);
        destroy(rcConfig);
        destroy(context);
    }

    destroy(bundle);
}
