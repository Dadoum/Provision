module app;

import std.array;
import std.base64;
import std.conv: to;
import file = std.file;
import std.format;
import std.path;
import process = std.process;
import provision;
import slf4d;

static import std.stdio;

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

int main(string[] args) {
    import slf4d.default_provider;
    Levels logLevel;
    debug {
        logLevel = Levels.TRACE;
    } else {
        logLevel = args.length == 2 && args[1] == "debug" ? Levels.TRACE : Levels.INFO;
    }
    auto provider = new shared DefaultProvider(true, logLevel);
    configureLoggingProvider(provider);

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

    if (!file.exists(configurationPath)) {
        file.mkdirRecurse(configurationPath);
    }

    ADI adi = new ADI("lib/" ~ architectureIdentifier);
    adi.provisioningPath = configurationPath;
    Device device = new Device(configurationPath.buildPath("device.json"));

    Logger log = getLogger();

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

    adi.identifier = device.adiIdentifier;
    if (!adi.isMachineProvisioned(-2)) {
        log.info("Machine requires provisioning... ");

        ProvisioningSession provisioningSession = new ProvisioningSession(adi, device);
        provisioningSession.provision(-2);
        log.info("Provisioning done!");
    }

    auto otp = adi.requestOTP(-2);

    import std.datetime.systime;
    version (Windows) {
        import std.datetime.timezone;
        auto time = Clock.currTime(UTC());
    } else {
        auto time = Clock.currTime();
    }

    std.stdio.writeln(
        format!`{
    "X-Apple-I-MD": "%s",
    "X-Apple-I-MD-M": "%s",
    "X-Apple-I-MD-RINFO": "%d",
    "X-Apple-I-MD-LU": "%s",
    "X-Apple-I-SRL-NO": "%s",
    "X-Mme-Client-Info": "%s",
    "X-Apple-I-Client-Time": "%s",
    "X-Apple-I-TimeZone": "%s",
    "X-Apple-Locale": "en_US",
    "X-Mme-Device-Id": "%s"
}`(
            Base64.encode(otp.oneTimePassword),
            Base64.encode(otp.machineIdentifier),
            17106176,
            device.localUserUUID,
            "0",
            device.serverFriendlyDescription,
            time.toISOExtString.split('.')[0] ~ "Z",
            time.timezone.dstName,
            device.uniqueDeviceIdentifier
        )
    );

    return 0;
}
