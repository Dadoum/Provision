module app;

import android.id;
import provision.androidlibrary;
import std.base64;
import std.digest.sha;
import std.file;
import std.net.curl;
import std.path;
import std.stdio;
import std.string;

ubyte[] generateSPIM(HTTP client) {
    string content = cast(string) post("https://gsa.apple.com/grandslam/MidService/startMachineProvisioning",
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

    import plist;
    import plist.types;
    Plist spimPlist = new Plist();
    spimPlist.read(content);
    PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (spimPlist[0]))["Response"];
    string spimStr = (cast(PlistElementString) spimResponse["spim"]).value;

    return Base64.decode(spimStr);
}

struct SecondStepAnswers {
    string rinfo;
    ubyte[] tk;
    ubyte[] ptm;
}

SecondStepAnswers sendCPIM(HTTP client, ubyte[] cpim) {
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

    string content = cast(string) post("https://gsa.apple.com/grandslam/MidService/finishMachineProvisioning",
        body_, client);

    import plist;
    import plist.types;
    Plist spimPlist = new Plist();
    spimPlist.read(content);
    PlistElementDict spimResponse = cast(PlistElementDict) (cast(PlistElementDict) (spimPlist[0]))["Response"];

    SecondStepAnswers secondStepAnswers = SecondStepAnswers();
    secondStepAnswers.rinfo = (cast(PlistElementString) spimResponse["X-Apple-I-MD-RINFO"]).value;
    secondStepAnswers.tk = Base64.decode((cast(PlistElementString) spimResponse["tk"]).value);
    secondStepAnswers.ptm = Base64.decode((cast(PlistElementString) spimResponse["ptm"]).value);

    return secondStepAnswers;
}

version (X86_64) {
    enum string architectureIdentifier = "x86_64";
} else version (X86) {
    enum string architectureIdentifier = "x86";
} else version (AArch64) {
    enum string architectureIdentifier = "arm64-v8a";
} else version (ARM) {
    enum string architectureIdentifier = "armeabi-v7a";
} else {
    static assert(false, "Votre architecture n'est pas supportée ^^'.");
}

private string defaultLibPrefix = "ndk/" ~ architectureIdentifier ~ "/";
enum string applePrefix = "lib/" ~ architectureIdentifier ~ "/";

