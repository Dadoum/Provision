module provision.adi;

import provision.android.id;
import provision.androidlibrary;
import std.base64;
import std.conv;
import std.digest.sha;
import std.file;
import std.format;
import std.net.curl;
import std.stdio;
import std.string;

version (LibPlist) {
    import provision.plist;
} else {
    import plist;
    import plist.types;
}

alias ADILoadLibraryWithPath_t = extern(C) int function(const char*);
alias ADISetAndroidID_t = extern(C) int function(const char*, uint);
alias ADISetProvisioningPath_t = extern(C) int function(const char*);

alias ADIProvisioningErase_t = extern(C) int function(ulong);
alias ADISynchronize_t = extern(C) int function(uint, ubyte*, uint, ubyte**, uint*, ubyte**, uint*);
alias ADIProvisioningDestroy_t = extern(C) int function(uint);
alias ADIProvisioningEnd_t = extern(C) int function(uint, ubyte*, uint, ubyte*, uint);
alias ADIProvisioningStart_t = extern(C) int function(ulong, ubyte*, uint, ubyte**, uint*, uint*);
alias ADIGetLoginCode_t = extern(C) int function(ulong);
alias ADIDispose_t = extern(C) int function(void*);
alias ADIOTPRequest_t = extern(C) int function(ulong, ubyte**, uint*, ubyte**, uint*);
alias ADISetIDMSRouting_t = extern(C) int function(ulong, ulong);
alias ADIGetIDMSRouting_t = extern(C) int function(ulong*, ulong);

