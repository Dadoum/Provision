module app;

import std.array;
import std.base64;
import std.format;
import std.path;
import std.file;
import std.getopt;
import std.stdio;
import provision;

static shared ADI* adi;
static __gshared ulong rinfo;

int main(string[] args) {
    string adiPB = getcwd();
    bool rememberMachine = false;
    auto helpInformation = getopt(
		    args,
		    "r|remember-machine", "Whether this machine should be remembered", &rememberMachine,
            "f|file", "Which adi.pb directory to use", &adiPB
    );
    if (helpInformation.helpWanted) {
        defaultGetoptPrinter("This program allows you to generate anisette through libprovision!",
	    helpInformation.options);
	return 0;
    }
    
    adi = new shared ADI(adiPB);

    if (!rememberMachine) {// !adi.isMachineProvisioned()) {
        stderr.write("Machine requires provisioning... ");
        adi.provisionDevice(rinfo);
        stderr.writeln("done !");
    } else {
        adi.getRoutingInformation(rinfo);
    }

    ubyte[] mid;
    ubyte[] otp;
    adi.getOneTimePassword(mid, otp);

    import std.datetime.systime;
    auto time = Clock.currTime();

    writeln(
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
            Base64.encode(otp),
            Base64.encode(mid),
            rinfo,
            adi.localUserUUID,
            adi.serialNo,
            adi.clientInfo,
            time.toISOExtString.split('.')[0] ~ "Z",
            time.timezone.dstName,
            adi.deviceId
        )
    );

    return 0;
}
