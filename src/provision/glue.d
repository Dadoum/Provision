module provision.glue;

import std.stdio;
import std.string;
import provision.androidclass;
import provision.utils.loghelper;
import core.stdc.stdlib;

extern (C) {
    struct string_vector;
    string_vector* string_vector_create();
    void string_vector_push_back(string_vector*, const(char)*);
    void string_vector_delete(string_vector*);

    alias DestructionDelegate = extern (C) void function(void*);
    OpaquePtr* shared_ptr_create(const(OpaquePtr*), DestructionDelegate);
    OpaquePtr* shared_ptr_get(const(OpaquePtr*));
    void shared_ptr_delete(const(OpaquePtr*));

    struct StringStringMultimap;
    StringStringMultimap* str_str_multimap_create();
    void str_str_multimap_delete(StringStringMultimap*);
    void str_str_multimap_to_string(StringStringMultimap*);
    void str_str_multimap_insert(StringStringMultimap*, void* key, void* value);
}
