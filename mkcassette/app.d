module app;

import core.sys.posix.sys.time;
import std.algorithm;
import std.array;
import std.base64;
import std.datetime.stopwatch: StopWatch;
import file = std.file;
import std.format;
import std.getopt;
import std.math;
import std.mmfile;
import std.net.curl;
import std.parallelism;
import std.path;
import std.range;
import std.stdio;
import std.zip;

import provision;
import provision.symbols;

import constants;

struct AnisetteCassetteHeader {
  align(1):
    ubyte[7] magicHeader = [0x69, 'C', 'A', 'S', 'S', 'T', 'E'];
    ubyte formatVersion = 0;
    ulong baseTime;

    ubyte[64] machineId;
}

static assert(AnisetteCassetteHeader.sizeof % 16 == 0);

__gshared ulong origTime;
int main(string[] args) {
    writeln(mkcassetteBranding, " v", mkcassetteVersion);

    char[] identifier = cast(char[]) "ba10defe42ea69ff";
    string path = "~/.adi";
    string outputFile = "./otp-file.acs";
    ulong days = 90;
    bool onlyInit = false;
    bool apkDownloadAllowed = true;

    auto helpInformation = getopt(
        args,
        "i|identifier", format!"The identifier used for the cassette (default: %s)"(identifier), &identifier,
        "a|adi-path", format!"Where the provisioning information should be stored on the computer (default: %s)"(path), &path,
        "d|days", format!"Number of days in the cassette (default: %s)"(days), &days,
        "o|output", format!"Output location (default: %s)"(outputFile), &outputFile,
        "init-only", format!"Download libraries and exit (default: %s)"(onlyInit), &onlyInit,
        "can-download", format!"If turned on, may download the dependencies automatically (default: %s)"(apkDownloadAllowed), &apkDownloadAllowed,
    );

    if (helpInformation.helpWanted) {
        defaultGetoptPrinter("This program allows you to host anisette through libprovision!", helpInformation.options);
        return 0;
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

        if (!file.exists("lib/")) {
            file.mkdir("lib/");
        }
        if (!file.exists(libraryPath)) {
            file.mkdir(libraryPath);
        }
        file.write(coreADIPath, apk.expand(dir[coreADIPath]));
        file.write(SSCPath, apk.expand(dir[SSCPath]));
    }

    if (onlyInit) {
        return 0;
    }

    auto numberOfOTP = days*24*60;

    ubyte[] mid;
    ubyte[] nothing;

    __gshared timeval origTimeVal;
    gettimeofday(&origTimeVal, null);
    origTime = origTimeVal.tv_sec;
    targetTime = taskPool.workerLocalStorage(origTimeVal);
    doTimeTravel = true;

    {
        scope ADI* adi = new ADI(expandTilde(path), identifier);

        if (!adi.isMachineProvisioned()) {
            stderr.write("Machine requires provisioning... ");
            ulong rinfo;
            adi.provisionDevice(rinfo);
            stderr.writeln("done !");
        }
        adi.getOneTimePassword(mid, nothing);
    }

    auto adi = taskPool.workerLocalStorage(new ADI(expandTilde(path), identifier));

    StopWatch sw;
    writeln("Starting generation of ", numberOfOTP, " otps (", days, " days) with ", totalCPUs, " threads.");
    sw.start();


    auto anisetteCassetteHeader = AnisetteCassetteHeader();
    anisetteCassetteHeader.baseTime = origTime;
    anisetteCassetteHeader.machineId[0..mid.length] = mid;

    auto anisetteCassetteHeaderBytes = (cast(ubyte*) &anisetteCassetteHeader)[0..AnisetteCassetteHeader.sizeof];

    scope otpFile = new MmFile(outputFile, MmFile.Mode.readWriteNew, AnisetteCassetteHeader.sizeof + 16 * numberOfOTP * ubyte.sizeof, null);
    scope acs = cast(ubyte[]) otpFile[0..$];
    acs[0..AnisetteCassetteHeader.sizeof] = anisetteCassetteHeaderBytes;

    void* dontcare;

    foreach (idx, otp; parallel(std.range.chunks(cast(ubyte[]) acs[AnisetteCassetteHeader.sizeof..$], 16))) {
        scope localAdi = adi.get();
        scope time = targetTime.get();
        scope ubyte* midPtr;
        scope ubyte* otpPtr;
        time.tv_sec = origTime + idx * 30;
        targetTime.get() = time;
        auto ret = localAdi.pADIOTPRequest(
            -2,
            cast(ubyte**) &midPtr,
            cast(uint*) &dontcare,
            &otpPtr,
            cast(uint*) &dontcare
        );
        if (ret != 0) {
            throw new AnisetteException(ret);
        }
        localAdi.pADIDispose(midPtr);
        otp[] = otpPtr[8..24];
        localAdi.pADIDispose(otpPtr);

        assert(targetTime.get().tv_sec == origTime + idx * 30);
    }

    sw.stop();

    writeln("Success. File written at ", outputFile, ", duration: ", sw.peek());

    return 0;
}
