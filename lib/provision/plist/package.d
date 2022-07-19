module provision.plist;

import core.stdc.stdlib;
import core.stdc.string;
import provision.plist.c;

public alias PlistType = plist_type;

public abstract class Plist {
    private plist_t handle;
    private bool owns;

    this(plist_t handle, bool owns) {
        this.handle = handle;
        this.owns = owns;
    }

    public PlistType nodeType() {
        return plist_get_node_type(handle);
    }

    public static Plist wrap(plist_t handle, bool owns = true) {
        Plist obj;
        with (PlistType) switch (plist_get_node_type(handle)) {
            case PLIST_BOOLEAN:
                obj = New!PlistBoolean(handle, owns);
                break;
            case PLIST_UINT:
                obj = New!PlistUint(handle, owns);
                break;
            case PLIST_REAL:
                obj = New!PlistReal(handle, owns);
                break;
            case PLIST_STRING:
                obj = New!PlistString(handle, owns);
                break;
            case PLIST_ARRAY:
                obj = New!PlistArray(handle, owns);
                break;
            case PLIST_DICT:
                obj = New!PlistDict(handle, owns);
                break;
            case PLIST_DATE:
                obj = New!PlistDate(handle, owns);
                break;
            case PLIST_DATA:
                obj = New!PlistData(handle, owns);
                break;
            case PLIST_KEY:
                obj = New!PlistKey(handle, owns);
                break;
            case PLIST_UID:
                obj = New!PlistUid(handle, owns);
                break;
            case PLIST_NONE:
                obj = New!PlistNone(handle, owns);
                break;
            default:
                break;
        }

        return obj;
    }

    public static Plist fromXml(string xml) {
        plist_t handle;
        plist_from_xml(xml.ptr, cast(uint) xml.length, &handle);
        return wrap(handle);
    }

    public static Plist fromBin(ubyte[] bin) {
        plist_t handle;
        plist_from_bin(cast(const char*) bin.ptr, cast(uint) bin.length, &handle);
        return wrap(handle);
    }

    ~this() {
        if (owns && nodeType() != PlistType.PLIST_NONE) {
            plist_free(handle);
        }
    }

    public R copy(this R)() {
        return New!R(plist_copy(handle), true);
    }

    public string toXml() {
        char* str;
        uint length;
        plist_to_xml(handle, &str, &length);
        auto xml = cast(string) str[0..length].dup;
        plist_to_xml_free(str);
        return xml;
    }
}

public class PlistBoolean: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(bool val) {
        this(plist_new_bool(val), true);
    }

    public T opCast(T: bool)() {
        byte val;
        plist_get_bool_val(handle, &val);
        return cast(T) val;
    }

    public void opAssign(bool val) {
        plist_set_bool_val(handle, val);
    }
}

class PlistUint: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(ulong val) {
        this(plist_new_uint(val), true);
    }

    public T opCast(T)() if (isUnsigned!T) {
        ulong val;
        plist_get_uint_val(handle, &val);
        return cast(T) val;
    }

    public void opAssign(T)(T val) if (isUnsigned!T) {
        plist_set_uint_val(handle, cast(ulong) val);
    }
}

class PlistReal: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(double val) {
        this(plist_new_real(val), true);
    }

    public T opCast(T)() if (isFloatingPoint!T) {
        double val;
        plist_get_real_val(handle, &val);
        return cast(T) val;
    }

    public void opAssign(T)(T val) if (isFloatingPoint!T) {
        plist_set_real_val(handle, cast(double) val);
    }
}

class PlistString: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(char* val) {
        this(plist_new_string(val), true);
    }

    public T opCast(T)() if (isSomeString!T) {
        char* val;
        plist_get_string_val(handle, &val);
        auto str = val.fromStringz.dup;
        plist_mem_free(val);
        return cast(T) str;
    }

    public void opAssign(char* val) {
        plist_set_string_val(handle, cast(const char*) val);
    }
}

class PlistArray: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this() {
        this(plist_new_array(), true);
    }

    public uint length() {
        return plist_array_get_size(handle);
    }

    public uint opDollar(size_t pos)() {
        return length();
    }

    public Plist opIndex(uint index) {
        return Plist.wrap(plist_array_get_item(handle, index), false);
    }

    public void opIndexAssign(Plist element, uint key) {
        element.owns = false;
        plist_array_set_item(handle, element.handle, key);
    }

    public void opOpAssign(string s: "~")(Plist element) {
        element.owns = false;
        plist_array_append_item(handle, element.handle);
    }

    class PlistArrayIter {
        private plist_array_iter handle;
        private PlistArray array;

        public this(plist_array_iter handle, PlistArray array) {
            this.handle = handle;
            this.array = array;
        }

        ~this() {
            free(handle);
        }

        bool next(out Plist plist) {
            plist_t plist_h;
            plist_array_next_item(array.handle, handle, &plist_h);
            if (!plist_h)
                return false;
            plist = Plist.wrap(plist_h, false);
            return true;
        }
    }

    public PlistArrayIter iter() {
        plist_array_iter iter;
        plist_array_new_iter(handle, &iter);
        return New!PlistArrayIter(iter, this);
    }
}

class PlistDict: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this() {
        this(plist_new_dict(), true);
    }

    public uint length() {
        return plist_dict_get_size(handle);
    }

    public uint opDollar(size_t pos)() {
        return length();
    }

    public Plist opIndex(char* key) {
        auto item = plist_dict_get_item(handle, key);
        return item ? Plist.wrap(item, false) : null;
    }

    public void opIndexAssign(Plist element, char* key) {
        element.owns = false;
        plist_dict_set_item(handle, key, element.handle);
    }

    class PlistDictIter {
        private plist_dict_iter handle;
        private PlistDict dict;

        public this(plist_dict_iter handle, PlistDict dict) {
            this.handle = handle;
            this.dict = dict;
        }

        ~this() {
            free(handle);
        }

        bool next(out Plist plist, out string key) {
            plist_t plist_h = null;
            char* k = null;
            plist_dict_next_item(dict.handle, handle, &k, &plist_h);
            if (!plist_h)
                return false;
            key = cast(string) k[0..strlen(k)];

            plist = Plist.wrap(plist_h, false);
            return true;
        }
    }

    public PlistDictIter iter() {
        plist_dict_iter iter;
        plist_dict_new_iter(handle, &iter);
        return New!PlistDictIter(iter, this);
    }
}

class PlistDate: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    // public this() {
    //     this(plist_new_date(), true);
    // }
}

class PlistData: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(ubyte[] val) {
        this(plist_new_data(cast(const char*) val.ptr, val.length), true);
    }

    public ubyte[] opCast(T: ubyte[])() {
        char* ptr;
        ulong length;
        plist_get_data_val(handle, &ptr, &length);
        auto data = cast(ubyte[]) ptr[0..length].dup;
        plist_mem_free(ptr);
        return data;
    }

    public void opAssign(ubyte[] val) {
        plist_set_data_val(handle, cast(const char*) val.ptr, val.length);
    }
}

class PlistKey: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }
}

class PlistUid: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }

    public this(ulong val) {
        this(plist_new_uid(val), true);
    }

    public void opAssign(ulong val) {
        plist_set_uid_val(handle, val);
    }
}

class PlistNone: Plist {
    public this(plist_t handle, bool owns) {
        super(handle, owns);
    }
}

