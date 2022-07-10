import archttp;
import std.array;
import std.base64;
import std.format;
import std.path;
import std.stdio;
import provision;

void main(string[] args) {
    auto app = new Archttp;
    ADI* adi = new ADI(expandTilde("~/.adi"));
    adi.serialNo = "DNPX89219";
    adi.customHeaders["X-Apple-Locale"] = "en_US";

    ulong rinfo;
    adi.provisionDevice(rinfo);

    app.get("/", (req, res) {
        try {
            import std.datetime.systime;
            import std.datetime.timezone;
            import core.time;
            auto time = Clock.currTime(cast(TimeZone) new SimpleTimeZone(dur!"msecs"(0), "GMT+0"));

            writeln("Received request !");

            ubyte[] mid;
            ubyte[] otp;
            adi.getOneTimePassword(mid, otp);

            import std.conv;
            import std.json;

            JSONValue response = [
                "X-Apple-I-Client-Time": time.toISOExtString.split('.')[0] ~ "Z",
                "X-Apple-I-MD":  Base64.encode(otp),
                "X-Apple-I-MD-M": Base64.encode(mid),
                "X-Apple-I-MD-RINFO": to!string(rinfo),
                "X-Apple-I-MD-LU": adi.localUserUUID,
                "X-Apple-I-SRL-NO": adi.serialNo,
                "X-MMe-Client-Info": adi.clientInfo,
                "X-Apple-I-TimeZone": "GMT+0",
                "X-Apple-Locale": "en_US",
                "X-Mme-Device-Id": adi.deviceId,
            ];

            res.code(HttpStatusCode.OK);
            res.send(response);
        } catch(Throwable t) {
            res.code(HttpStatusCode.INTERNAL_SERVER_ERROR);
            res.send(t.toString());
        }
    });

    app.listen(6969);
}

