module provision.android.id;

import std.digest: toHexString;
import File = std.file;
import std.format;
import std.random;
import std.range;
import std.stdio;
import std.uni;

char[] genAndroidId() {
    ubyte[] identifier;
    try {
        identifier = cast(ubyte[]) File.read("/etc/machine-id", 8);

        static foreach (index, appIdentifierBit; [
            0x8b, 0x06, 0x7f, 0xdd,
            0x3c, 0xbf, 0x40, 0x8c,
            0x90, 0x64, 0xc7, 0x5a,
            0x9a, 0xc4, 0xc7, 0x8b
        ]) {
            identifier[index % 8] ^= appIdentifierBit;
        }
    } catch (File.FileException) {
        stderr.writeln("WARN: Generation of unique identifier failed, using a random one instead. ");
        identifier = cast(ubyte[]) rndGen.take(2).array;
    }

    return identifier.toHexString().toLower().dup;
}
