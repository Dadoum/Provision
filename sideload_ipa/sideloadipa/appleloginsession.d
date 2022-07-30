module sideloadipa.appleloginsession;

import app;

import gmp.z;

import std.array;
import std.base64;
import std.conv;
import std.datetime.systime;
import curl = std.net.curl;
import std.variant;

import provision.plist;

import glib.CharacterSet;

enum AppleLoginResponse: int {
    errored = 0,
    requires2FA = 1,
    loggedIn = 2,
}

shared class AppleLoginSession {
    __gshared string[string] urlBag;
    __gshared Variant[string] xHeaders;
    __gshared curl.HTTP client;
    private __gshared PlistDict requestTemplate;
    private static __gshared ulong rinfo;

    string get(string url) {
        return cast(string) curl.get(url, client);
    }

    string post(string url, string data) {
        return cast(string) curl.post(url, data, client);
    }

    this() {
        if (!(rinfo && appInstance.adi.isMachineProvisioned())) {
            appInstance.adi.provisionDevice(rinfo);
        }

        client = curl.HTTP();
        client.setUserAgent("Xcode");
        client.handle.set(curl.CurlOption.ssl_verifypeer, 0);
        client.addRequestHeader("Accept", "*/*");
        client.addRequestHeader("Content-Type", "text/x-xml-plist; charset=utf-8");
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

        import std.algorithm.searching;
        auto locale = CharacterSet.getLanguageNamesWithCategory("LC_MESSAGES")[0];
        if (locale == "C")
            locale = "en";
        else if (locale.canFind('.'))
            locale = locale.split('.')[0];

        xHeaders = cast(Variant[string]) [
        "X-Apple-I-Client-Time":    cast(Variant) Clock.currTime().toISOExtString().split('.')[0] ~ "Z",
        "X-Apple-I-Locale":         cast(Variant) locale,
        "X-Apple-I-SRL-NO":         cast(Variant) appInstance.adi.serialNo,
        "X-Apple-I-MD":             cast(Variant) cast(string) Base64.encode(otp),
        "X-Apple-I-MD-M":           cast(Variant) cast(string) Base64.encode(mid),
        "X-Apple-I-MD-RINFO":       cast(Variant) to!string(rinfo),
        "X-Apple-I-MD-LU":          cast(Variant) appInstance.adi.localUserUUID,
        "X-Mme-Device-Id":          cast(Variant) appInstance.adi.deviceId,
        "X-Apple-I-TimeZone":       cast(Variant) Clock.currTime().timezone().dstName,
        "X-Apple-Locale":           cast(Variant) locale,
        "bootstrap":                cast(Variant) true,
        "icscrec":                  cast(Variant) true,
        "loc":                      cast(Variant) locale,
        "pbe":                      cast(Variant) false,
        "prkgen":                   cast(Variant) true,
        "svct":                     cast(Variant) "iCloud",
        ];

        foreach (xHeader; xHeaders.byKeyValue) {
            client.addRequestHeader(xHeader.key, to!string(xHeader.value));
        }

        auto content = get("https://gsa.apple.com/grandslam/GsService2/lookup");

        PlistDict plist = cast(PlistDict) Plist.fromXml(content);
        auto response = cast(PlistDict) plist["urls"];
        auto responseIter = response.iter();

        Plist val;
        string key;

        while (responseIter.next(val, key)) {
            urlBag[key] = cast(string) cast(PlistString) val;
        }

        requestTemplate = new PlistDict();
        auto req_headers = new PlistDict();
        req_headers["Version"] = new PlistString("1.0.1");
        requestTemplate["Header"] = req_headers;

        auto req_request = new PlistDict();

        auto req_cpd = new PlistDict();

        foreach (clientProtocol; xHeaders.byKeyValue) {
            auto valType = clientProtocol.value.type;
            if (valType == typeid(string)) {
                req_cpd[clientProtocol.key] = new PlistString(clientProtocol.value.coerce!string);
            } else if (valType == typeid(bool)) {
                req_cpd[clientProtocol.key] = new PlistBoolean(clientProtocol.value.coerce!bool);
            } else {
                continue;
            }
        }
        req_request["cpd"] = req_cpd;
        requestTemplate["Request"] = req_request;
    }

    AppleLoginResponse login(string appleId, string password, out string error) {
        import std.digest.sha;
        import std.stdio;

        error = null;
        SHA256Digest exchange;

        auto root = requestTemplate.copy();

        MpZ N;
        MpZ a;
        MpZ A;
        MpZ g;

        ubyte[] Ab;

        {
            auto requestRoot = cast(PlistDict) root["Request"];

            requestRoot["o"] = new PlistString("init");
            requestRoot["u"] = new PlistString(appleId);

            auto ps = new PlistArray();
            ps ~= new PlistString("s2k");
            ps ~= new PlistString("s2k_fo");
            requestRoot["ps"] = ps;

            exchange = new SHA256Digest();
            exchange.put(cast(ubyte[]) "s2k");
            exchange.put(cast(ubyte[]) ",");
            exchange.put(cast(ubyte[]) "s2k_fo");
            exchange.put(cast(ubyte[]) "|");

            import std.algorithm.mutation;

            N = MpZ.fromHexString(
            "AC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC319294" ~
            "3DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310D" ~
            "CD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FB" ~
            "D5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF74" ~
            "7359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A" ~
            "436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D" ~
            "5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E73" ~
            "03CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB6" ~
            "94B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F" ~
            "9E4AFF73",
            ); // +/
            g = MpZ.fromHexString("2");

            ubyte[] buffer = new ubyte[](32);
            File urandom = File("/dev/urandom", "rb");
            urandom.setvbuf(null, _IONBF);
            scope(exit) urandom.close();

            buffer = urandom.rawRead(buffer);

            a = buffer.toMpZ;
            A = powm(g, a, N);

            Ab = A.toByteArray();

            requestRoot["A2k"] = new PlistData(Ab);
        }

        ubyte[] expectedM2;
        ubyte[] K;

        {
            auto res = cast(PlistDict) Plist.fromXml(post(urlBag["gsService"], root.toXml()));
            PlistDict responseDict = cast(PlistDict) res["Response"];
            error = checkStatus(cast(PlistDict) responseDict["Status"]);
            if (error) {
                return AppleLoginResponse.errored;
            }

            uint i = cast(uint) cast(PlistUint) responseDict["i"];
            ubyte[] s = cast(ubyte[]) cast(PlistData) responseDict["s"];
            string sp = cast(string) cast(PlistString) responseDict["sp"];
            string c = cast(string) cast(PlistString) responseDict["c"];
            ubyte[] B = cast(ubyte[]) cast(PlistData) responseDict["B"];

            root = requestTemplate.copy();

            auto requestRoot = cast(PlistDict) root["Request"];

            requestRoot.append([
                "u": new PlistString(appleId),
                "c": new PlistString(c),
                "o": new PlistString("complete")
            ]);

            exchange.put(cast(ubyte[]) "|");
            exchange.put(cast(ubyte[]) sp);

            ubyte[] passwordHash = sha256Of(password).dup;
            if (sp == "s2k_fo") {
                passwordHash = cast(ubyte[]) passwordHash.toHexString();
            }

            import kdf.pbkdf2;
            auto pw = pbkdf2!SHA256(passwordHash, s, i, 32);

            auto pwSum = new SHA256Digest();
            pwSum.put(cast(ubyte[]) ":");
            pwSum.put(pw);
            auto xSum = new SHA256Digest();
            xSum.put(s);
            xSum.put(pwSum.finish());

            auto X = xSum.finish().toMpZ();

            auto Bnum = B.toMpZ();

            auto N_bytes = N.toByteArray();
            auto N_length = N_bytes.length;
            auto A_length = Ab.length;

            ubyte[] U_intermediate = new ubyte[](2*N_length);
            U_intermediate[] = 0;
            U_intermediate[(N_length - A_length)..N_length] = Ab;
            U_intermediate[($ - B.length)..$] = B;

            ubyte[] U_bytes = sha256Of(U_intermediate).dup;
            MpZ U = U_bytes.toMpZ();

            auto g_bytes = g.toByteArray();
            auto g_length = g_bytes.length;

            ubyte[] k_intermediate = new ubyte[](2*N_length);
            k_intermediate[] = 0;
            k_intermediate[0..N_length] = N_bytes;
            k_intermediate[($ - g_length)..$] = g_bytes;

            ubyte[] k_bytes = sha256Of(k_intermediate).dup;
            MpZ k = k_bytes.toMpZ();

            auto S = powm((Bnum - ((k * powm(g, X, N)) % N)) % N, (U * X + a), N);
            auto S_bytes = S.toByteArray();

            K = sha256Of(S_bytes).dup;

            auto H_N = sha256Of(N_bytes).dup;
            auto H_g_intermediate = new ubyte[](N_length);
            H_g_intermediate[] = 0;
            H_g_intermediate[$-g_length..$] = g_bytes;
            auto H_g = sha256Of(H_g_intermediate);

            ubyte[] xor_i = new ubyte[](H_N.length);
            foreach (index, ref b; xor_i) {
                b = H_g[index] ^ H_N[index];
            }

            auto M1Hash = new SHA256Digest();
            M1Hash.put(xor_i);
            M1Hash.put(sha256Of(appleId));
            M1Hash.put(s);
            M1Hash.put(Ab);
            M1Hash.put(B);
            M1Hash.put(K);

            ubyte[] M1 = M1Hash.finish();

            requestRoot["M1"] = new PlistData(M1);

            auto expectedM2Hash = new SHA256Digest();
            expectedM2Hash.put(Ab);
            expectedM2Hash.put(M1);
            expectedM2Hash.put(K);
            expectedM2 = expectedM2Hash.finish();
        }

        {
            auto responsePlist = cast(PlistDict) Plist.fromXml(post(urlBag["gsService"], root.toXml));
            auto responseDict = cast(PlistDict) responsePlist["Response"];
            auto statusDict = cast(PlistDict) responseDict["Status"];
            error = checkStatus(statusDict);
            if (error) {
                return AppleLoginResponse.errored;
            }

            ubyte[] M2 = cast(ubyte[]) cast(PlistData) responseDict["M2"];

            if (M2 != expectedM2) {
                error = "Session verification failed!";
                return AppleLoginResponse.errored;
            }

            exchange.put(cast(ubyte[]) "|");

            PlistData spd = cast(PlistData) responseDict["spd"];
            if (spd) {
                exchange.put(cast(ubyte[]) spd);
            }

            exchange.put(cast(ubyte[]) "|");

            PlistData sc = cast(PlistData) responseDict["sc"];
            if (sc) {
                exchange.put(cast(ubyte[]) sc);
            }

            exchange.put(cast(ubyte[]) "|");

            ubyte[] np = cast(ubyte[]) cast(PlistData) responseDict["np"];
            exchange.put(np);

            if (exchange.length() != np.length) {
                error = "np too short";
                return AppleLoginResponse.errored;
            }

            import std.digest.hmac;
            auto digest = exchange.finish();

            auto extraDataKeyHmac = HMAC!SHA256(K);
            extraDataKeyHmac.put(cast(ubyte[]) "extra data key:");
            auto extraDataKey = extraDataKeyHmac.finish();

            auto extraDataIvHmac = HMAC!SHA256(K);
            extraDataIvHmac.put(cast(ubyte[]) "extra data iv:");
            auto extraDataIv = extraDataIvHmac.finish().dup[0..16];

            import crypto.aes;
            import crypto.padding;
            auto extraData = cast(PlistDict) Plist.fromXml(cast(string) AESUtils.decrypt!AES256(
                cast(ubyte[]) spd,
                cast(char[]) extraDataKey,
                extraDataIv,
                PaddingMode.PKCS7
            ));

            string adsid = cast(string) cast(PlistString) extraData["adsid"];
            string idmsToken = cast(string) cast(PlistString) extraData["GsIdmsToken"];

            string au = cast(string) cast(PlistString) statusDict["au"];
            if (au == "trustedDeviceSecondaryAuth") {
                return AppleLoginResponse.requires2FA;
            } else {
                ubyte[] sk = cast(ubyte[]) cast(PlistData) extraData["sk"];
                ubyte[] c = cast(ubyte[]) cast(PlistData) extraData["c"];

                enum appId = "com.apple.gs.xcode.auth";

                auto apps = new PlistArray();
                apps ~= new PlistString(appId);

                auto appTokensHmac = HMAC!SHA256(sk);
                appTokensHmac.put(cast(ubyte[]) "apptokens");
                appTokensHmac.put(cast(ubyte[]) adsid);
                appTokensHmac.put(cast(ubyte[]) appId);
                auto checksum = appTokensHmac.finish();

                root = requestTemplate.copy();

                auto requestRoot = cast(PlistDict) root["Request"];

                requestRoot.append([
                    "u": new PlistString(adsid),
                    "app": apps,
                    "c": new PlistData(c),
                    "t": new PlistString(idmsToken),
                    "checksum": new PlistData(checksum),
                    "o": new PlistString("apptokens")
                ]);
                writeln(root.toXml());

                responsePlist = cast(PlistDict) Plist.fromXml(post(urlBag["gsService"], root.toXml()));
                writeln(responsePlist.toXml());
                responseDict = cast(PlistDict) responsePlist["Response"];
                statusDict = cast(PlistDict) responseDict["Status"];
                error = checkStatus(statusDict);
                if (error) {
                    return AppleLoginResponse.errored;
                }
            }
        }

        error = "Not implemented.";
        return AppleLoginResponse.errored;
    }

    private static string checkStatus(PlistDict status) {
        int ec = cast(int) cast(uint) cast(PlistUint) status["ec"];
        if (ec != 0) {
            import std.format;
            import UTF = std.utf;

            return format!"%s (%d)"(cast(dstring) cast(PlistString) status["em"], ec);
        }
        return null;
    }

    bool consume2FACode(uint code) {
        return false;
    }

    string token() {
        return "";
    }
}

// helpers

static MpZ toMpZ(ubyte[] self) {
    return MpZ(self, WordOrder.mostSignificantWordFirst, 1, WordEndianess.bigEndian, 0);
}

static ubyte[] toByteArray(ref MpZ self) {
    return self.serialize!ubyte(WordOrder.mostSignificantWordFirst, WordEndianess.bigEndian, 0);
}

static uint byteLength(ref MpZ self) {
    auto numb = 8 * ubyte.sizeof;
    return cast(uint) (self.sizeInBase(2) + numb-1) / numb;
}
