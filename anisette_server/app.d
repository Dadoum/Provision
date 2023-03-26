import handy_httpd;
import handy_httpd.components.request;
import std.algorithm.searching;
import std.array;
import std.base64;
import file = std.file;
import std.format;
import std.getopt;
import std.math;
import std.net.curl;
import std.path;
import std.stdio;
import std.zip;

import provision;

import constants;

static __gshared ADI* adi;
static __gshared ulong rinfo;
static __gshared bool allowRemoteProvisioning = false;

void main(string[] args) {
    auto serverConfig = ServerConfig.defaultValues;
    serverConfig.hostname = "0.0.0.0";
    serverConfig.port = 6969;

    bool rememberMachine = false;
    string path = "~/.adi";
    bool onlyInit = false;
    bool apkDownloadAllowed = true;
    auto helpInformation = getopt(
        args,
        "n|host", format!"The hostname to bind to (default: %s)"(serverConfig.hostname), &serverConfig.hostname,
        "p|port", format!"The port to bind to (default: %s)"(serverConfig.hostname), &serverConfig.port,
        "r|remember-machine", format!"Whether this machine should be remembered (default: %s)"(rememberMachine), &rememberMachine,
        "a|adi-path", format!"Where the provisioning information should be stored on the computer (default: %s)"(path), &path,
        "init-only", format!"Download libraries and exit (default: %s)"(onlyInit), &onlyInit,
        "can-download", format!"If turned on, may download the dependencies automatically (default: %s)"(apkDownloadAllowed), &apkDownloadAllowed,
        "allow-remote-reprovisioning", format!"If turned on, the server may reprovision the server on client demand (default: %s)"(allowRemoteProvisioning), &allowRemoteProvisioning,
    );

    if (helpInformation.helpWanted) {
        defaultGetoptPrinter("This program allows you to host anisette through libprovision!", helpInformation.options);
        return;
    }

    auto coreADIPath = libraryPath.buildPath("libCoreADI.so");
    auto SSCPath = libraryPath.buildPath("libstoreservicescore.so");

    if (!(file.exists(coreADIPath) && file.exists(SSCPath)) && apkDownloadAllowed) {
        auto http = HTTP();
        http.onProgress = (size_t dlTotal, size_t dlNow, size_t ulTotal, size_t ulNow) {
            write("Downloading libraries from Apple servers... ");
            if (dlTotal != 0) {
                write((dlNow * 100)/dlTotal, "%     \r");
            } else {
                // Convert dlNow (in bytes) to a human readable string
                float downloadedSize = dlNow;

                enum units = ["B", "kB", "MB", "GB", "TB"];
                int i = 0;
                while (downloadedSize > 1000 && i < units.length - 1) {
                    downloadedSize = floor(downloadedSize) / 1000;
                    ++i;
                }

                write(downloadedSize, units[i], "     \r");
            }
            return 0;
        };
        auto apkData = get!(HTTP, ubyte)(nativesUrl, http);
        writeln("Downloading libraries from Apple servers... done!     \r");
        auto apk = new ZipArchive(apkData);
        auto dir = apk.directory();

        file.mkdir("lib/");
        file.mkdir(libraryPath);
        file.write(coreADIPath, apk.expand(dir[coreADIPath]));
        file.write(SSCPath, apk.expand(dir[SSCPath]));
    }

    if (onlyInit) {
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
        write("Machine requires provisioning... ");
        adi.provisionDevice(rinfo);
        writeln("done !");
    } else {
        adi.getRoutingInformation(rinfo);
    }

    auto s = new HttpServer((ref ctx) {
        auto req = ctx.request;
        ctx.response.addHeader("Implementation-Version", anisetteServerBranding ~ " " ~ anisetteServerVersion);

        writeln("[<<] ", req.method, " ", req.url);
        if (req.method != "GET") {
            writefln("[>>] 405 Method Not Allowed");
            ctx.response.setStatus(405).setStatusText("Method Not Allowed").flushHeaders();
            return;
        }

        if (req.url == "/reprovision") {
            if (allowRemoteProvisioning) {
                adi.provisionDevice(rinfo);
                writeln("[>>] 200 OK");
                ctx.response.setStatus(200);
            } else {
                writeln("[>>] 403 Forbidden");
                ctx.response.setStatus(403).setStatusText("Forbidden").flushHeaders();
            }
            return;
        }

        if (req.url != "") {
            writeln("[>>] 404 Not Found");
            ctx.response.setStatus(404).setStatusText("Not Found").flushHeaders();
            return;
        }

        try {
            import std.datetime.systime;
            import std.datetime.timezone;
            import core.time;
            auto time = Clock.currTime();

            ubyte[] mid;
            ubyte[] otp;
            try {
                adi.getOneTimePassword(mid, otp);
            } catch (AnisetteException exception) {
                if (exception.anisetteError() != AnisetteError.notProvisioned) {
                    throw exception;
                }

                writeln("Machine wasn't provisioned??");
                adi.provisionDevice(rinfo);
                adi.getOneTimePassword(mid, otp); // if it rethrows an error, we can't do much anyway.
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
            ctx.response.addHeader("Content-Type", "application/json");
            ctx.response.writeBodyString(response.toString(JSONOptions.doNotEscapeSlashes));

            writefln!"[>>] 200 OK %s"(response);
            ctx.response.okResponse();
        } catch(Throwable t) {
            string exception = t.toString();
            writeln("Encountered an error: ", exception);
            writeln("[>>] 500 Internal Server Error");
            ctx.response.writeBodyString(exception);

            ctx.response.setStatus(500).setStatusText("Internal Server Error").flushHeaders();
        }
    }, serverConfig);

    writeln("Ready! Serving data.");
    s.start();
}
