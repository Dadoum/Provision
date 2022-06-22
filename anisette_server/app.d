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
    adi.customHeaders["X-Apple-Locale"] = "en_US";

    ulong rinfo;
    adi.provisionDevice(rinfo);

    app.get("/", (req, res) {
        try {
            ubyte[] mid;
            ubyte[] otp;
            adi.getOneTimePassword(mid, otp);

            import std.datetime.systime;
            auto time = Clock.currTime();

            res.header("Content-Type", "application/json");
            res.code(HttpStatusCode.OK);

            res.send(
                format!`{"X-Apple-I-MD":"%s","X-Apple-I-MD-M":"%s","X-Apple-I-MD-RINFO":"%d","X-Apple-I-MD-LU":"%s","X-Apple-I-SRL-NO":"%s","X-Mme-Client-Info":"%s","X-Apple-I-Client-Time":"%s","X-Apple-I-TimeZone":"%s","X-Apple-Locale":"en_US","X-Mme-Device-Id":"%s"}`(
                    Base64.encode(mid),
                    Base64.encode(otp),
                    rinfo,
                    adi.localUserUUID,
                    adi.serialNo,
                    adi.clientInfo,
                    time.toISOExtString.split('.')[0] ~ "Z",
                    time.timezone.dstName,
                    adi.deviceId
                )
            );
        } catch(Throwable t) {
            res.code(HttpStatusCode.INTERNAL_SERVER_ERROR);
            res.send(t.toString());
        }
    });

    app.listen(6969);
}

