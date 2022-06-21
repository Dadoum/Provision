module provision.adi;

import provision.android.id;
import plist;
import plist.types;
import provision.ilibrary;
import std.base64;
import std.conv;
import std.digest.sha;
import std.file;
import std.format;
import std.net.curl;
import std.stdio;
import std.string;

alias ADISetProvisioningPath_t = extern(C) int function(immutable char*);
alias ADILoadLibraryWithPath_t = extern(C) int function(immutable char*);
alias ADISetAndroidID_t = extern(C) int function(immutable char*, uint);
alias ADIProvisioningStart_t = extern(C) int function(ulong, ubyte*, uint, ubyte**, uint*, uint*);
alias ADIProvisioningEnd_t = extern(C) int function(uint, ubyte*, uint, ubyte*, uint);
alias ADIOTPRequest_t = extern(C) int function(ulong, ubyte**, uint*, ubyte**, uint*);
alias ADISetIDMSRouting_t = extern(C) int function(ulong, ulong);
alias ADIGetIDMSRouting_t = extern(C) int function(ulong*, ulong);

public struct ADI {
    private string path;
    private string identifier;
    private ulong dsId;

    private string[string] urlBag;

    ILibrary libcoreadi;
    ILibrary libstoreservicescore;

    ADISetProvisioningPath_t pADISetProvisioningPath;
    ADILoadLibraryWithPath_t pADILoadLibraryWithPath;
    ADISetAndroidID_t pADISetAndroidID;
    ADIProvisioningStart_t pADIProvisioningStart;
    ADIProvisioningEnd_t pADIProvisioningEnd;
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

        import provision.androidlibrary;
        initHybris();

        if (!exists(libraryPath ~ "libCoreADI.so")) {
            throw new FileException(libraryPath ~ "libCoreADI.so", "Apple libraries are not installed correctly. Refer to README for instructions. ");
        }

        if (!exists(libraryPath ~ "libstoreservicescore.so")) {
            throw new FileException(libraryPath ~ "libstoreservicescore.so", "Apple libraries are not installed correctly. Refer to README for instructions. ");
        }

        this.libcoreadi = new AndroidLibrary(libraryPath ~ "libCoreADI.so");
        this.libstoreservicescore = new AndroidLibrary(libraryPath ~ "libstoreservicescore.so");

        this.pADISetProvisioningPath = cast(ADISetProvisioningPath_t) libstoreservicescore.load("nf92ngaK92");
        this.pADILoadLibraryWithPath = cast(ADILoadLibraryWithPath_t) libstoreservicescore.load("kq56gsgHG6");
        this.pADISetAndroidID = cast(ADISetAndroidID_t) libstoreservicescore.load("Sph98paBcz");
        this.pADIProvisioningStart = cast(ADIProvisioningStart_t) libstoreservicescore.load("rsegvyrt87");
        this.pADIProvisioningEnd = cast(ADIProvisioningEnd_t) libstoreservicescore.load("uv5t6nhkui");
        this.pADIOTPRequest = cast(ADIOTPRequest_t) libstoreservicescore.load("qi864985u0");
        // possibilités: ksbafgljkb, madsvsfvjk (unlikely)
        this.pADISetIDMSRouting = cast(ADISetIDMSRouting_t) libstoreservicescore.load("ksbafgljkb");
        // possibilités: cp2g1b9ro, TRKYieUV6ptjZFoDvz (unlikely)
        this.pADIGetIDMSRouting = cast(ADIGetIDMSRouting_t) libstoreservicescore.load("cp2g1b9ro");

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

    ~this() {
        import provision.androidlibrary;
        unloadHybris();
    }

    private HTTP makeHttpClient() {
        auto client = HTTP();

        client.setUserAgent("iCloud.exe (unknown version) CFNetwork/520.44.6");
        client.handle.set(CurlOption.ssl_verifypeer, 0);

        debug {
            client.handle.set(CurlOption.verbose, 1);
        }
        client.addRequestHeader("Accept", "*/*");
        client.addRequestHeader("Content-Type", "text/x-xml-plist");
        client.addRequestHeader("Accept-Language", "en");
        client.addRequestHeader("Accept-Encoding", "gzip, deflate");
        client.addRequestHeader("Connection", "keep-alive");
        client.addRequestHeader("Proxy-Connection", "keep-alive");

        return client;
    }

    private void populateUrlBag(HTTP client) {
        auto content = std.net.curl.get("https://gsa.apple.com/grandslam/GsService2/lookup", client);

        Plist plist = new Plist();
        plist.read(cast(string) content);
        auto response = (cast(PlistElementDict) (cast(PlistElementDict) (plist[0]))["urls"]);

        foreach (key; response.keys()) {
            urlBag[key] = (cast(PlistElementString) response[key]).value;
        }
    }

    private ubyte[] downloadSPIM(HTTP client) {
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

        Plist spimPlist = new Plist();
        spimPlist.read(content);
        PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (spimPlist[0]))["Response"];
        string spimStr = (cast(PlistElementString) spimResponse["spim"]).value;

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

        string content = cast(string) post(urlBag["midFinishProvisioning"],
        body_, client);

        Plist plist = new Plist();
        plist.read(content);
        PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (plist[0]))["Response"];

        struct SecondStepAnswers {
            string rinfo;
            ubyte[] tk;
            ubyte[] ptm;
        }

        SecondStepAnswers secondStepAnswers = SecondStepAnswers();
        secondStepAnswers.rinfo = (cast(PlistElementString) spimResponse["X-Apple-I-MD-RINFO"]).value;
        secondStepAnswers.tk = Base64.decode((cast(PlistElementString) spimResponse["tk"]).value);
        secondStepAnswers.ptm = Base64.decode((cast(PlistElementString) spimResponse["ptm"]).value);

        return secondStepAnswers;
    }

    public void provisionDevice(out ulong routingInformation) {
        auto client = makeHttpClient();

        client.addRequestHeader("X-Mme-Client-Info", clientInfo);
        client.addRequestHeader("X-Mme-Device-Id", deviceId);
        client.addRequestHeader("X-Apple-I-MD-LU", localUserUUID);
        client.addRequestHeader("X-Apple-I-SRL-NO", serialNo);

        populateUrlBag(client);

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
            throw new AnisetteException(ret);

        ubyte[] cpim = cpimPtr[0..l];

        auto secondStep = sendCPIM(client, cpim);
        routingInformation = to!ulong(secondStep.rinfo);

        ret = pADIProvisioningEnd(
        session,
        secondStep.ptm.ptr,
        cast(uint) secondStep.ptm.length,
        secondStep.tk.ptr,
        cast(uint) secondStep.tk.length
        );

        if (ret)
            throw new AnisetteException(ret);

        pADISetIDMSRouting(routingInformation, dsId);
    }

    void getOneTimePassword(out ubyte[] machineId, out ubyte[] oneTimePassword) {
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
            throw new AnisetteException(ret);

        machineId = midPtr[0..midLen];
        oneTimePassword = otpPtr[0..otpLen];
    }
}

public class AnisetteException: Exception {
    this(int error, string file = __FILE__, ulong line = __LINE__) {
        string msg;
        if (error == -45054) {
            msg = "ADI error: cannot create folder. ";
        } else {
            msg = format!"ADI error: %d"(error);
        }
        super(msg, file, line);
    }
}
