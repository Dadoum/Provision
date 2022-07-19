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

import provision.plist;

@nogc:

alias ADILoadLibraryWithPath_t = extern(C) int function(immutable char*);
alias ADISetAndroidID_t = extern(C) int function(immutable char*, uint);
alias ADISetProvisioningPath_t = extern(C) int function(immutable char*);

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

@nogc public struct ADI {
    private string path;
    private string identifier;
    private ulong dsId;

    private string[string] urlBag;
    private string[string] __customHeaders;

    AndroidLibrary* libcoreadi;
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
    ADISetIDMSRouting_t pADISetIDMSRouting;
    ADIGetIDMSRouting_t pADIGetIDMSRouting;

    string __clientInfo = "<iMac11,3> <Mac OS X;10.15.6;19G2021> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
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

    public @property string deviceId() {
        return sha1Of(this.identifier).toHexString().toUpper().dup();
    }

    public @property string localUserUUID() {
        return sha256Of(this.identifier).toHexString().toUpper().dup();
    }

    public @property string[string] customHeaders() {
        return this.__customHeaders;
    }

    @disable this();

    public this(string provisioningPath, string identifier = null) {
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

        if (!(exists(libraryPath ~ "libCoreADI.so") && exists(libraryPath ~ "libstoreservicescore.so"))) {
            stderr.fprintf("Apple libraries are not installed correctly. Refer to README for instructions. ");
            abort();
        }

        this.libcoreadi = New! AndroidLibrary(libraryPath ~ "libCoreADI.so");
        this.libstoreservicescore = New!AndroidLibrary(libraryPath ~ "libstoreservicescore.so");

        this.pADILoadLibraryWithPath = cast(ADILoadLibraryWithPath_t) libstoreservicescore.load("kq56gsgHG6");
        this.pADISetAndroidID = cast(ADISetAndroidID_t) libstoreservicescore.load("Sph98paBcz");
        this.pADISetProvisioningPath = cast(ADISetProvisioningPath_t) libstoreservicescore.load("nf92ngaK92");

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

        if (identifier == null)
            this.identifier = genAndroidId;
        else
            this.identifier = identifier;

        this.path = provisioningPath;
        pADISetProvisioningPath(/+path+/ path.toStringz);
        // pADILoadLibraryWithPath(/+path+/ applePrefix.toStringz);
        pADISetAndroidID(/+identifierStr+/ identifier.toStringz, /+length+/ cast(uint) identifier.length);

        dsId = -2;
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

        if (__customHeaders !is null) {
            foreach (customHeader; customHeaders.byKeyValue()) {
                client.addRequestHeader(customHeader.key, customHeader.value);
            }
        }

        return client;
    }

    private void populateUrlBag(HTTP client) {
        auto content = cast(string) std.net.curl.get("https://gsa.apple.com/grandslam/GsService2/lookup", client);

        PlistDict plist = cast(PlistDict) Plist.fromXml(content);
        auto response = cast(PlistDict) plist["urls"];
        auto responseIter = response.iter();
        Plist val;
        string key;
        while (responseIter.next(val, key)) {
            urlBag[key] = cast(string) cast(PlistString) val;
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

        auto spimPlist = cast(PlistDict) Plist.fromXml(content);
        auto spimResponse = cast(PlistDict) spimPlist["Response"];
        string spimStr = cast(string) cast(PlistString) spimResponse["spim"];

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

        PlistDict plist = cast(PlistDict) Plist.fromXml(content);
        PlistDict spimResponse = cast(PlistDict) plist["Response"];

        struct SecondStepAnswers {
            string rinfo;
            ubyte[] tk;
            ubyte[] ptm;
        }

        SecondStepAnswers secondStepAnswers = SecondStepAnswers();
        secondStepAnswers.rinfo = cast(string) cast(PlistString) spimResponse["X-Apple-I-MD-RINFO"];
        secondStepAnswers.tk = Base64.decode(cast(string) cast(PlistString) spimResponse["tk"]);
        secondStepAnswers.ptm = Base64.decode(cast(string) cast(PlistString) spimResponse["ptm"]);

        return secondStepAnswers;
    }

    public bool isMachineProvisioned() {
        return pADIGetLoginCode(dsId) == 0;
    }

    public uint provisionDevice(out ulong routingInformation) {
        auto client = makeHttpClient();

        client.addRequestHeader("X-Mme-Client-Info", clientInfo);
        client.addRequestHeader("X-Mme-Device-Id", deviceId);
        client.addRequestHeader("X-Apple-I-MD-LU", localUserUUID);
        client.addRequestHeader("X-Apple-I-SRL-NO", serialNo);

        populateUrlBag(client);

        pADIProvisioningErase(dsId);

        ubyte[] spim = downloadSPIM(client);

        ubyte* cpimPtr;
        uint l;

        uint session;

        int ret = pADIProvisioningStart(
        /+dsId+/ dsId,
        /+spim ptr+/ spim.ptr,
        /+spim length+/ cast(uint) spim.length,
        /+(out) cpim ptr+/ &cpimPtr,
        /+(out) cpim length+/ &l,
        /+(out) session+/ &session
        );

        if (ret)
            return 1;

        ubyte[] cpim = cpimPtr[0..l];

        auto secondStep = sendCPIM(client, cpim);
        routingInformation = to!ulong(secondStep.rinfo);

        ret = pADISetIDMSRouting(
        routingInformation,
        dsId,
        );

        if (ret)
            return 2;

        ret = pADIProvisioningEnd(
        session,
        secondStep.ptm.ptr,
        cast(uint) secondStep.ptm.length,
        secondStep.tk.ptr,
        cast(uint) secondStep.tk.length
        );

        if (ret)
            return 3;

        ret = pADIDispose(cpimPtr);

        if (ret)
            return 4;

        return 0;
    }

    public uint getOneTimePassword(out ubyte[] machineId, out ubyte[] oneTimePassword) {
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

        if (ret)
            return 1;

        machineId = midPtr[0..midLen].dup;
        oneTimePassword = otpPtr[0..otpLen].dup;

        ret = pADIDispose(midPtr);

        if (ret)
            return 2;

        ret = pADIDispose(otpPtr);

        if (ret)
            return 3;
    }

    public uint getRoutingInformation(out ulong routingInfo) {
        auto ret = pADIGetIDMSRouting(
        /+(out) routingInfo+/ &routingInfo,
        /+accountID+/ dsId,
        );

        if (ret)
            return 1;
    }
}

// public class AnisetteException: Exception {
//     this(int error, string file = __FILE__, ulong line = __LINE__) {
//         string msg;
//         if (error == -45054) {
//             msg = "ADI error: cannot create folder. ";
//         } else {
//             msg = format!"ADI error: %d"(error);
//         }
//         super(msg, file, line);
//     }
// }
//