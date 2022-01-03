module provision.glue;

import std.stdio;
import std.string;
import provision.androidclass;
import provision.utils.loghelper;
import core.stdc.stdlib;

extern(C++, mediaplatform) {
    struct HeaderComparison { }
}

alias StdNamespace = AliasSeq!("std", "__ndk1");
alias StdChronoNamespace = AliasSeq!("std", "__ndk1", "chrono");
extern (C++, (StdNamespace)) {
    struct shared_ptr(T) {
        ~this() { }

        AndroidClassPtr* ptr;
        void* _control_block;
    }

    struct pair(T1, T2) {}
    struct vector(T, TAlloc) {}

    alias string_vector = vector!(NdkString, allocator!NdkString);

    struct multimap(TKey, TValue, TComp, TAllocator) {}
    alias headers_multimap = multimap!(NdkString, NdkString, HeaderComparison, allocator!(pair!(const(NdkString), NdkString)));

    struct ratio(long l1, long l2);
}

extern (C++, (StdChronoNamespace)) {
    struct duration(T1, T2) {
        size_t[8] __padding;
    }

    alias std_duration = duration!(double, ratio!(1, 1));
}

extern (C) {
    string_vector* string_vector_create();
    void string_vector_push_back(string_vector*, const(char)*);
    void string_vector_delete(string_vector*);

    alias DestructionDelegate = extern (C) void function(void*);
    OpaquePtr* shared_ptr_create(const(OpaquePtr*), DestructionDelegate);
    OpaquePtr* shared_ptr_get(const(OpaquePtr*));
    void shared_ptr_delete(const(OpaquePtr*));

    headers_multimap* str_str_multimap_create();
    void str_str_multimap_delete(headers_multimap*);
    void str_str_multimap_to_string(headers_multimap*);
    void str_str_multimap_insert(headers_multimap*, void* key, void* value);

    std_duration* std_duration_create();
    void std_duration_delete(std_duration*);

    const(char)* std_string_c_str(const(void*));
}

shared_ptr!T create_shared(T)(T* instance) {
    alias DestructionDelegate = extern (C) void function(void*);
    auto sharedptr = cast(shared_ptr!T*) shared_ptr_create(
    cast(OpaquePtr*) instance.handle, cast(DestructionDelegate)(pointer) {
        destroy(pointer);
    });
    return *sharedptr;
}

void destroy_shared(T)(shared_ptr!T pointer) {
    return shared_ptr_delete(*(cast(const(OpaquePtr**))&pointer));
}

T* get(T)(ref shared_ptr!T sharedp) if (__traits(hasMember, T, "wrap")) {
    return T.wrap(sharedp.ptr);
}