@nogc public shared struct ADI {
    private shared string path;
    private shared ulong dsId;

    private shared string __identifier;
    private shared string[string] urlBag;

    shared AndroidLibrary* libcoreadi;
    shared AndroidLibrary* libstoreservicescore;

    __gshared ADILoadLibraryWithPath_t pADILoadLibraryWithPath;
    __gshared ADISetAndroidID_t pADISetAndroidID;
    __gshared ADISetProvisioningPath_t pADISetProvisioningPath;

    __gshared ADIProvisioningErase_t pADIProvisioningErase;
    __gshared ADISynchronize_t pADISynchronize;
    __gshared ADIProvisioningDestroy_t pADIProvisioningDestroy;
    __gshared ADIProvisioningEnd_t pADIProvisioningEnd;
    __gshared ADIProvisioningStart_t pADIProvisioningStart;
    __gshared ADIGetLoginCode_t pADIGetLoginCode;
    __gshared ADIDispose_t pADIDispose;
    __gshared ADIOTPRequest_t pADIOTPRequest;
    __gshared ADISetIDMSRouting_t pADISetIDMSRouting;
    __gshared ADIGetIDMSRouting_t pADIGetIDMSRouting;

    string __clientInfo = "<MacBookPro17,1> <macOS;12.2.1;21D62> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
    public @property string clientInfo() shared {
        return __clientInfo;
    }

    public @property void clientInfo(string value) shared {
        __clientInfo = value;
    }

    shared string __serialNo = "0";
    public @property string serialNo() shared {
        return __serialNo;
    }

    public @property void serialNo(string value) shared {
        __serialNo = value;
    }

    public @property string provisionPath() shared {
        return this.path;
    }

    public void identifier(string value) shared {
        pADISetAndroidID(/+identifierStr+/ value.toStringz, /+length+/ cast(uint) value.length);
        __identifier = value;
    }

    public string identifier() shared {
        return __identifier;
    }

    public @property string deviceId() shared {
        return sha1Of(this.identifier).toHexString().toUpper().dup();
    }

    public @property string localUserUUID() shared {
        return sha256Of(this.identifier).toHexString().toUpper().dup();
    }

    @disable this();

    public shared this(string provisioningPath, char[] identifier = null) {
        version (X86_64) {
            enum string architectureIdentifier = "x86_64";
        } else version (X86) {
            enum string architectureIdentifier = "x86";
        } else version (AArch64) {
                enum string architectureIdentifier = "arm64-v8a";
            } else version (ARM) {
                    enum string architectureIdentifier = "armeabi-v7a";
                } else {
                    static assert(false, "Architecture not supported :(");
                }

        enum string libraryPath = "lib/" ~ architectureIdentifier ~ "/";

        initHybris();

        if (!exists(libraryPath ~ "libCoreADI.so")) {
            throw new FileException(libraryPath ~ "libCoreADI.so", "Apple libraries are not installed correctly. Refer to README for instructions. ");
        }

        if (!exists(libraryPath ~ "libstoreservicescore.so")) {
            throw new FileException(libraryPath ~ "libstoreservicescore.so", "Apple libraries are not installed correctly. Refer to README for instructions. ");
        }

        this.libcoreadi = new AndroidLibrary(libraryPath ~ "libCoreADI.so");
        this.libstoreservicescore = new AndroidLibrary(libraryPath ~ "libstoreservicescore.so");

        debug {
            stderr.writeln("Loading Android-specific symbols...");
        }

        this.pADILoadLibraryWithPath = cast(ADILoadLibraryWithPath_t) libstoreservicescore.load("kq56gsgHG6");
        this.pADISetAndroidID = cast(ADISetAndroidID_t) libstoreservicescore.load("Sph98paBcz");
        this.pADISetProvisioningPath = cast(ADISetProvisioningPath_t) libstoreservicescore.load("nf92ngaK92");

        debug {
            stderr.writeln("Loading ADI symbols...");
        }

        this.pADIProvisioningErase = cast(ADIProvisioningErase_t) libstoreservicescore.load("p435tmhbla");
        this.pADISynchronize = cast(ADISynchronize_t) libstoreservicescore.load("tn46gtiuhw");
        this.pADIProvisioningDestroy = cast(ADIProvisioningDestroy_t) libstoreservicescore.load("fy34trz2st");
        this.pADIProvisioningEnd = cast(ADIProvisioningEnd_t) libstoreservicescore.load("uv5t6nhkui");
        this.pADIProvisioningStart = cast(ADIProvisioningStart_t) libstoreservicescore.load("rsegvyrt87");
        this.pADIGetLoginCode = cast(ADIGetLoginCode_t) libstoreservicescore.load("aslgmuibau");
        this.pADIDispose = cast(ADIDispose_t) libstoreservicescore.load("jk24uiwqrg");
        this.pADIOTPRequest = cast(ADIOTPRequest_t) libstoreservicescore.load("qi864985u0");
        this.pADISetIDMSRouting = cast(ADISetIDMSRouting_t) libstoreservicescore.load("ksbafgljkb");
        this.pADIGetIDMSRouting = cast(ADIGetIDMSRouting_t) libstoreservicescore.load("madsvsfvjk");

        debug {
            stderr.writeln("Generating an identifier...");
        }

        debug {
            stderr.writeln("First calls...");
        }

        this.path = provisioningPath;
        pADISetProvisioningPath(/+path+/ path.toStringz);

        if (identifier == null)
            this.identifier = cast(string) genAndroidId();
        else
            this.identifier = cast(string) identifier;
        // pADILoadLibraryWithPath(/+path+/ applePrefix.toStringz);
        // pADISetAndroidID(/+identifierStr+/ identifier.toStringz, /+length+/ cast(uint) identifier.length);

        debug {
            stderr.writeln("Setting fields...");
        }

        dsId = -2;

        debug {
            stderr.writeln("Ctor done !");
        }
    }

    private HTTP makeHttpClient() shared {
        auto client = HTTP();

        client.setUserAgent("iCloud.exe (unknown version) CFNetwork/520.44.6");
        client.handle.set(CurlOption.ssl_verifypeer, 0);

        // debug {
        //     client.handle.set(CurlOption.verbose, 1);
        // }
        client.addRequestHeader("Accept", "*/*");
        client.addRequestHeader("Content-Type", "text/x-xml-plist");
        client.addRequestHeader("Accept-Language", "en");
        client.addRequestHeader("Accept-Encoding", "gzip, deflate");
        client.addRequestHeader("Connection", "keep-alive");
        client.addRequestHeader("Proxy-Connection", "keep-alive");

        // if (__customHeaders !is null) {
        //     foreach (customHeader; customHeaders.byKeyValue()) {
        //         client.addRequestHeader(customHeader.key, customHeader.value);
        //     }
        // }

        return client;
    }

    private void populateUrlBag(HTTP client) shared {
        auto content = cast(string) std.net.curl.get("https://gsa.apple.com/grandslam/GsService2/lookup", client);

        version (LibPlist) {
            PlistDict plist = cast(PlistDict) Plist.fromXml(content);
            auto response = cast(PlistDict) plist["urls"];
            auto responseIter = response.iter();
            Plist val;
            string key;
            while (responseIter.next(val, key)) {
                urlBag[key] = cast(string) cast(PlistString) val;
            }
        } else {
            Plist plist = new Plist();
            plist.read(cast(string) content);
            auto response = (cast(PlistElementDict) (cast(PlistElementDict) (plist[0]))["urls"]);

            foreach (key; response.keys()) {
                urlBag[key] = (cast(PlistElementString) response[key]).value;
            }
        }
    }

    private ubyte[] downloadSPIM(HTTP client) shared {
        import std.datetime.systime;
        auto time = Clock.currTime();

        client.addRequestHeader("X-Apple-I-Client-Time", time.toISOExtString());
        client.addRequestHeader("X-Apple-I-TimeZone", time.timezone().dstName);

        string content = cast(string) post(urlBag["midStartProvisioning"],
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
\t<key>Header</key>
\t<dict/>
\t<key>Request</key>
\t<dict/>
</dict>
</plist>
", client);

        string spimStr;
        version (LibPlist) {
            auto spimPlist = cast(PlistDict) Plist.fromXml(content);
            auto spimResponse = cast(PlistDict) spimPlist["Response"];
            spimStr = cast(string) cast(PlistString) spimResponse["spim"];
        } else {
            Plist spimPlist = new Plist();
            spimPlist.read(content);
            PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (spimPlist[0]))["Response"];
            spimStr = (cast(PlistElementString) spimResponse["spim"]).value;
        }

        return Base64.decode(spimStr);
    }

    auto sendCPIM(HTTP client, ubyte[] cpim) shared {
        string body_ = format!"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
\t<key>Header</key>
\t<dict/>
\t<key>Request</key>
\t<dict>
\t\t<key>cpim</key>
\t\t<string>%s</string>
\t</dict>
</dict>
</plist>
"(Base64.encode(cpim));

        import std.datetime.systime;
        auto time = Clock.currTime();

        client.addRequestHeader("X-Apple-I-Client-Time", time.toISOExtString());
        client.addRequestHeader("X-Apple-I-TimeZone", time.timezone().dstName);

        string content = cast(string) post(urlBag["midFinishProvisioning"],
        body_, client);

        struct SecondStepAnswers {
            string rinfo;
            ubyte[] tk;
            ubyte[] ptm;
        }

        SecondStepAnswers secondStepAnswers = SecondStepAnswers();

        version (LibPlist) {
            PlistDict plist = cast(PlistDict) Plist.fromXml(content);
            PlistDict spimResponse = cast(PlistDict) plist["Response"];
            secondStepAnswers.rinfo = cast(string) cast(PlistString) spimResponse["X-Apple-I-MD-RINFO"];
            secondStepAnswers.tk = Base64.decode(cast(string) cast(PlistString) spimResponse["tk"]);
            secondStepAnswers.ptm = Base64.decode(cast(string) cast(PlistString) spimResponse["ptm"]);
        } else {
            Plist plist = new Plist();
            plist.read(content);
            PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (plist[0]))["Response"];

            secondStepAnswers.rinfo = (cast(PlistElementString) spimResponse["X-Apple-I-MD-RINFO"]).value;
            secondStepAnswers.tk = Base64.decode((cast(PlistElementString) spimResponse["tk"]).value);
            secondStepAnswers.ptm = Base64.decode((cast(PlistElementString) spimResponse["ptm"]).value);
        }

        return secondStepAnswers;
    }

    public bool isMachineProvisioned() shared {
        debug {
            stderr.writeln("isMachineProvisioned called !");
        }

        int i = pADIGetLoginCode(dsId);

        debug {
            stderr.writefln("isMachineProvisioned -> %d", i);
        }

        return i == 0;
    }

    public void provisionDevice(out ulong routingInformation) shared {
        debug {
            stderr.writeln("provisionDevice called !");
        }
        auto client = makeHttpClient();

        client.addRequestHeader("X-Mme-Client-Info", clientInfo);
        client.addRequestHeader("X-Mme-Device-Id", deviceId);
        client.addRequestHeader("X-Apple-I-MD-LU", localUserUUID);
        client.addRequestHeader("X-Apple-I-SRL-NO", serialNo);

        debug {
            stderr.writeln("First request... (urlBag)");
        }

        populateUrlBag(client);

        debug {
            stderr.writeln("Erasing provisioning...");
        }

        pADIProvisioningErase(dsId);

        debug {
            stderr.writeln("Second request... (spim)");
        }

        ubyte[] spim = downloadSPIM(client);

        ubyte* cpimPtr;
        uint l;

        uint session;

        debug {
            stderr.writeln("Start provisioning...");
        }

        int ret = pADIProvisioningStart(
            /+dsId+/ dsId,
            /+spim ptr+/ spim.ptr,
            /+spim length+/ cast(uint) spim.length,
            /+(out) cpim ptr+/ &cpimPtr,
            /+(out) cpim length+/ &l,
            /+(out) session+/ &session
        );

        if (ret)
            throw new AnisetteException(ret);

        ubyte[] cpim = cpimPtr[0..l];

        debug {
            stderr.writeln("Third request... (ptm & tk)");
        }

        auto secondStep = sendCPIM(client, cpim);
        routingInformation = to!ulong(secondStep.rinfo);

        debug {
            stderr.writeln("setIDMSRouting...");
        }

        ret = pADISetIDMSRouting(
            routingInformation,
            dsId,
        );

        if (ret)
            throw new AnisetteException(ret);

        debug {
            stderr.writeln("End provisioning...");
        }

        ret = pADIProvisioningEnd(
            session,
            secondStep.ptm.ptr,
            cast(uint) secondStep.ptm.length,
            secondStep.tk.ptr,
            cast(uint) secondStep.tk.length
        );

        if (ret)
            throw new AnisetteException(ret);


        debug {
            stderr.writeln("Cleanup...");
        }

        ret = pADIDispose(cpimPtr);

        if (ret)
            throw new AnisetteException(ret);
    }

    public void getOneTimePassword(out ubyte[] machineId, out ubyte[] oneTimePassword) shared {
        debug {
            stderr.writeln("getOneTimePassword called !");
        }

        ubyte* midPtr;
        uint midLen;
        ubyte* otpPtr;
        uint otpLen;

        auto ret = pADIOTPRequest(
            /+accountID+/ dsId,
            /+(out) machineID+/ &midPtr, // X-Apple-I-MD-M
            /+(out) machineID length+/ &midLen,
            /+(out) oneTimePW+/ &otpPtr, // X-Apple-I-MD
            /+(out) oneTimePW length+/ &otpLen,
        );

        debug {
            stderr.writefln("getOneTimePassword -> %d", ret);
        }

        if (ret)
            throw new AnisetteException(ret);

        machineId = midPtr[0..midLen].dup;
        oneTimePassword = otpPtr[0..otpLen].dup;

        debug {
            stderr.writeln("Cleaning up...");
        }

        ret = pADIDispose(midPtr);

        if (ret)
            throw new AnisetteException(ret);

        ret = pADIDispose(otpPtr);

        if (ret)
            throw new AnisetteException(ret);
    }

    public void getRoutingInformation(out ulong routingInfo) shared {
        debug {
            stderr.writeln("getRoutingInformation ignored");
        }

        return;

        debug {
            stderr.writeln("getRoutingInformation called !");
        }

        auto ret = pADIGetIDMSRouting(
            /+(out) routingInfo+/ &routingInfo,
            /+accountID+/ dsId,
        );

        debug {
            stderr.writefln("getRoutingInformation -> %d", ret);
        }

        if (ret)
            throw new AnisetteException(ret);
    }
}

public class AnisetteException: Exception {
    this(int error, string file = __FILE__, size_t line = __LINE__) {
        super(format!"ADI error: %s."(translateADIErrorCode(error)), file, line);
    }
}

enum knownErrorCodes = [
    -45054: "cannot create folder",
    -45061: "invalid adi file"
];

string translateADIErrorCode(int errorCode) {
    foreach (knownErrorCode; knownErrorCodes.byKeyValue) {
        if (errorCode == knownErrorCode.key) {
            return knownErrorCode.value;
        }
    }

    return format!"%d"(errorCode);
}
