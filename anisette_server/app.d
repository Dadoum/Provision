import std.array;
import std.base64;
import std.format;
import std.path;
import std.stdio;
import provision;
import serverino;

mixin ServerinoMain;

__gshared ADI* adi;
__gshared ulong rinfo;

@onServerInit ServerinoConfig initServer() {
    adi = new ADI(expandTilde("~/.adi"));

    if (!adi.isMachineProvisioned()) {
        stderr.write("Machine requires provisioning... ");
        adi.provisionDevice(rinfo);
        stderr.writeln("done !");
    } else {
        // adi.getRoutingInformation(rinfo);
        rinfo = 0;
    }

    ServerinoConfig sc = ServerinoConfig.create(); // Config with default params
    sc.addListener("127.0.0.1", 6969);

    return sc;
}

@endpoint void server(const Request req, Output output) {
    if (req.uri == "/reprovision")  {
        // writefln!"[%s >>] GET /reprovision"(req.ip);
        adi.provisionDevice(rinfo);
        // writefln!"[>> %s] 200 OK"(req.ip);
        output.status = 200;
        return;
    }
    try {
        import std.datetime.systime;
        import std.datetime.timezone;
        import core.time;
        auto time = Clock.currTime();

        writefln!"[%s >>] GET /"(req.remoteAddress);

        ubyte[] mid;
        ubyte[] otp;
        try {
            adi.getOneTimePassword(mid, otp);
        } catch (Throwable t) {
            writeln("Reprovision needed. ");
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

        writefln!"[>> %s] 200 OK %s"(req.remoteAddress, response);

        output.status = 200;
        output ~= response;
    } catch(Throwable t) {
        output.status = 500;
        output ~= t.toString();
    }
}
