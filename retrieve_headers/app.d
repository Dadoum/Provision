module app;

import std.base64;
import std.format;
import std.path;
import std.stdio;
import provision;

int main(string[] args) {
    ADI* adi = new ADI(expandTilde("~/.adi"));
    ulong rinfo;
    adi.provisionDevice(rinfo);

    ubyte[] mid;
    ubyte[] otp;
    adi.getOneTimePassword(mid, otp);

    writeln(
    format!`{
    "X-Apple-I-MD": "%s",
    "X-Apple-I-MD-M": "%s",
    "X-Apple-I-MD-RINFO": "%d",
    "X-Apple-I-MD-LU": "%s",
    "X-Apple-I-SRL-NO": "%s",
    "X-Mme-Client-Info": "%s"
    "X-Mme-Device-Id": "%s",
}`(Base64.encode(mid), Base64.encode(otp), rinfo, adi.localUserUUID, adi.serialNo, adi.clientInfo, adi.deviceId)
    );

    return 0;
}
