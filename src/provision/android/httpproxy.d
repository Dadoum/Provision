module provision.android.httpproxy;

import provision.androidclass;


extern(C++, class) extern(C++, mediaplatform) struct HTTPProxy {
    enum Type: int {
        t0 = 0
    }

    mixin AndroidClass!HTTPProxy;
    ~this();

    this(Type, ref const(NdkString), ref const(ushort));
}
