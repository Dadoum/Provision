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
import std.parallelism;
import process = std.process;
import std.path;
import std.zip;

import slf4d;
import slf4d.default_provider;

import provision;

import constants;

version (X86_64) {
    enum string architectureIdentifier = "x86_64";
} else version (X86) {
    enum string architectureIdentifier = "x86";
} else version (AArch64) {
    enum string architectureIdentifier = "arm64-v8a";
} else version (ARM) {
    enum string architectureIdentifier = "armeabi-v7a";
} else {
    static assert(false, "Architecture not supported :(");
}

__gshared bool allowRemoteProvisioning = false;
__gshared ADI adi;
__gshared Device device;

void main(string[] args) {
    debug {
        configureLoggingProvider(new shared DefaultProvider(true, Levels.DEBUG));
    } else {
        configureLoggingProvider(new shared DefaultProvider(true, Levels.INFO));
    }

    Logger log = getLogger();
    log.infoF!"%s v%s"(anisetteServerBranding, provisionVersion);
    auto serverConfig = ServerConfig.defaultValues;
    serverConfig.hostname = "0.0.0.0";
    serverConfig.port = 6969;

    bool rememberMachine = true;
    bool onlyInit = false;
    bool apkDownloadAllowed = true;
    version (Windows) {
        string configurationPath = process.environment["LocalAppData"].buildPath("Provision");
    } else {
        string configurationPath;
        string xdgConfigPath = process.environment.get("XDG_CONFIG_HOME");
        if (xdgConfigPath) {
            configurationPath = xdgConfigPath.buildPath("Provision");
        } else {
            configurationPath = expandTilde("~/.config/Provision/");
        }
    }

    auto helpInformation = getopt(
        args,
        "n|host", format!"The hostname to bind to (default: %s)"(serverConfig.hostname), &serverConfig.hostname,
        "p|port", format!"The port to bind to (default: %s)"(serverConfig.hostname), &serverConfig.port,
        "r|remember-machine", format!"Whether this machine should be remembered (default: %s)"(rememberMachine), &rememberMachine,
        "a|adi-path", format!"Where the provisioning information should be stored on the computer (default: %s)"(configurationPath), &configurationPath,
        "init-only", format!"Download libraries and exit (default: %s)"(onlyInit), &onlyInit,
        "can-download", format!"If turned on, may download the dependencies automatically (default: %s)"(apkDownloadAllowed), &apkDownloadAllowed,
        "allow-remote-reprovisioning", format!"If turned on, the server may reprovision the server on client demand (default: %s)"(allowRemoteProvisioning), &allowRemoteProvisioning,
    );

    if (helpInformation.helpWanted) {
        defaultGetoptPrinter("This program allows you to host anisette through libprovision!", helpInformation.options);
        return;
    }

    if (!file.exists(configurationPath)) {
        file.mkdirRecurse(configurationPath);
    }

    string libraryPath = configurationPath.buildPath("lib/").buildPath(architectureIdentifier ~ "/");

    auto coreADIPath = libraryPath.buildPath("libCoreADI.so");
    auto SSCPath = libraryPath.buildPath("libstoreservicescore.so");

    if (!(file.exists(coreADIPath) && file.exists(SSCPath)) && apkDownloadAllowed) {
        auto http = HTTP();
        log.info("Downloading libraries from Apple servers...");
        auto apkData = get!(HTTP, ubyte)(nativesUrl, http);
        log.info("Done !");
        auto apk = new ZipArchive(apkData);
        auto dir = apk.directory();

        if (!file.exists(libraryPath)) {
            file.mkdirRecurse(libraryPath);
        }
        file.write(coreADIPath, apk.expand(dir["lib/" ~ architectureIdentifier ~ "/libCoreADI.so"]));
        file.write(SSCPath, apk.expand(dir["lib/" ~ architectureIdentifier ~ "/libstoreservicescore.so"]));
    }

    if (onlyInit) {
        return;
    }

    // Initializing ADI and machine if it has not already been made.
    device = new Device(rememberMachine ? configurationPath.buildPath("device.json") : "/dev/null");
    adi = new ADI(libraryPath);
    adi.provisioningPath = configurationPath;

    if (!device.initialized) {
        log.info("Creating machine... ");

        import std.digest;
        import std.random;
        import std.range;
        import std.uni;
        import std.uuid;
        device.serverFriendlyDescription = "<MacBookPro13,2> <macOS;13.1;22C65> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>";
        device.uniqueDeviceIdentifier = randomUUID().toString().toUpper();
        device.adiIdentifier = (cast(ubyte[]) rndGen.take(2).array()).toHexString().toLower();
        device.localUserUUID = (cast(ubyte[]) rndGen.take(8).array()).toHexString().toUpper();

        log.info("Machine creation done!");
    }

    enum dsId = -2;

    adi.identifier = device.adiIdentifier;
    if (!adi.isMachineProvisioned(dsId)) {
        log.info("Machine requires provisioning... ");

        ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
        provisioningSession.provision(dsId);
        log.info("Provisioning done!");
    }

    auto s = new HttpServer((ref ctx) {
        Logger log = getLogger();

        auto req = ctx.request;
        ctx.response.addHeader("Implementation-Version", anisetteServerBranding ~ " " ~ provisionVersion);

        log.infoF!"[<<] %s %s"(req.method, req.url);
        if (req.method != "GET") {
            log.info("[>>] 405 Method Not Allowed");
            ctx.response.setStatus(405).setStatusText("Method Not Allowed");
            return;
        }

        if (req.url == "/reprovision") {
            if (allowRemoteProvisioning) {
                ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
                provisioningSession.provision(dsId);
                log.info("[>>] 200 OK");
                ctx.response.setStatus(200);
            } else {
                log.info("[>>] 403 Forbidden");
                ctx.response.setStatus(403).setStatusText("Forbidden");
            }
            return;
        }

        if (req.url != "") {
            log.info("[>>] 404 Not Found");
            ctx.response.setStatus(404).setStatusText("Not Found");
            return;
        }

        try {
            import std.datetime.systime;
            import std.datetime.timezone;
            import core.time;
            version (Windows) {
                import std.datetime.timezone;
                auto time = Clock.currTime(UTC());
            } else {
                auto time = Clock.currTime();
            }

            auto otp = adi.requestOTP(dsId);

            import std.conv;
            import std.json;

            JSONValue response = [
                "X-Apple-I-Client-Time": time.toISOExtString.split('.')[0] ~ "Z",
                "X-Apple-I-MD":  Base64.encode(otp.oneTimePassword),
                "X-Apple-I-MD-M": Base64.encode(otp.machineIdentifier),
                "X-Apple-I-MD-RINFO": to!string(17106176),
                "X-Apple-I-MD-LU": device.localUserUUID,
                "X-Apple-I-SRL-NO": "0",
                "X-MMe-Client-Info": device.serverFriendlyDescription,
                "X-Apple-I-TimeZone": time.timezone.dstName,
                "X-Apple-Locale": "en_US",
                "X-Mme-Device-Id": device.uniqueDeviceIdentifier,
            ];
            ctx.response.writeBodyString(response.toString(JSONOptions.doNotEscapeSlashes), "application/json");
            log.infoF!"[>>] 200 OK %s"(response);
        } catch(Throwable t) {
            string exception = t.toString();
            log.errorF!"Encountered an error: %s"(exception);
            log.info("[>>] 500 Internal Server Error");
            ctx.response.writeBodyString(exception);
            ctx.response.setStatus(500).setStatusText("Internal Server Error");
        }
    }, serverConfig);

    log.info("Ready! Serving data.");
    s.start();
}
