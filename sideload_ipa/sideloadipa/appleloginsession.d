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
    private static __gshared ulong rinfo;

    string get(string url) {
        return cast(string) curl.get(url, client);
    }

    this() {
        if (!rinfo /+appInstance.adi.isMachineProvisioned()+/) {
            appInstance.adi.provisionDevice(rinfo);
        }

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
        import std.stdio;
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

        import std.bigint;
        import std.digest.sha;
        import std.random;

        auto hash = new SHA256Digest();
        hash.put(cast(ubyte[]) "s2k");
        hash.put(cast(ubyte[]) ",");
        hash.put(cast(ubyte[]) "s2k_fo");

        auto N = BigInt(false, [
            0xACu, 0x6Bu, 0xDBu, 0x41u, 0x32u, 0x4Au, 0x9Au, 0x9Bu, 0xF1u, 0x66u, 0xDEu, 0x5Eu, 0x13u, 0x89u, 0x58u, 0x2Fu, 0xAFu, 0x72u,
            0xB6u, 0x65u, 0x19u, 0x87u, 0xEEu, 0x07u, 0xFCu, 0x31u, 0x92u, 0x94u, 0x3Du, 0xB5u, 0x60u, 0x50u, 0xA3u, 0x73u, 0x29u, 0xCBu,
            0xB4u, 0xA0u, 0x99u, 0xEDu, 0x81u, 0x93u, 0xE0u, 0x75u, 0x77u, 0x67u, 0xA1u, 0x3Du, 0xD5u, 0x23u, 0x12u, 0xABu, 0x4Bu, 0x03u,
            0x31u, 0x0Du, 0xCDu, 0x7Fu, 0x48u, 0xA9u, 0xDAu, 0x04u, 0xFDu, 0x50u, 0xE8u, 0x08u, 0x39u, 0x69u, 0xEDu, 0xB7u, 0x67u, 0xB0u,
            0xCFu, 0x60u, 0x95u, 0x17u, 0x9Au, 0x16u, 0x3Au, 0xB3u, 0x66u, 0x1Au, 0x05u, 0xFBu, 0xD5u, 0xFAu, 0xAAu, 0xE8u, 0x29u, 0x18u,
            0xA9u, 0x96u, 0x2Fu, 0x0Bu, 0x93u, 0xB8u, 0x55u, 0xF9u, 0x79u, 0x93u, 0xECu, 0x97u, 0x5Eu, 0xEAu, 0xA8u, 0x0Du, 0x74u, 0x0Au,
            0xDBu, 0xF4u, 0xFFu, 0x74u, 0x73u, 0x59u, 0xD0u, 0x41u, 0xD5u, 0xC3u, 0x3Eu, 0xA7u, 0x1Du, 0x28u, 0x1Eu, 0x44u, 0x6Bu, 0x14u,
            0x77u, 0x3Bu, 0xCAu, 0x97u, 0xB4u, 0x3Au, 0x23u, 0xFBu, 0x80u, 0x16u, 0x76u, 0xBDu, 0x20u, 0x7Au, 0x43u, 0x6Cu, 0x64u, 0x81u,
            0xF1u, 0xD2u, 0xB9u, 0x07u, 0x87u, 0x17u, 0x46u, 0x1Au, 0x5Bu, 0x9Du, 0x32u, 0xE6u, 0x88u, 0xF8u, 0x77u, 0x48u, 0x54u, 0x45u,
            0x23u, 0xB5u, 0x24u, 0xB0u, 0xD5u, 0x7Du, 0x5Eu, 0xA7u, 0x7Au, 0x27u, 0x75u, 0xD2u, 0xECu, 0xFAu, 0x03u, 0x2Cu, 0xFBu, 0xDBu,
            0xF5u, 0x2Fu, 0xB3u, 0x78u, 0x61u, 0x60u, 0x27u, 0x90u, 0x04u, 0xE5u, 0x7Au, 0xE6u, 0xAFu, 0x87u, 0x4Eu, 0x73u, 0x03u, 0xCEu,
            0x53u, 0x29u, 0x9Cu, 0xCCu, 0x04u, 0x1Cu, 0x7Bu, 0xC3u, 0x08u, 0xD8u, 0x2Au, 0x56u, 0x98u, 0xF3u, 0xA8u, 0xD0u, 0xC3u, 0x82u,
            0x71u, 0xAEu, 0x35u, 0xF8u, 0xE9u, 0xDBu, 0xFBu, 0xB6u, 0x94u, 0xB5u, 0xC8u, 0x03u, 0xD8u, 0x9Fu, 0x7Au, 0xE4u, 0x35u, 0xDEu,
            0x23u, 0x6Du, 0x52u, 0x5Fu, 0x54u, 0x75u, 0x9Bu, 0x65u, 0xE3u, 0x72u, 0xFCu, 0xD6u, 0x8Eu, 0xF2u, 0x0Fu, 0xA7u, 0x11u, 0x1Fu,
            0x9Eu, 0x4Au, 0xFFu, 0x73u
        ]);



        // A = G^a % N

        char* output;
        uint length;
        plist_to_xml(root, &output, &length);
        string xml = output[0..length].dup;
        plist_to_xml_free(output);

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
