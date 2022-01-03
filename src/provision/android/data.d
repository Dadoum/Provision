module provision.android.data;

import provision.androidclass;

extern(C++, class) extern(C++, mediaplatform) public struct Data {
    mixin AndroidClass!Data;

    this(const void*, ulong, bool);

    void* bytes() const;
    long length() const;

    extern(D) {
        static Data* fromByteArray(ubyte[] data) {
            return Data.create(data.ptr, data.length, true);
        }

        string toString() {
            if (length <= 0) {
                return null;
            }

            return cast(string) bytes[0..length];
        }
    }
}
