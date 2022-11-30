import handy_httpd;
import core.exception;
import std.algorithm.searching;
import std.array;
import std.base64;
import std.format;
import std.path;
import std.stdio;
import provision;

__gshared static ADI* adi;
__gshared static ulong rinfo;

void main(string[] args) {
    auto serverConfig = ServerConfig.defaultValues;
    serverConfig.port = 6969;

    auto hostFound = countUntil(args, "--host");
    auto portFound = countUntil(args, "--port");

    try {
        if (hostFound != -1)
	    serverConfig.hostname = args[hostFound + 1];
    } catch(ArrayIndexError e) {
	    writeln("Hostname not found!");
	    return;
    }

    try {
        if (portFound != -1) {
	    import std.conv;
	    serverConfig.port = to!ushort(args[portFound + 1]);
        }
    } catch(ArrayIndexError e) {
	    writeln("Port not found!");
	    return;
    }

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

    if (!adi.isMachineProvisioned()) {
        stderr.write("Machine requires provisioning... ");
        adi.provisionDevice(rinfo);
        stderr.writeln("done !");
    } else {
        adi.getRoutingInformation(rinfo);
    }

    auto s = new HttpServer(simpleHandler((ref req, ref res) {
        if (req.url == "/reprovision") {
            writeln("[<<] GET /reprovision");
            adi.provisionDevice(rinfo);
            writeln("[>>] 200 OK");
            res.setStatus(200);
        } else {
            try {
                import std.datetime.systime;
                import std.datetime.timezone;
                import core.time;
                auto time = Clock.currTime();

                writefln("[<<] GET /");

                ubyte[] mid;
                ubyte[] otp;
                try {
                    adi.getOneTimePassword(mid, otp);
                } catch (Throwable) {
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

                writefln!"[>>] 200 OK %s"(response);

                res.setStatus(200);
                res.writeBody(to!string(response));
            } catch(Throwable t) {
                res.setStatus(500);
                res.writeBody(t.toString());
            }
        }
    }), serverConfig);
    s.start();

    /+



    with (vib) {
        Get("/reprovision", (req, res) => "Hello World!");

        Get("", (req, res) {
        });
    }

    // listenHTTP is called automatically
    runApplication();

    scope (exit)
    vib.Stop();
    // +/
}

