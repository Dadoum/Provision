module sideloadipa.utils;

import std.traits;

template toDFunc(alias func) {
    alias Params = Parameters!func;

    static assert(isFunctionPointer!(Params[0]) && is(Parameters!(Params[0])[$-1] == void*) && is(Params[1] == void*));

    alias CDelType = extern(C) Params[0];
    alias CParams = Parameters!(Params[0]);
    alias DParams = CParams[0..$-1];
    alias DRetType = ReturnType!CDelType;
    alias DDelType = DRetType delegate(DParams);

    struct DelegateWrapperStruct {
        DDelType del;
    }

    ReturnType!func toDFunc(DDelType type) {
        CDelType fPtr = (CParams params) {
            auto del = cast(DelegateWrapperStruct*) params[$-1];
            static if (is(DRetType == void)) {
                del.del(params[0..$-1]);
            } else {
                return del.del(params[0..$-1]);
            }
        };
        return func(fPtr, cast(void*) new DelegateWrapperStruct(type));
    }
}
