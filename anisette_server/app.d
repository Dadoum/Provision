import archttp;
import std.algorithm.searching;
import std.array;
import std.base64;
import std.format;
import std.path;
import std.stdio;
import provision;

void main(string[] args) {
    auto app = new Archttp;
    ADI* adi;

    if (args.canFind("--remember-machine")) {
        adi = new ADI(expandTilde("~/.adi"));
    } else {
        import std.digest: toHexString;
        import std.random;
        import std.range;
        import std.uni;
        ubyte[] id = cast(ubyte[]) rndGen.take(2).array;
        adi = new ADI(expandTilde("~/.adi"), cast(char[]) id.toHexString().toLower());
    }

    ulong rinfo;
    if (!adi.isMachineProvisioned()) {
        stderr.write("Machine requires provisioning... ");
        adi.provisionDevice(rinfo);
        stderr.writeln("done !");
    } else {
        adi.getRoutingInformation(rinfo);
    }

    app.get("/reprovision", (req, res) {
        writefln!"[%s >>] GET /reprovision"(req.ip);
        adi.provisionDevice(rinfo);
        writefln!"[>> %s] 200 OK"(req.ip);
        res.code(HttpStatusCode.OK);
    });

    app.get("/", (req, res) {
        try {
            import std.datetime.systime;
            import std.datetime.timezone;
            import core.time;
            auto time = Clock.currTime();

            writefln!"[%s >>] GET /"(req.ip);

            ubyte[] mid;
            ubyte[] otp;
            try {
                adi.getOneTimePassword(mid, otp);
            } catch {
                writeln("Reprovision needed.");
                adi.provisionDevice(rinfo);
                adi.getOneTimePassword(mid, otp);
            }

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
                "X-Apple-I-TimeZone": time.timezone.dstName,
                "X-Apple-Locale": "en_US",
                "X-Mme-Device-Id": adi.deviceId,
            ];

            writefln!"[>> %s] 200 OK %s"(req.ip, response);

            res.code(HttpStatusCode.OK);
            res.send(response);
        } catch(Throwable t) {
            res.code(HttpStatusCode.INTERNAL_SERVER_ERROR);
            res.send(t.toString());
        }
    });

    app.listen(6969);
}

