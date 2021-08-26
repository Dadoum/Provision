module app;

import core.memory;
import core.stdc.stdint;
import core.stdc.stdlib;
import provision.androidclass;
import provision.androidlibrary;
import provision.android.ndkstring;
import provision.librarybundle;
import provision.utils.loghelper;
import provision.utils.segfault;
import provision.glue;
import provision.android.requestcontextconfig;
import provision.android.requestcontext;
import std.file;
import std.algorithm;
import std.conv;
import std.meta;
import std.path;
import std.stdio;
import std.string;
import std.typecons;

version (LDC) {
@live:
}

extern (C) {
    uint _ZNSt6__ndk113random_deviceclEvHook() {
        return 0;
    }

    int randHook() {
        return 0;
    }

    uint arc4randomHook() {
        return 0;
    }

    void __android_log_writeHook(int prio, const(char)* tag, const(char)* text) {
        return logln!(const(char)[], const(char)[])("%s >> %s",
                fromStringz(tag), fromStringz(text), cast(LogPriority) prio);
    }

    debug {
        bool _ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook(LogPriority prio) {
            return true;
        }
    } else {
        bool _ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook(LogPriority prio) {
            return prio > 4;
        }
    }

    union sd_id128_t {
        uint8_t[16] bytes;
        uint64_t[2] qwords;
    }

    int sd_id128_get_machine_app_specific(sd_id128_t app_id, sd_id128_t* ret);
}

sd_id128_t* make_id(int b0, int b1, int b2, int b3, int b4, int b5, int b6, int b7,
        int b8, int b9, int b10, int b11, int b12, int b13, int b14, int b15) {
    return make_id([
            cast(byte) b0, cast(byte) b1, cast(byte) b2, cast(byte) b3,
            cast(byte) b4, cast(byte) b5, cast(byte) b6, cast(byte) b7,
            cast(byte) b8, cast(byte) b9, cast(byte) b10, cast(byte) b11,
            cast(byte) b12, cast(byte) b13, cast(byte) b14, cast(byte) b15
            ]);
}

sd_id128_t* make_id(byte[16] b) {
    auto id = new sd_id128_t();
    id.bytes[0] = b[0];
    id.bytes[1] = b[1];
    id.bytes[2] = b[2];
    id.bytes[3] = b[3];
    id.bytes[4] = b[4];
    id.bytes[5] = b[5];
    id.bytes[6] = b[6];
    id.bytes[7] = b[7];
    id.bytes[8] = b[8];
    id.bytes[9] = b[9];
    id.bytes[10] = b[10];
    id.bytes[11] = b[11];
    id.bytes[12] = b[12];
    id.bytes[13] = b[13];
    id.bytes[14] = b[14];
    id.bytes[15] = b[15];
    return id;
}

string toString(sd_id128_t* id) {
    import std.format;

    return std.format.format("%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            id.bytes[0], id.bytes[1], id.bytes[2], id.bytes[3], id.bytes[4],
            id.bytes[5], id.bytes[6], id.bytes[7], id.bytes[8], id.bytes[9],
            id.bytes[10], id.bytes[11], id.bytes[12], id.bytes[13], id.bytes[14], id.bytes[15]);
}

LibraryBundle* bundle;
bool isVerbeux;

