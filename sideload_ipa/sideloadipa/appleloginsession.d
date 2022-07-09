module sideloadipa.appleloginsession;

import app;

import std.array;
import std.base64;
import std.conv;
import std.datetime.systime;
import curl = std.net.curl;
import std.string;
import std.variant;

import plist;
import plist.types;

import sideloadipa.plist;

enum AppleLoginResponse: int {
    errored = 0,
    requires2FA = 1,
    loggedIn = 2,
}

class AppleLoginSession {
    string[string] urlBag;
    Variant[string] xHeaders;
    curl.HTTP client;
    private plist_t requestTemplate;

    string get(string url) {
        return cast(string) curl.get(url, client);
    }

    this() {
        ulong rinfo;
        appInstance.adi.provisionDevice(rinfo);

        client = curl.HTTP();
        client.setUserAgent("Xcode");
        client.handle.set(curl.CurlOption.ssl_verifypeer, 0);
        client.addRequestHeader("Accept", "*/*");
        client.addRequestHeader("Content-Type", "text/x-xml-plist");
        client.addRequestHeader("Accept-Language", "en");
        client.addRequestHeader("Accept-Encoding", "gzip, deflate");
        client.addRequestHeader("Connection", "keep-alive");
        client.addRequestHeader("Proxy-Connection", "keep-alive");

        client.addRequestHeader("X-Apple-I-MD-LU", appInstance.adi.localUserUUID);
        client.addRequestHeader("X-Mme-Device-Id", appInstance.adi.deviceId);
        client.addRequestHeader("X-Mme-Client-Info", appInstance.adi.clientInfo);
        client.addRequestHeader("X-Xcode-Version", "11.2 (11B41)");
        client.addRequestHeader("X-Apple-App-Info", "com.apple.gs.xcode.auth");

        ubyte[] mid;
        ubyte[] otp;

        appInstance.adi.getOneTimePassword(mid, otp);

        xHeaders = cast(Variant[string]) [
            "X-Apple-I-Client-Time":    cast(Variant) Clock.currTime().toISOExtString().split('.')[0] ~ "Z",
            "X-Apple-I-Locale":         cast(Variant) "en",
            "X-Apple-I-SRL-NO":         cast(Variant) appInstance.adi.serialNo,
            "X-Apple-I-MD":             cast(Variant) cast(string) Base64.encode(mid),
            "X-Apple-I-MD-M":           cast(Variant) cast(string) Base64.encode(otp),
            "X-Apple-I-MD-RINFO":       cast(Variant) to!string(rinfo),
            "X-Apple-I-MD-LU":          cast(Variant) appInstance.adi.localUserUUID,
            "X-Mme-Device-Id":          cast(Variant) appInstance.adi.deviceId,
            "X-Apple-I-TimeZone":       cast(Variant) Clock.currTime().timezone().dstName,
            "X-Apple-Locale":           cast(Variant) "en",
            "bootstrap":                cast(Variant) true,
            "icscrec":                  cast(Variant) true,
            "loc":                      cast(Variant) "en",
            "pbe":                      cast(Variant) false,
            "prkgen":                   cast(Variant) true,
            "svct":                     cast(Variant) "iCloud",
        ];

        foreach (xHeader; xHeaders.byKeyValue) {
            client.addRequestHeader(xHeader.key, to!string(xHeader.value));
        }

        auto content = get("https://gsa.apple.com/grandslam/GsService2/lookup");

        Plist plist = new Plist();
        plist.read(cast(string) content);
        auto response = (cast(PlistElementDict) (cast(PlistElementDict) (plist[0]))["urls"]);

        foreach (key; response.keys()) {
            urlBag[key] = (cast(PlistElementString) response[key]).value;
        }

        requestTemplate = plist_new_dict();
        auto req_headers = plist_new_dict();
        auto header_version = plist_new_string("1.0.1");

        plist_dict_set_item(req_headers, "Version", header_version);
        plist_dict_set_item(requestTemplate, "Header", req_headers);

        auto req_request = plist_new_dict();

        auto req_cpd = plist_new_dict();

        foreach (clientProtocol; xHeaders.byKeyValue) {
            plist_t val;
            auto valType = clientProtocol.value.type;
            if (valType == typeid(string)) {
                val = plist_new_string(clientProtocol.value.coerce!string.toStringz);
            } else if (valType == typeid(bool)) {
                val = plist_new_bool(clientProtocol.value.coerce!bool);
            } else {
                continue;
            }

            // WARN: it assumes that every dict key is a direct string literral, else it could segfault since string
            // would be not \0 terminated
            plist_dict_set_item(req_cpd, clientProtocol.key.ptr, val);
        }

        plist_dict_set_item(req_request, "cpd", req_cpd);
        plist_dict_set_item(requestTemplate, "Request", req_request);
    }

