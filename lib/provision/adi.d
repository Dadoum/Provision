module provision.adi;

import provision.androidlibrary;
import std.base64;
import std.conv;
import std.digest.sha;
import file = std.file;
import std.format;
import std.json;
import std.path;
import std.string;

import requests;

import slf4d;

import provision.compat.general;

version (LibPlist) {
    import plist;
} else {
    import plist;
    import plist.types;
}

alias ADILoadLibraryWithPath_t = extern(C) int function(const char*);
alias ADISetAndroidID_t = extern(C) int function(const char*, uint);
alias ADISetProvisioningPath_t = extern(C) int function(const char*);
alias ADIProvisioningErase_t = extern(C) int function(ulong);
alias ADISynchronize_t = extern(C) int function(ulong, ubyte*, uint, ubyte**, uint*, ubyte**, uint*);
alias ADIProvisioningDestroy_t = extern(C) int function(uint);
alias ADIProvisioningEnd_t = extern(C) int function(uint, ubyte*, uint, ubyte*, uint);
alias ADIProvisioningStart_t = extern(C) int function(ulong, ubyte*, uint, ubyte**, uint*, uint*);
alias ADIGetLoginCode_t = extern(C) int function(ulong);
alias ADIDispose_t = extern(C) int function(void*);
alias ADIOTPRequest_t = extern(C) int function(ulong, ubyte**, uint*, ubyte**, uint*);

public class ADI {
    package ADILoadLibraryWithPath_t pADILoadLibraryWithPath;
    package ADISetAndroidID_t pADISetAndroidID;
    package ADISetProvisioningPath_t pADISetProvisioningPath;

    package ADIProvisioningErase_t pADIProvisioningErase;
    package ADISynchronize_t pADISynchronize;
    package ADIProvisioningDestroy_t pADIProvisioningDestroy;
    package ADIProvisioningEnd_t pADIProvisioningEnd;
    package ADIProvisioningStart_t pADIProvisioningStart;
    package ADIGetLoginCode_t pADIGetLoginCode;
    package ADIDispose_t pADIDispose;
    package ADIOTPRequest_t pADIOTPRequest;

    private AndroidLibrary storeServicesCore;
    private Logger logger;

    private string __provisioningPath = null;
    public string provisioningPath() {
        return __provisioningPath;
    }

    public void provisioningPath(string path) {
        __provisioningPath = path;
        androidInvoke!pADISetProvisioningPath(path.toStringz).unwrapADIError();
    }

    private string __identifier = null;
    public string identifier() {
        return __identifier;
    }

    public void identifier(string identifier) {
        __identifier = identifier;
        androidInvoke!pADISetAndroidID(identifier.ptr, cast(uint) identifier.length).unwrapADIError();
    }

    public this(string libraryPath) {
        string storeServicesCorePath = libraryPath.buildPath("libstoreservicescore.so");
        if (!file.exists(storeServicesCorePath)) {
            throw new file.FileException(storeServicesCorePath);
        }

        this(libraryPath, new AndroidLibrary(storeServicesCorePath));
    }

    public this(string libraryPath, AndroidLibrary storeServicesCore) {
        this.storeServicesCore = storeServicesCore;
        this.logger = getLogger();

        // We are loading the symbols from the ELF library from their name.
        // Those has been obfuscated but they keep a consistent obfuscated name, like a hash function would.
        logger.debug_("Loading Android-specific symbols…");

        pADILoadLibraryWithPath = cast(ADILoadLibraryWithPath_t) storeServicesCore.load("kq56gsgHG6");
        pADISetAndroidID = cast(ADISetAndroidID_t) storeServicesCore.load("Sph98paBcz");
        pADISetProvisioningPath = cast(ADISetProvisioningPath_t) storeServicesCore.load("nf92ngaK92");

        logger.debug_("Loading ADI symbols…");

        pADIProvisioningErase = cast(ADIProvisioningErase_t) storeServicesCore.load("p435tmhbla");
        pADISynchronize = cast(ADISynchronize_t) storeServicesCore.load("tn46gtiuhw");
        pADIProvisioningDestroy = cast(ADIProvisioningDestroy_t) storeServicesCore.load("fy34trz2st");
        pADIProvisioningEnd = cast(ADIProvisioningEnd_t) storeServicesCore.load("uv5t6nhkui");
        pADIProvisioningStart = cast(ADIProvisioningStart_t) storeServicesCore.load("rsegvyrt87");
        pADIGetLoginCode = cast(ADIGetLoginCode_t) storeServicesCore.load("aslgmuibau");
        pADIDispose = cast(ADIDispose_t) storeServicesCore.load("jk24uiwqrg");
        pADIOTPRequest = cast(ADIOTPRequest_t) storeServicesCore.load("qi864985u0");

        logger.debug_("Loading libraries…");
        loadLibrary(libraryPath);

        logger.debug_("Initialization…");

        // We are setting those to be sure to have the same value in the class (used in getter) and the real one in ADI.
        logger.debug_("Initialization complete !");
    }