int main(string[] args) {
    AndroidLibrary.addGlobalHook("_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE",
            &_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook);
    AndroidLibrary.addGlobalHook("__android_log_write", &__android_log_writeHook);
    debug {
        AndroidLibrary.addGlobalHook("_ZNSt6__ndk113random_deviceclEv",
                &_ZNSt6__ndk113random_deviceclEvHook);
        AndroidLibrary.addGlobalHook("rand", &randHook);
        AndroidLibrary.addGlobalHook("arc4random", &arc4randomHook);
        isVerbeux = true;
    } else {
        isVerbeux = args.canFind("-v");
    }

    bundle = LibraryBundle();

    {
        logln!()("Création d'un contexte de requete", LogPriority.verbeux);
        logln!()("Création d'une configuration de contexte de requete (afin de créer un contexte de requete)",
                LogPriority.verbeux);

        auto rcConfigPtr = create_shared(new RequestContextConfig());

        log!()("(Re)configuration du dossier...", LogPriority.verbeux);
        const(string) bdp = expandTilde("~/.config/octocertif");
        if (!bdp.exists) {
            bdp.mkdir();
        }
        logln!(string)("(localisé à %s)", bdp, LogPriority.verbeux);

        sd_id128_t* appId = make_id(0x8b, 0x06, 0x7f, 0xdd, 0x3c, 0xbf, 0x40,
                0x8c, 0x90, 0x64, 0xc7, 0x5a, 0x9a, 0xc4, 0xc7, 0x8b), machineId = new sd_id128_t();
        int idGenCode = sd_id128_get_machine_app_specific(*appId, machineId);
        string linuxId = appId.toString()[0 .. 16];

        if (idGenCode != 0) {
            logln("Échec de la génération de l'identifiant linux (code %d).", idGenCode);
            return -1;
        }

        const(uint) sdkVersion = 29;
        const(bool) hasFairplay = true;

        logln!()("Configuration du contexte de requete... ", LogPriority.verbeux);

        shared_ptr!RequestContext contextPtr = RequestContext.makeShared(bdp);

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

        shared_ptr!AndroidRequestContextObserver observerPtr = create_shared(
                new AndroidRequestContextObserver(PrivateConstructorOperation.ALLOCATE));
        scope (exit)
            destroy_shared(observerPtr);
        rcConfigPtr.get().setRequestContextObserver(observerPtr);

        import provision.android.foothillconfig;

        FootHillConfig.config(linuxId);

        import provision.android.deviceguid;
        import provision.android.storeerrorcondition;
        import provision.android.data;

        log!()("Création d'un identifiant... ", LogPriority.verbeux);
        auto deviceGuid = DeviceGUID.instance();
        if (deviceGuid.get() !is null) {
            if (!deviceGuid.get().isConfigured()) {
                StoreErrorCondition error = deviceGuid.get().configure(linuxId,
                        "", sdkVersion, hasFairplay);
                auto code = error.errorCode();
                if (code == ErrorCode.SUCCESS) {
                    logln!()("succès !", LogPriority.verbeux);
                } else {
                    logln!(int)("échec... (code %d) ", code, LogPriority.verbeux);
                    return code;
                }
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

        logln!()("Application de la configuration... ", LogPriority.verbeux);
        import provision.android.requestcontextmanager;

        RequestContextManager.configure(contextPtr);
        StoreErrorCondition errorCode = contextPtr.get().initialize(contextPtr.get(), rcConfigPtr);
        auto initErrorCode = errorCode.errorCode();
        if (initErrorCode == ErrorCode.SUCCESS) {
            logln!()("Succès !", LogPriority.verbeux);
        } else {
            logln!(int)("Échec... (code %d) ", initErrorCode, LogPriority.verbeux);
            return initErrorCode;
        }

        logln!()("On passe à l'approvisionnement...", LogPriority.verbeux);
        // import provision.android.defaultstoreclient;
        //
        // auto dscPtr = DefaultStoreClient.make(contextPtr);
        // auto str = DefaultStoreClient.getAnisetteRequestMachineId(0x0, dscPtr.ptr);

        //         import provision.android.urlbagrequest;
        //         URLBagRequest urlBagRequest = new URLBagRequest(contextPtr);
        //         urlBagRequest.setCacheOptions(URLBagCacheOption.ignoresCache);
        //         urlBagRequest.run();
        //
        //         import provision.android.anisetteprotocolaction;
        //
        //         auto headers = str_str_multimap_create();
        //         scope (exit)
        //             str_str_multimap_delete(headers);

        // Meilleure façon de récupérer le texte, plutot que juste l'écrire, autant directement le lire
        //         auto md_action = bundle.libraries[Library.LIBSTORESERVICESCORE].loadSymbol!(
        //                 void*)("_ZN17storeservicescore14XAppleMDActionE");
        //         auto md_data = bundle.libraries[Library.LIBSTORESERVICESCORE].loadSymbol!(
        //                 void*)("_ZN17storeservicescore12XAppleMDDataE");
        //         headers.str_str_multimap_insert(md_action, md_data);
        //         auto tempFakeAnisette = new AnisetteProtocolAction(
        //                 PrivateConstructorOperation.WRAP_OBJECT, cast(OpaquePtr*) new void* ());
        //         auto anisetteProtocolAction = tempFakeAnisette.actionForHeaders(headers,
        //                 AnisetteProtocolVersion.standard);
        //         anisetteProtocolAction.performWithContext(contextPtr);
        // import provision.android.rapidandroidprototyper;
		doRequest(contextPtr);
        //         auto urlBagRequest = RapidAndroidPrototyper!(Library.LIBSTORESERVICESCORE).runCtor!"_ZN17storeservicescore13URLBagRequestC1ENSt6__ndk110shared_ptrINS_14RequestContextEEE"(contextPtr);
        //
        //         enum URLBagRequest {
        //     		URLBagCacheOptionNone = 0,
        //     		URLBagCacheOptionAllowsExpiredBag = 1,
        //     		URLBagCacheOptionIgnoresCache = 2
        //     	}
        //
        //         urlBagRequest.run!"_ZN17storeservicescore13URLBagRequest15setCacheOptionsENS_18URLBagCacheOptionsE"();
        //         urlBagRequest.run!"_ZN17storeservicescore13URLBagRequest3runEv"();

// 	import plist;
// 	import plist.types;
// 	Plist spimPlist = new Plist();
// 	spimPlist.read(content);
// 	PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (spimPlist[0]))["Response"];
// 	string spimStr = (cast(PlistElementString) spimResponse["spim"]).value;
//
// 	import std.base64;
// 	byte[] spim = cast(byte[]) Base64.decode(spimStr);

        logln!()("Nettoyage...", LogPriority.verbeux);
    }

    return 0;
}

void doRequest(shared_ptr!RequestContext rqContext) {
	import std.net.curl;
	auto client = HTTP();
	client.setUserAgent("akd/1.0 CFNetwork/808.1.4 Darwin/16.1.0");
	client.addRequestHeader("Accept", "*/*");
	client.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	client.addRequestHeader("Accept-Language", "fr-fr");
	client.addRequestHeader("X-Apple-I-SRL-NO", "");
	client.addRequestHeader("X-MMe-Client-Info", format!"<%s> <%s;%s;%s> <com.apple.akd/1.0 (com.apple.akd/1.0)>"("PC", "Windows", "6.2(0,0)", "9200")); // device model, device operating system, os version, os build
	client.addRequestHeader("Accept-Encoding", "gzip"); // , deflate
	// client.addRequestHeader("X-Mme-Device-Id", lpUdid);
	string content = cast(string) post("https://gsa.apple.com/grandslam/MidService/startMachineProvisioning",
	"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
<key>Header</key>
<dict/>
<key>Request</key>
<dict/>
</dict>
</plist>"
	, client);

	writeln(content);
}