int main(string[] args) {
    initHybris();
    auto libdl = AndroidLibrary(defaultLibPrefix ~ "libdl.so");
    auto libc = AndroidLibrary(defaultLibPrefix ~ "libc.so");
    auto libm = AndroidLibrary(defaultLibPrefix ~ "libm.so");
    auto libz = AndroidLibrary(defaultLibPrefix ~ "libz.so");
    auto liblog = AndroidLibrary(defaultLibPrefix ~ "liblog.so");
    auto libstdcpp = AndroidLibrary(defaultLibPrefix ~ "libstdc++.so");
    auto libopensles = AndroidLibrary(defaultLibPrefix ~ "libOpenSLES.so");
    auto libandroid = AndroidLibrary(defaultLibPrefix ~ "libandroid.so");
    auto libcoreadi = AndroidLibrary(applePrefix ~ "libCoreADI.so");
    auto libcorelskd = AndroidLibrary(applePrefix ~ "libCoreLSKD.so");
    auto libcorefp = AndroidLibrary(applePrefix ~ "libCoreFP.so");
    auto libcpp_shared = AndroidLibrary(applePrefix ~ "libc++_shared.so");
    auto libxml2 = AndroidLibrary(applePrefix ~ "libxml2.so");
    auto libcurl = AndroidLibrary(applePrefix ~ "libcurl.so");
    auto libicudata_sv_apple = AndroidLibrary(applePrefix ~ "libicudata_sv_apple.so");
    auto libicuuc_sv_apple = AndroidLibrary(applePrefix ~ "libicuuc_sv_apple.so");
    auto libicui18n_sv_apple = AndroidLibrary(applePrefix ~ "libicui18n_sv_apple.so");
    auto libblocksruntime = AndroidLibrary(applePrefix ~ "libBlocksRuntime.so");
    auto libdispatch = AndroidLibrary(applePrefix ~ "libdispatch.so");
    auto libcorefoundation = AndroidLibrary(applePrefix ~ "libCoreFoundation.so");
    auto libmediaplatform = AndroidLibrary(applePrefix ~ "libmediaplatform.so");
    auto libstoreservicescore = AndroidLibrary(applePrefix ~ "libstoreservicescore.so");

    alias ADISetProvisioningPath_t = extern(C) void function(immutable char*);
    auto pADISetProvisioningPath = cast(ADISetProvisioningPath_t) libstoreservicescore.load("nf92ngaK92");

    alias ADILoadLibraryWithPath_t = extern(C) void function(immutable char*);
    auto pADILoadLibraryWithPath = cast(ADILoadLibraryWithPath_t) libstoreservicescore.load("kq56gsgHG6");

    alias ADISetAndroidID_t = extern(C) void function(immutable char*, uint);
    auto pADISetAndroidID = cast(ADISetAndroidID_t) libstoreservicescore.load("Sph98paBcz");

    alias ADIProvisioningStart_t = extern(C) void function(ulong, ubyte*, uint, ubyte**, uint*, uint*);
    auto pADIProvisioningStart = cast(ADIProvisioningStart_t) libstoreservicescore.load("rsegvyrt87");

    alias ADIProvisioningEnd_t = extern(C) void function(uint, ubyte*, uint, ubyte*, uint);
    auto pADIProvisioningEnd = cast(ADIProvisioningEnd_t) libstoreservicescore.load("uv5t6nhkui");

    alias ADIOTPRequest_t = extern(C) void function(ulong, ubyte**, uint*, ubyte**, uint*);
    auto pADIOTPRequest = cast(ADIOTPRequest_t) libstoreservicescore.load("qi864985u0");

    string androidId = genAndroidId;

    auto adiPath = expandTilde("~/.adi");
    if (!adiPath.exists()) {
        adiPath.mkdir();
    }

    auto provisionPath = buildPath(adiPath, "provision");
    if (!provisionPath.exists()) {
        provisionPath.mkdir();
    }

    pADISetProvisioningPath(/+path+/ provisionPath.toStringz);
    pADILoadLibraryWithPath(/+path+/ applePrefix.toStringz);
    pADISetAndroidID(/+identifierStr+/ androidId.toStringz, /+length+/ cast(uint) androidId.length);

    auto client = HTTP();

    client.setUserAgent("iCloud.exe (unknown version) CFNetwork/520.44.6");
    client.handle.set(CurlOption.ssl_verifypeer, 0);

    debug {
        client.handle.set(CurlOption.verbose, 1);
    }
    client.addRequestHeader("Accept", "*/*");
    client.addRequestHeader("Content-Type", "text/x-xml-plist");
    client.addRequestHeader("X-Mme-Client-Info", format!"<%s> <%s;%s;%s> <com.apple.AuthKitWin/1.0 (com.apple.iCloud/7.13)>"("PC", "Windows", "6.2(0,0)", "9200")); // device model, device operating system, os version, os build

    auto deviceId = sha1Of(androidId).toHexString().toUpper();
    client.addRequestHeader("X-Mme-Device-Id", deviceId);
    auto localUserUUID = sha256Of(androidId).toHexString().toUpper();
    client.addRequestHeader("X-Apple-I-MD-LU", localUserUUID);

    client.addRequestHeader("Accept-Language", "en");
    client.addRequestHeader("X-Mme-Country", "US");
    client.addRequestHeader("Accept-Encoding", "gzip, deflate");
    client.addRequestHeader("Connection", "keep-alive");
    client.addRequestHeader("Proxy-Connection", "keep-alive");

    ubyte[] spim = generateSPIM(client);

    ubyte* cpimPtr;
    uint l;
    ulong dsid = -2;

    uint session;

    pADIProvisioningStart(
    /+dsId+/ dsid,
    /+spim ptr+/ spim.ptr,
    /+spim length+/ cast(uint) spim.length,
    /+(out) cpim ptr+/ &cpimPtr,
    /+(out) cpim length+/ &l,
    /+(out) session+/ &session
    );

    ubyte[] cpim = cpimPtr[0..l];

    auto secondStep = sendCPIM(client, cpim);

    pADIProvisioningEnd(
        session,
        secondStep.ptm.ptr,
        cast(uint) secondStep.ptm.length,
        secondStep.tk.ptr,
        cast(uint) secondStep.tk.length
    );

    ubyte* midPtr;
    uint midLen;
    ubyte* otpPtr;
    uint otpLen;

    pADIOTPRequest(
    /+accountID+/ cast(ulong) -2,
    /+(out) machineID+/ &midPtr, // X-Apple-I-MD-M
    /+(out) machineID length+/ &midLen,
    /+(out) oneTimePW+/ &otpPtr, // X-Apple-I-MD
    /+(out) oneTimePW length+/ &otpLen,
    );

    ubyte[] mid = midPtr[0..midLen];
    ubyte[] otp = otpPtr[0..otpLen];
    string rinfo = secondStep.rinfo;

    writeln(
format!`{
    "X-Apple-I-MD-M":"%s",
    "X-Apple-I-MD":"%s",
    "X-Apple-I-MD-RINFO":"%s",
    "X-Apple-I-MD-LU":"%s",
    "X-Mme-Device-Id":"%s",
}`(Base64.encode(mid), Base64.encode(otp), rinfo, localUserUUID, deviceId)
    );

    unloadHybris();
    return 0;
}