    ~this() {
        if (storeServicesCore) {
            destroy(storeServicesCore);
        }
    }

    public void loadLibrary(string libraryPath) {
        androidInvoke!pADILoadLibraryWithPath(cast(const(char*)) libraryPath.toStringz).unwrapADIError();
    }

    public void eraseProvisioning(ulong dsId) {
        androidInvoke!pADIProvisioningErase(dsId).unwrapADIError();
    }

    struct SynchronizationResumeMetadata {
        public ubyte[] synchronizationResumeMetadata;
        public ubyte[] machineIdentifier;
        private ADI adi;

        @disable this();
        @disable this(this);

        this(ADI adiInstance, ubyte* srm, uint srmLength, ubyte* mid, uint midLength) {
            adi = adiInstance;
            synchronizationResumeMetadata = srm[0..srmLength];
            machineIdentifier = mid[0..midLength];
        }

        ~this() {
            adi.dispose(synchronizationResumeMetadata.ptr);
            adi.dispose(machineIdentifier.ptr);
        }
    }

    public SynchronizationResumeMetadata synchronize(ulong dsId, ubyte[] serverIntermediateMetadata) {
        ubyte* srm;
        uint srmLength;
        ubyte* mid;
        uint midLength;

        androidInvoke!pADISynchronize(
            dsId,
            serverIntermediateMetadata.ptr,
 cast(uint) serverIntermediateMetadata.length,
            &mid,
            &midLength,
            &srm,
            &srmLength
        ).unwrapADIError();

        return SynchronizationResumeMetadata(this, srm, srmLength, mid, midLength);
    }

    public void destroyProvisioning(uint session) {
        androidInvoke!pADIProvisioningDestroy(session).unwrapADIError();
    }

    public void endProvisioning(uint session, ubyte[] persistentTokenMetadata, ubyte[] trustKey) {
        androidInvoke!pADIProvisioningEnd(
            session,
            persistentTokenMetadata.ptr,
 cast(uint) persistentTokenMetadata.length,
            trustKey.ptr,
 cast(uint) trustKey.length
        ).unwrapADIError();
    }

    struct ClientProvisioningIntermediateMetadata {
        public ubyte[] clientProvisioningIntermediateMetadata;
        public uint session;
        private ADI adi;

        @disable this();
        @disable this(this);

        this(ADI adiInstance, ubyte* cpim, uint cpimLength, uint session) {
            adi = adiInstance;
            clientProvisioningIntermediateMetadata = cpim[0..cpimLength];
            this.session = session;
        }

        ~this() {
            adi.dispose(clientProvisioningIntermediateMetadata.ptr);
        }
    }

    public ClientProvisioningIntermediateMetadata startProvisioning(ulong dsId, ubyte[] serverProvisioningIntermediateMetadata) {
        ubyte* cpim;
        uint cpimLength;
        uint session;

        androidInvoke!pADIProvisioningStart(
            dsId,
            serverProvisioningIntermediateMetadata.ptr,
 cast(uint) serverProvisioningIntermediateMetadata.length,
            &cpim,
            &cpimLength,
            &session
        ).unwrapADIError();

        return ClientProvisioningIntermediateMetadata(this, cpim, cpimLength, session);
    }

    public bool isMachineProvisioned(ulong dsId) {
        int errorCode = androidInvoke!pADIGetLoginCode(dsId);

        if (errorCode == 0) {
            return true;
        } else if (errorCode == -45061) {
            return false;
        }

        throw new ADIException(errorCode);
    }

