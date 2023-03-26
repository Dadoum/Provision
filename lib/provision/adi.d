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

@nogc public struct ADI {
    private string path;
    private ulong dsId;

    private string __identifier;
    private string[string] urlBag;

    AndroidLibrary* libstoreservicescore;

    ADILoadLibraryWithPath_t pADILoadLibraryWithPath;
    ADISetAndroidID_t pADISetAndroidID;
    ADISetProvisioningPath_t pADISetProvisioningPath;

    ADIProvisioningErase_t pADIProvisioningErase;
    ADISynchronize_t pADISynchronize;
    ADIProvisioningDestroy_t pADIProvisioningDestroy;
    ADIProvisioningEnd_t pADIProvisioningEnd;
    ADIProvisioningStart_t pADIProvisioningStart;
    ADIGetLoginCode_t pADIGetLoginCode;
    ADIDispose_t pADIDispose;
    ADIOTPRequest_t pADIOTPRequest;

    string __clientInfo = "<MacBookPro13,2> <macOS;13.1;22C65> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
    public @property string clientInfo() {
        return __clientInfo;
    }

    public @property void clientInfo(string value) {
        __clientInfo = value;
    }

    string __serialNo = "0";
    public @property string serialNo() {
        return __serialNo;
    }

    public @property void serialNo(string value) {
        __serialNo = value;
    }

    public @property string provisionPath() {
        return this.path;
    }

    public void identifier(string value) {
        pADISetAndroidID(/+identifierStr+/ value.toStringz, /+length+/ cast(uint) value.length);
        __identifier = value;
    }

    public string identifier() {
        return __identifier;
    }

    public @property string deviceId() {
        return sha1Of(this.identifier).toHexString().toUpper().dup();
    }

    public @property string localUserUUID() {
        return sha256Of(this.identifier).toHexString().toUpper().dup();
    }

    @disable this();

    public this(string provisioningPath, char[] identifier = null) {
        if (!exists(libraryPath ~ "libstoreservicescore.so")) {
            throw new FileException(libraryPath ~ "libstoreservicescore.so", "Apple libraries are not installed correctly. Refer to README for instructions. ");
        }

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

        debug {
            stderr.writeln("First calls...");
        }

        pADILoadLibraryWithPath(/+path+/ libraryPath.toStringz);

        this.path = provisioningPath;
        pADISetProvisioningPath(/+path+/ path.toStringz);

        if (identifier == null)
            this.identifier = cast(string) genAndroidId();
        else
            this.identifier = cast(string) identifier;

        debug {
            stderr.writeln("Setting fields...");
        }

        dsId = -2;

        debug {
            stderr.writeln("Ctor done !");
        }
    }

    private HTTP makeHttpClient() {
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

        return client;
    }

    private void populateUrlBag(HTTP client) {
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

    private ubyte[] downloadSPIM(HTTP client) {
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

    auto sendCPIM(HTTP client, ubyte[] cpim) {
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

    public bool isMachineProvisioned() {
        debug {
            stderr.writeln("isMachineProvisioned called !");
        }

        int loginCode = pADIGetLoginCode(dsId);

        debug {
            stderr.writefln("isMachineProvisioned -> %d", loginCode);
        }

        if (loginCode == 0) {
            return true;
        } else if (loginCode == -45061) {
            return false;
        }
        throw new AnisetteException(loginCode);
    }

    public void provisionDevice(out ulong routingInformation) {
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

    public void getOneTimePassword(bool writeMachineId = true)(out ubyte[] machineId, out ubyte[] oneTimePassword) {
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

        static if (writeMachineId) {
            machineId = midPtr[0..midLen].dup;
        }
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

    public void getRoutingInformation(out ulong routingInfo) {
        debug {
            stderr.writeln("getRoutingInformation ignored");
        }

        routingInfo = 17106176;
    }
}

enum AnisetteError: int {
    invalidParams = -45001,
    invalidParams2 = -45002,
    invalidTrustKey = -45003,
    ptmTkNotMatchingState = -45006,
    invalidInputDataParamHeader = -45018,
    unknownAdiFunction = -45019,
    invalidInputDataParamBody = -45020,
    unknownSession = -45025,
    emptySession = -45026,
    invalidDataHeader = -45031,
    dataTooShort = -45032,
    invalidDataBody = -45033,
    unknownADICallFlags = -45034,
    timeError = -45036,
    emptyHardwareIds = -45046,
    filesystemError = -45054,
    notProvisioned = -45061,
    noProvisioningToErase = -45062,
    pendingSession = -45063,
    sessionAlreadyDone = -45066,
    libraryLoadingFailed = -45075,
}

string toString(AnisetteError error) {
    string formatString;
    switch (cast(int) error) {
        case -45001:
            formatString = "invalid parameters (%d)";
            break;
        case -45002:
            formatString = "invalid parameters (for decipher) (%d)";
            break;
        case -45003:
            formatString = "invalid Trust Key (%d)";
            break;
        case -45006:
            formatString = "ptm and tk are not matching the transmitted cpim (%d)";
            break;
        // -45017: exists (observed: iOS), unknown meaning
        case -45018:
            formatString = "invalid input data header (first uint) (pointer is correct tho) (%d)";
            break;
        case -45019:
            formatString = "vdfut768ig doesn't know the asked function (%d)";
            break;
        case -45020:
            formatString = "invalid input data (not the first uint) (%d)";
            break;
        case -45025:
            formatString = "unknown session (%d)";
            break;
        case -45026:
            formatString = "empty session (%d)";
            break;
        case -45031:
            formatString = "invalid data (header) (%d)";
            break;
        case -45032:
            formatString = "data too short (%d)";
            break;
        case -45033:
            formatString = "invalid data (body) (%d)";
            break;
        case -45034:
            formatString = "unknown ADI call flags (%d)";
            break;
        case -45036:
            formatString = "time error (%d)";
            break;
        // -45044: exists (observed: macOS iTunes, from Google), unknown meaning
        // -45045: probably a typo of -45054
        case -45046:
            formatString = "identifier generation failure: empty hardware ids (%d)";
            break;
        // -45048: exists (observed: windows iTunes, from Google), unknown meaning, resolved by adi file suppression
        case -45054:
            formatString = "generic libc/file manipulation error (%d)";
            break;
        case -45061:
            formatString = "not provisioned (%d)";
            break;
        case -45062:
            formatString = "cannot erase provisioning: not provisioned (%d)";
            break;
        case -45063:
            formatString = "provisioning first step is already pending (%d)";
            break;
        case -45066:
            formatString = "2nd step fail: session already consumed (%d)";
            break;
        case -45075:
            formatString = "library loading error (%d)";
            break;
        // -45076: exists (observed: macOS iTunes, from Google), unknown meaning, seems related to backward compatibility between 12.6.x and 12.7
        default:
            formatString = "unknown ADI error (%d)";
            break;
    }
    return format(formatString, error);
}

public class AnisetteException: Exception {
    private AnisetteError errorCode;

    this(int error, string file = __FILE__, size_t line = __LINE__) {
        this.errorCode = cast(AnisetteError) error;
        super(errorCode.toString(), file, line);
    }

    AnisetteError anisetteError() {
        return errorCode;
    }
}
