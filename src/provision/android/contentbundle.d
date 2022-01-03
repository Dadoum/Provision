module provision.android.contentbundle;

import provision.glue;
import provision.android.filepath;
import provision.android.storeerrorcondition;
import provision.androidclass;

extern(C++, class) extern(C++, mediaplatform) struct ContentBundle {
    mixin AndroidClass!ContentBundle;
    ~this();

    this(ref const(FilePath), ref const(FilePath), ref const(FilePath), ref const(string_vector));
}
