module provision.android.filepath;

import provision.android.storeerrorcondition;
import provision.androidclass;

extern(C++, class) extern(C++, mediaplatform) struct FilePath {
    mixin AndroidClass!FilePath;
    ~this();

    this(ref const(NdkString));
}