    public void dispose(void* ptr) {
        androidInvoke!pADIDispose(ptr).unwrapADIError();
    }

    struct OneTimePassword {
        public ubyte[] oneTimePassword;
        public ubyte[] machineIdentifier;
        private ADI adi;

        @disable this();
        @disable this(this);

        this(ADI adiInstance, ubyte* otp, uint otpLength, ubyte* mid, uint midLength) {
            adi = adiInstance;
            oneTimePassword = otp[0..otpLength];
            machineIdentifier = mid[0..midLength];
        }

        ~this() {
            adi.dispose(oneTimePassword.ptr);
            adi.dispose(machineIdentifier.ptr);
        }
    }

    public OneTimePassword requestOTP(ulong dsId) {
        ubyte* otp;
        uint otpLength;
        ubyte* mid;
        uint midLength;

        androidInvoke!pADIOTPRequest(
            dsId,
            &mid,
            &midLength,
            &otp,
            &otpLength
        ).unwrapADIError();

        return OneTimePassword(this, otp, otpLength, mid, midLength);
    }
}

public class Device {
    JSONValue deviceData;

    enum uniqueDeviceIdentifierJson = "UUID";
    enum serverFriendlyDescriptionJson = "clientInfo";
    enum adiIdentifierJson = "identifier";
    enum localUserUUIDJson = "localUUID";

    string uniqueDeviceIdentifier() { return deviceData[uniqueDeviceIdentifierJson].str(); }
    string serverFriendlyDescription() { return deviceData[serverFriendlyDescriptionJson].str(); }
    string adiIdentifier() { return deviceData[adiIdentifierJson].str(); }
    // It is a value computed by AuthKit. On Windows, it takes the path to the home folder and hash every component in.
    // We could do the same thing but anyway we can also just hash the ADI identifier, that's good too.
    string localUserUUID() { return deviceData[localUserUUIDJson].str(); }

    void uniqueDeviceIdentifier(string value) { deviceData[uniqueDeviceIdentifierJson] = value; write(); }
    void serverFriendlyDescription(string value) { deviceData[serverFriendlyDescriptionJson] = value; write(); }
    void adiIdentifier(string value) { deviceData[adiIdentifierJson] = value; write(); }
    void localUserUUID(string value) { deviceData[localUserUUIDJson] = value; write(); }

    // We could generate that, but we servers don't care so anyway
    // string logicBoardSerialNumber;
    // string romAddress;
    // string machineSerialNumber;

    bool initialized = false;
    string path;

    this(string filePath) {
        path = filePath;
        if (file.exists(path)) {
            try {
                JSONValue deviceFile = parseJSON(cast(char[]) file.read(filePath));
                uniqueDeviceIdentifier = deviceFile[uniqueDeviceIdentifierJson].str();
                serverFriendlyDescription = deviceFile[serverFriendlyDescriptionJson].str();
                adiIdentifier = deviceFile[adiIdentifierJson].str();
                localUserUUID = deviceFile[localUserUUIDJson].str();
                initialized = true;
            } catch (Throwable) { /+ do nothing +/ }
        }
    }

    public void write(string path) {
        this.path = path;
        write();
    }

    public void write() {
        if (path) {
            file.write(path, deviceData.toString());
            initialized = true;
        }
    }
}

public class ProvisioningSession {
    private Request request;
    private string[string] urlBag;

    private ADI adi;
    private Device device;

    public this(ADI adi, Device device) {
        this.adi = adi;
        this.device = device;

        request = Request();

        request.sslSetVerifyPeer(false);
        request.addHeaders([
            "User-Agent": "akd/1.0 CFNetwork/1404.0.5 Darwin/22.3.0",

            // they are somehow not using the plist content-type in AuthKit
            "Content-Type": "application/x-www-form-urlencoded",
            "Connection": "keep-alive",

            "X-Mme-Device-Id": device.uniqueDeviceIdentifier,
            // on macOS, MMe for the Client-Info header is written with 2 caps, while on Windows it is Mme...
            // and HTTP headers are supposed to be case-insensitive in the HTTP spec...
            "X-MMe-Client-Info": device.serverFriendlyDescription,
            "X-Apple-I-MD-LU": device.localUserUUID,

            // "X-Apple-I-MLB": device.logicBoardSerialNumber, // 17 letters, uppercase in Apple's base 34
            // "X-Apple-I-ROM": device.romAddress, // 6 bytes, lowercase hexadecimal
            // "X-Apple-I-SRL-NO": device.machineSerialNumber, // 12 letters, uppercase

            // different apps can be used, I already saw fmfd and Setup here
            // and Reprovision uses Xcode in some requests, so maybe it is possible here too.
            "X-Apple-Client-App-Name": "Setup",
        ]);
    }