    ~this() {
        plist_free(requestTemplate);
    }

    AppleLoginResponse login(string appleId, string password, out string error) {
        error = null;
        error = "Not implemented.";

        auto root = plist_copy(requestTemplate);
        scope(exit) plist_free(root);

        auto requestRoot = plist_dict_get_item(root, "Request");

        auto o = plist_new_string("init");
        plist_dict_set_item(requestRoot, "o", o);

        auto u = plist_new_string(appleId.toStringz);
        plist_dict_set_item(requestRoot, "u", u);

        auto ps = plist_new_array();
        auto s2k = plist_new_string("s2k");
        plist_array_append_item(ps, s2k);
        auto s2k_fo = plist_new_string("s2k_fo");
        plist_array_append_item(ps, s2k_fo);
        plist_dict_set_item(requestRoot, "ps", ps);

        import std.digest.sha;
        auto r2048 = [
            0xAC, 0x6B, 0xDB, 0x41, 0x32, 0x4A, 0x9A, 0x9B, 0xF1, 0x66, 0xDE, 0x5E, 0x13, 0x89, 0x58, 0x2F, 0xAF, 0x72,
            0xB6, 0x65, 0x19, 0x87, 0xEE, 0x07, 0xFC, 0x31, 0x92, 0x94, 0x3D, 0xB5, 0x60, 0x50, 0xA3, 0x73, 0x29, 0xCB,
            0xB4, 0xA0, 0x99, 0xED, 0x81, 0x93, 0xE0, 0x75, 0x77, 0x67, 0xA1, 0x3D, 0xD5, 0x23, 0x12, 0xAB, 0x4B, 0x03,
            0x31, 0x0D, 0xCD, 0x7F, 0x48, 0xA9, 0xDA, 0x04, 0xFD, 0x50, 0xE8, 0x08, 0x39, 0x69, 0xED, 0xB7, 0x67, 0xB0,
            0xCF, 0x60, 0x95, 0x17, 0x9A, 0x16, 0x3A, 0xB3, 0x66, 0x1A, 0x05, 0xFB, 0xD5, 0xFA, 0xAA, 0xE8, 0x29, 0x18,
            0xA9, 0x96, 0x2F, 0x0B, 0x93, 0xB8, 0x55, 0xF9, 0x79, 0x93, 0xEC, 0x97, 0x5E, 0xEA, 0xA8, 0x0D, 0x74, 0x0A,
            0xDB, 0xF4, 0xFF, 0x74, 0x73, 0x59, 0xD0, 0x41, 0xD5, 0xC3, 0x3E, 0xA7, 0x1D, 0x28, 0x1E, 0x44, 0x6B, 0x14,
            0x77, 0x3B, 0xCA, 0x97, 0xB4, 0x3A, 0x23, 0xFB, 0x80, 0x16, 0x76, 0xBD, 0x20, 0x7A, 0x43, 0x6C, 0x64, 0x81,
            0xF1, 0xD2, 0xB9, 0x07, 0x87, 0x17, 0x46, 0x1A, 0x5B, 0x9D, 0x32, 0xE6, 0x88, 0xF8, 0x77, 0x48, 0x54, 0x45,
            0x23, 0xB5, 0x24, 0xB0, 0xD5, 0x7D, 0x5E, 0xA7, 0x7A, 0x27, 0x75, 0xD2, 0xEC, 0xFA, 0x03, 0x2C, 0xFB, 0xDB,
            0xF5, 0x2F, 0xB3, 0x78, 0x61, 0x60, 0x27, 0x90, 0x04, 0xE5, 0x7A, 0xE6, 0xAF, 0x87, 0x4E, 0x73, 0x03, 0xCE,
            0x53, 0x29, 0x9C, 0xCC, 0x04, 0x1C, 0x7B, 0xC3, 0x08, 0xD8, 0x2A, 0x56, 0x98, 0xF3, 0xA8, 0xD0, 0xC3, 0x82,
            0x71, 0xAE, 0x35, 0xF8, 0xE9, 0xDB, 0xFB, 0xB6, 0x94, 0xB5, 0xC8, 0x03, 0xD8, 0x9F, 0x7A, 0xE4, 0x35, 0xDE,
            0x23, 0x6D, 0x52, 0x5F, 0x54, 0x75, 0x9B, 0x65, 0xE3, 0x72, 0xFC, 0xD6, 0x8E, 0xF2, 0x0F, 0xA7, 0x11, 0x1F,
            0x9E, 0x4A, 0xFF, 0x73
        ];

        char* output;
        uint length;
        plist_to_xml(root, &output, &length);
        string xml = output[0..length].dup;
        plist_to_xml_free(output);

        import std.stdio;
        writeln(xml);

        return AppleLoginResponse.errored;
    }

    bool consume2FACode(uint code) {
        return false;
    }

    string token() {
        return "";
    }
}
