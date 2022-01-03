module app;

import core.memory;
import core.stdc.stdint;
import core.stdc.stdlib;
import provision.androidclass;
import provision.androidlibrary;
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

int main(string[] args) {
    AndroidLibrary.addGlobalHook("_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityE",
    &_ZN13mediaplatform26DebugLogEnabledForPriorityENS_11LogPriorityEHook);
    AndroidLibrary.addGlobalHook("__android_log_write", &__android_log_writeHook);
    //AndroidLibrary.addGlobalHook("__cxa_finalize", &__cxa_finalizeHook);
    debug {
        AndroidLibrary.addGlobalHook("_ZNSt6__ndk113random_deviceclEv",
        &_ZNSt6__ndk113random_deviceclEvHook);
        AndroidLibrary.addGlobalHook("rand", &randHook);
        AndroidLibrary.addGlobalHook("arc4random", &arc4randomHook);
        isVerbeux = true;
    } else {
        isVerbeux = args.canFind("-v");
    }

    initLibBundle();

    {
        logln!()("Création d'un contexte de requete", LogPriority.verbeux);
        logln!()("Création d'une configuration de contexte de requete (afin de créer un contexte de requete)",
        LogPriority.verbeux);

        auto __rcConfig = RequestContextConfig.create();
        auto rcConfigPtr = create_shared(__rcConfig);

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

        NdkString* baseDirectoryPath  = bdp.toHybrisStr;
        NdkString* clientIdentifier   = "Music".toHybrisStr;
        NdkString* versionIdentifier  = "4.4".toHybrisStr;
        NdkString* platformIdentifier = "Android".toHybrisStr;
        NdkString* productVersion     = "7.0.0".toHybrisStr;
        NdkString* deviceModel        = "Google Pixel 3".toHybrisStr;
        NdkString* buildVersion       = "5803371".toHybrisStr;
        NdkString* localeIdentifier   = "fr".toHybrisStr;
        NdkString* languageIdentifier = "fr".toHybrisStr;

        shared_ptr!RequestContext contextPtr = RequestContext.makeShared(*baseDirectoryPath);

        rcConfigPtr.get().setBaseDirectoryPath  (*baseDirectoryPath);
        rcConfigPtr.get().setClientIdentifier   (*clientIdentifier);
        rcConfigPtr.get().setVersionIdentifier  (*versionIdentifier); // 11.2
        rcConfigPtr.get().setPlatformIdentifier (*platformIdentifier); // Linux
        rcConfigPtr.get().setProductVersion     (*productVersion); // 5.11.2
        rcConfigPtr.get().setDeviceModel        (*deviceModel); // HP ProBook 430 G5
        rcConfigPtr.get().setBuildVersion       (*buildVersion); // 0
        rcConfigPtr.get().setLocaleIdentifier   (*localeIdentifier); // fr
        rcConfigPtr.get().setLanguageIdentifier (*languageIdentifier); // fr

        import provision.android.httpproxy;

        const(ushort) port = 80;
        HTTPProxy* httpProxy = HTTPProxy.allocate();
        rcConfigPtr.get().setHTTPProxy(*httpProxy);
        rcConfigPtr.get().setResetHttpCache(true);

        import provision.android.androidrequestcontextobserver;

        shared_ptr!AndroidRequestContextObserver observerPtr = create_shared(AndroidRequestContextObserver.allocate());
        //scope (exit)
        //destroy_shared(observerPtr);
        rcConfigPtr.get().setRequestContextObserver(observerPtr);

        import provision.android.foothillconfig;

        FootHillConfig.config(*linuxId.toHybrisStr);

        import provision.android.deviceguid;
        import provision.android.storeerrorcondition;
        import provision.android.data;

        log!()("Création d'un identifiant... ", LogPriority.verbeux);
        auto deviceGuid = DeviceGUID.instance();
        if (deviceGuid.get() !is null) {
            if (!deviceGuid.get().isConfigured()) {
                StoreErrorCondition error = deviceGuid.get().configure(*linuxId.toHybrisStr,
                *"".toHybrisStr, sdkVersion, hasFairplay);
                scope(exit) destroy(error);
                auto code = error.errorCode();
                // TODO, ça marche bizarrement pas
                if (/+code == ErrorCode.success+/ deviceGuid.get().isConfigured) {
                    logln!()("succès !", LogPriority.verbeux);
                    shared_ptr!Data guid = deviceGuid.get().guid();
                    logln!string("GUID: %s", guid.get().toString(), LogPriority.verbeux);


                } else {
                    logln!ErrorCode("Échec... (code %d) ", code, LogPriority.verbeux);
                    return code;
                }
            }
        }

        import provision.android.filepath;
        import provision.android.contentbundle;

        FilePath* baseDir = FilePath.create(*expandTilde("~/.config/octocertif").toHybrisStr);
        FilePath* cacheDir = FilePath.create(*expandTilde("~/.config/octocertif/cache").toHybrisStr);
        FilePath* filesDir = FilePath.create(*expandTilde("~/.config/octocertif").toHybrisStr);

        auto langs = string_vector_create();
        scope (exit)
        string_vector_delete(langs);
        string_vector_push_back(langs, "fr".toStringz);

        ContentBundle* contentBundle = ContentBundle.create(*baseDir, *cacheDir, *filesDir, *langs);
        auto contentBundlePtr = create_shared(contentBundle);
        rcConfigPtr.get().setContentBundle(contentBundlePtr);

        rcConfigPtr.get().setFairPlayDirectoryPath(*expandTilde("~/.config/octocertif/fairPlay").toHybrisStr);

        logln!()("Application de la configuration... ", LogPriority.verbeux);
        import provision.android.requestcontextmanager;

        RequestContextManager.configure(contextPtr);
        StoreErrorCondition errorCode = contextPtr.get().initialize(rcConfigPtr);
        auto initErrorCode = errorCode.errorCode();
        if (initErrorCode == ErrorCode.success) {
            logln!()("succès !", LogPriority.verbeux);
        } else {
            logln!(typeof(initErrorCode))("Échec... (code %d) ", initErrorCode, LogPriority.verbeux);
            return initErrorCode;
        }

        import provision.android.androidpresentationinterface;
        auto androidPrez = AndroidPresentationInterface.makeShared();
        androidPrez.get().setDialogHandler((l, pd, adrh) {
            logln("appel du dialog handler");
        });
        androidPrez.get().setCredentialsHandler((cr, adrh) {
            logln("cancel btn title: %s", cr.get().cancelButtonTitle().toDString);
            //logln("Titre: %s", cr.get().context().toDString);
            logln("pw: %s", cr.get().initialPassword().toDString);
            logln("un: %s", cr.get().initialUserName().toDString);
            logln("msg: %s", cr.get().message().toDString);
            //logln("Titre: %s", cr.get().okButtonAction().toDString);
            logln("action type: %s", cr.get().okButtonAction().get().actionType().toDString);
            logln("ok btn title: %s", cr.get().okButtonTitle().toDString);
            logln("title: %s", cr.get().title().toDString);
            logln("is require h2a: %s", cr.get().requiresHSA2VerificationCode());
            //logln("Titre: %s", cr.get().dialog().toDString);

            auto rcContext = cr.get().context();
            cr.get().okButtonAction().get().performWithContext(rcContext);
            logln("executed");
        });

        contextPtr.get().setPresentationInterface(androidPrez);

        logln!()("On passe à l'approvisionnement...", LogPriority.verbeux);

        import provision.android.anisetteprotocolaction;

        auto headers = str_str_multimap_create();
        scope (exit)
            str_str_multimap_delete(headers);

        auto md_action = libraryBundleInstance[Library.LIBSTORESERVICESCORE].loadSymbol!(
                void*)("_ZN17storeservicescore15XAppleAMDActionE");
        auto md_data = libraryBundleInstance[Library.LIBSTORESERVICESCORE].loadSymbol!(
                void*)("_ZN17storeservicescore13XAppleAMDDataE");
        headers.str_str_multimap_insert(md_action, md_data);

        //contextPtr.get().mescal();

        //AnisetteProtocolAction* a = AnisetteProtocolAction.allocate();
        //AnisetteProtocolAction* anis = a.actionForHeaders(*headers, AnisetteProtocolVersion.anonymous);
        //
        //writefln("%s %s", a.protocolVersion, anis.protocolVersion);

//        import std.net.curl;
//        auto client = HTTP();
//        client.handle.set(CurlOption.ssl_verifypeer, 0);
//        client.setUserAgent("akd/1.0 CFNetwork/808.1.4 Darwin/16.1.0");
//        client.addRequestHeader("Accept", "*/*");
//        client.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
//        client.addRequestHeader("Accept-Language", "fr-fr");
//        client.addRequestHeader("X-Apple-I-SRL-NO", "");
//        client.addRequestHeader("X-MMe-Client-Info", format!"<%s> <%s;%s;%s> <com.apple.akd/1.0 (com.apple.akd/1.0)>"("PC", "Windows", "6.2(0,0)", "9200")); // device model, device operating system, os version, os build
//        client.addRequestHeader("Accept-Encoding", "gzip"); // , deflate
//        // client.addRequestHeader("X-Mme-Device-Id", lpUdid);
//        string content = cast(string) post("https://gsa.apple.com/grandslam/MidService/startMachineProvisioning",
//        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
//<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
//<plist version=\"1.0\">
//<dict>
//<key>Header</key>
//<dict/>
//<key>Request</key>
//<dict/>
//</dict>
//</plist>"
//        , client);
//
//        import plist;
//        import plist.types;
//        Plist pl = new Plist();
//        pl.read(content);
//
//        struct MachineProvisionRequestAnswer {
//            struct _response {
//                struct _status {
//                    @PlistKey("ed") string ed;
//                    @PlistKey("ec") long ec;
//                    @PlistKey("em") string em;
//                }
//                @PlistKey("Status") _status Status;
//                @PlistKey("spim") string spim;
//            }
//            @PlistKey("Response") _response Response;
//            struct _header {}
//            @PlistKey("Header") _header Header;
//        }
//
//        PlistElementDict dict = cast(PlistElementDict) pl[0];
//        MachineProvisionRequestAnswer answer;
//        dict.coerceToNative!MachineProvisionRequestAnswer(answer);
//
//        import std.base64;
//        shared_ptr!Data data = create_shared(Data.fromByteArray(Base64.decode(answer.Response.spim)));
//
//        import provision.android.mescal;
//        Mescal* mescal = Mescal.create(contextPtr);
//
//        mescal.sign(data);

        import provision.android.authenticateflow;
        AuthenticateFlow* flow = AuthenticateFlow.create(contextPtr);

        auto dur = std_duration_create();
        scope(exit) std_duration_delete(dur);
        //flow.runWithTimeout(*dur);
        flow._promptForCredentials();
        //flow._authenticateUsingExistingAccount(*dur);
        //flow._saveAuthHeaders();

        logln!()("Nettoyage...", LogPriority.verbeux);
    }

    return 0;
}