    public void loadURLBag() {
        string content = request.get("https://gsa.apple.com/grandslam/GsService2/lookup").responseBody.data!string();

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

    public void provision(ulong dsId) {
        if (urlBag.length == 0) {
            loadURLBag();
        }

        import std.datetime.systime;

        request.headers["X-Apple-I-Client-Time"] = Clock.currTime().stripMilliseconds().toISOExtString();
        string startProvisioningPlist = request.post(urlBag["midStartProvisioning"],
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
\t<key>Header</key>
\t<dict/>
\t<key>Request</key>
\t<dict/>
</dict>
</plist>").responseBody.data!string();

        scope string spimStr;
        {
            version (LibPlist) {
                scope auto spimPlist = cast(PlistDict) Plist.fromXml(startProvisioningPlist);
                scope auto spimResponse = cast(PlistDict) spimPlist["Response"];
                spimStr = cast(string) cast(PlistString) spimResponse["spim"];
            } else {
                Plist spimPlist = new Plist();
                spimPlist.read(startProvisioningPlist);
                PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (spimPlist[0]))["Response"];
                spimStr = (cast(PlistElementString) spimResponse["spim"]).value;
            }
        }

        scope ubyte[] spim = Base64.decode(spimStr);

        scope auto cpim = adi.startProvisioning(dsId, spim);
        scope (failure) try { adi.destroyProvisioning(cpim.session); } catch(Throwable) {}

        request.headers["X-Apple-I-Client-Time"] = Clock.currTime().stripMilliseconds().toISOExtString();
        string endProvisioningPlist = request.post(urlBag["midFinishProvisioning"], format!"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
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
</plist>"(Base64.encode(cpim.clientProvisioningIntermediateMetadata))).responseBody.data!string();

        scope ulong routingInformation;
        scope ubyte[] persistentTokenMetadata;
        scope ubyte[] trustKey;

        {
            version (LibPlist) {
                scope PlistDict plist = cast(PlistDict) Plist.fromXml(endProvisioningPlist);
                scope PlistDict spimResponse = cast(PlistDict) plist["Response"];
                routingInformation = to!ulong(cast(string) cast(PlistString) spimResponse["X-Apple-I-MD-RINFO"]);
                persistentTokenMetadata = Base64.decode(cast(string) cast(PlistString) spimResponse["ptm"]);
                trustKey = Base64.decode(cast(string) cast(PlistString) spimResponse["tk"]);
            } else {
                scope Plist plist = new Plist();
                plist.read(endProvisioningPlist);
                scope PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (plist[0]))["Response"];

                routingInformation = to!ulong((cast(PlistElementString) spimResponse["X-Apple-I-MD-RINFO"]).value);
                persistentTokenMetadata = Base64.decode((cast(PlistElementString) spimResponse["ptm"]).value);
                trustKey = Base64.decode((cast(PlistElementString) spimResponse["tk"]).value);
            }
        }

        adi.endProvisioning(cpim.session, persistentTokenMetadata, trustKey);
    }
}

void unwrapADIError(int error, string file = __FILE__, size_t line = __LINE__) {
    if (error) {
        throw new ADIException(error, file, line);
    }
}

enum ADIError: int {
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

string toString(ADIError error) {
    string formatString;
    switch (cast(int) error) {
        case -45001:
            formatString = "invalid parameters (%d), or missing initialization bits, you need to set an identifier and a valid provisioning path first!";
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

public class ADIException: Exception {
    private ADIError errorCode;

    this(int error, string file = __FILE__, size_t line = __LINE__) {
        this.errorCode = cast(ADIError) error;
        super(errorCode.toString(), file, line);
    }

    ADIError adiError() {
        return errorCode;
    }
}

import std.datetime: dur, SysTime;
private SysTime stripMilliseconds(return SysTime time) {
    time.fracSecs = dur!"msecs"(0);
    return time;
}
