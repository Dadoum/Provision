module app;

import std.array;
import std.base64;
import std.format;
import std.path;
import std.stdio;
import provision;

int main(string[] args) {
    ADI* adi = new ADI(expandTilde("~/.adi"));

    ulong rinfo;
    if (true) {// !adi.isMachineProvisioned()) {
        stderr.write("Machine requires provisioning... ");
        adi.provisionDevice(rinfo);
        stderr.writeln("done !");
    } else {
        adi.getRoutingInformation(rinfo);
    }

    import core.memory: GC;
    GC.disable();
    import std.datetime.stopwatch: StopWatch;
    StopWatch sw;
    sw.start();
    ubyte[] mid;
    ubyte[] otp;
    foreach (num; 0..(2*60*24*7)) {
        import provision.androidlibrary: time_shift;
        adi.getOneTimePassword(mid, otp);

        time_shift++;

        //+
        writeln(
            format!`{
    "X-Apple-I-MD": "%s",
    "X-Apple-I-MD-M": "%s",
}`(
                Base64.encode(otp),
                Base64.encode(mid),
            )
        );
        // +/
    }
    sw.stop();
    writeln("Success. Duration: ", sw.peek());
    GC.collect();

    return 0;
}
