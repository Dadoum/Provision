import handy_httpd;
import std.algorithm.searching;
import std.array;
import std.base64;
import std.format;
import std.getopt;
import std.path;
import std.stdio;
import provision;

static ADI* adi;
static ulong rinfo;

void main(string[] args) {
    auto serverConfig = ServerConfig.defaultValues;
    serverConfig.hostname = "0.0.0.0";
    serverConfig.port = 6969;

    bool rememberMachine = false;
    string path = "~/.adi";
    auto helpInformation = getopt(
		    args,
		    "n|host", "The hostname to bind to", &serverConfig.hostname,
		    "p|port", "The port to bind to", &serverConfig.port,
		    "r|remember-machine", "Whether this machine should be remembered", &rememberMachine,
		    "a|adi-path", "Where the provisioning information should be stored on the computer", &path,
    );
    if (helpInformation.helpWanted) {
        defaultGetoptPrinter("This program allows you to host anisette through libprovision!",
	    helpInformation.options);
	return;
    }

    if (rememberMachine) {
        adi = new ADI(expandTilde(path));
    } else {
        import std.digest: toHexString;
        import std.random;
        import std.range;
        import std.uni;
        ubyte[] id = cast(ubyte[]) rndGen.take(2).array;
        adi = new ADI(expandTilde(path), cast(char[]) id.toHexString().toLower());
    }

    if (!adi.isMachineProvisioned()) {
        stderr.write("Machine requires provisioning... ");
        adi.provisionDevice(rinfo);
        stderr.writeln("done !");
    } else {
        adi.getRoutingInformation(rinfo);
    }

    auto s = new HttpServer((ref ctx) {
        auto res = ctx.response;
        if (ctx.request.url == "/version") {
            import constants;
            writeln("[<<] GET /version");
            res.writeBody(anisetteServerVersion);
            writeln("[>>] 200 OK");
            res.setStatus(200);
        } else if (ctx.request.url == "/reprovision") {
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
                res.addHeader("Content-Type", "application/json");
                res.writeBody(response.toString(JSONOptions.doNotEscapeSlashes));
            } catch(Throwable t) {
                res.setStatus(500);
                res.writeBody(t.toString());
            }
        }
    }, serverConfig);
    s.start();
}

