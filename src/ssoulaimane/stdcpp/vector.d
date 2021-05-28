/**
 * D header file for interaction with C++ std::vector.
 *
 * Copyright: Copyright (c) 2018 D Language Foundation
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Guillaume Chatelet
 *            Manu Evans
 * Source:    $(DRUNTIMESRC core/stdcpp/vector.d)
 */

module ssoulaimane.stdcpp.vector;

///////////////////////////////////////////////////////////////////////////////
// std::vector declaration.
//
// Current caveats :
// - missing noexcept
// - nothrow @trusted @nogc for most functions depend on knowledge
//   of T's construction/destruction/assignment semantics
///////////////////////////////////////////////////////////////////////////////

import core.stdcpp.allocator;
import core.stdcpp.xutility : StdNamespace;

enum DefaultConstruct { value }

/// Constructor argument for default construction
enum Default = DefaultConstruct();

extern(C++, (StdNamespace)):

extern(C++, class) struct vector(T, Alloc = allocator!T)
{
    import core.lifetime : forward, move, moveEmplace, core_emplace = emplace;
    import core.internal.lifetime : emplaceInitializer;

    static assert(!is(T == bool), "vector!bool not supported!");
extern(D):

    ///
    alias size_type = size_t;
    ///
    alias difference_type = ptrdiff_t;
    ///
    alias value_type = T;
    ///
    alias allocator_type = Alloc;
    ///
    alias pointer = T*;
    ///
    alias const_pointer = const(T)*;

    /// MSVC allocates on default initialisation in debug, which can't be modelled by D `struct`
    @disable this();

    ///
    alias length = size;
    ///
    alias opDollar = length;

    ///
    size_t[2] opSlice(size_t dim : 0)(size_t start, size_t end) const pure nothrow @safe @nogc { return [start, end]; }

    ///
    ref inout(T) opIndex(size_t index) inout pure nothrow @safe @nogc       { return as_array[index]; }
    ///
    inout(T)[] opIndex(size_t[2] slice) inout pure nothrow @safe @nogc      { return as_array[slice[0] .. slice[1]]; }
    ///
    inout(T)[] opIndex() inout pure nothrow @safe @nogc                     { return as_array(); }

    ///
    ref vector opAssign(U)(auto ref vector!(U, Alloc) s)                    { opAssign(s.as_array); return this; }

    ///
    void opIndexAssign()(auto ref T val, size_t index)                      { as_array[index] = val; }
    ///
    void opIndexAssign()(auto ref T val, size_t[2] slice)                   { as_array[slice[0] .. slice[1]] = val; }
    ///
    void opIndexAssign(T[] val, size_t[2] slice)                            { as_array[slice[0] .. slice[1]] = val[]; }
    ///
    void opIndexAssign()(auto ref T val)                                    { as_array[] = val; }
    ///
    void opIndexAssign(T[] val)                                             { as_array[] = val[]; }

    ///
    void opIndexOpAssign(string op)(auto ref T val, size_t index)           { mixin("as_array[index] " ~ op ~ "= val;"); }
    ///
    void opIndexOpAssign(string op)(auto ref T val, size_t[2] slice)        { mixin("as_array[slice[0] .. slice[1]] " ~ op ~ "= val;"); }
    ///
    void opIndexOpAssign(string op)(T[] val, size_t[2] slice)               { mixin("as_array[slice[0] .. slice[1]] " ~ op ~ "= val[];"); }
    ///
    void opIndexOpAssign(string op)(auto ref T val)                         { mixin("as_array[] " ~ op ~ "= val;"); }
    ///
    void opIndexOpAssign(string op)(T[] val)                                { mixin("as_array[] " ~ op ~ "= val[];"); }

    ///
    ref inout(T) front() inout pure nothrow @safe @nogc                     { return as_array[0]; }
    ///
    ref inout(T) back() inout pure nothrow @safe @nogc                      { return as_array[$-1]; }

    ///
    ref vector opOpAssign(string op : "~")(auto ref T item)                 { push_back(forward!item); return this; }
    ///
    ref vector opOpAssign(string op : "~")(T[] array)                       { insert(length, array); return this; }

    ///
    void append(T[] array)                                                  { insert(length, array); }


    // Modifiers
    ///
    void push_back(U)(auto ref U element)
    {
        emplace_back(forward!element);
    }

    version (CppRuntime_Microsoft)
    {
        //----------------------------------------------------------------------------------
        // Microsoft runtime
        //----------------------------------------------------------------------------------

        ///
        this(DefaultConstruct) @nogc                                        { _Alloc_proxy(); }
        ///
        this()(size_t count)
        {
            _Alloc_proxy();
            _Buy(count);
            scope(failure) _Tidy();
            _Get_data()._Mylast = _Udefault(_Get_data()._Myfirst, count);
        }
        ///
        this()(size_t count, auto ref T val)
        {
            _Alloc_proxy();
            _Buy(count);
            scope(failure) _Tidy();
            _Get_data()._Mylast = _Ufill(_Get_data()._Myfirst, count, val);
        }
        ///
        this()(T[] array)
        {
            _Alloc_proxy();
            _Buy(array.length);
            scope(failure) _Tidy();
            _Get_data()._Mylast = _Utransfer!false(array.ptr, array.ptr + array.length, _Get_data()._Myfirst);
        }
        ///
        this(this)
        {
            _Alloc_proxy();
            pointer _First = _Get_data()._Myfirst;
            pointer _Last = _Get_data()._Mylast;
            _Buy(_Last - _First);
            scope(failure) _Tidy();
            _Get_data()._Mylast = _Utransfer!false(_First, _Last, _Get_data()._Myfirst);
        }

        ///
        ~this()                                                             { _Tidy(); }

        ///
        ref inout(Alloc) get_allocator() inout pure nothrow @safe @nogc     { return _Getal(); }

        ///
        size_type max_size() const pure nothrow @safe @nogc                 { return ((size_t.max / T.sizeof) - 1) / 2; } // HACK: clone the windows version precisely?

        ///
        size_type size() const pure nothrow @safe @nogc                     { return _Get_data()._Mylast - _Get_data()._Myfirst; }
        ///
        size_type capacity() const pure nothrow @safe @nogc                 { return _Get_data()._Myend - _Get_data()._Myfirst; }
        ///
        bool empty() const pure nothrow @safe @nogc                         { return _Get_data()._Myfirst == _Get_data()._Mylast; }
        ///
        inout(T)* data() inout pure nothrow @safe @nogc                     { return _Get_data()._Myfirst; }
        ///
        inout(T)[] as_array() inout pure nothrow @trusted @nogc             { return _Get_data()._Myfirst[0 .. size()]; }
        ///
        ref inout(T) at(size_type i) inout pure nothrow @trusted @nogc      { return _Get_data()._Myfirst[0 .. size()][i]; }

        ///
        ref vector opAssign(T[] array)
        {
            clear();
            reserve(array.length);
            insert(0, array);
            return this;
        }

        ///
        ref T emplace_back(Args...)(auto ref Args args)
        {
            if (_Has_unused_capacity())
                return _Emplace_back_with_unused_capacity(forward!args);
            return *_Emplace_reallocate(_Get_data()._Mylast, forward!args);
        }

        ///
        void reserve(const size_type newCapacity)
        {
            if (newCapacity > capacity())
            {
//                if (newCapacity > max_size())
//                    _Xlength();
                _Reallocate_exactly(newCapacity);
            }
        }

        ///
        void shrink_to_fit()
        {
            if (_Has_unused_capacity())
            {
                if (empty())
                    _Tidy();
                else
                    _Reallocate_exactly(size());
            }
        }

        ///
        void pop_back()
        {
            static if (_ITERATOR_DEBUG_LEVEL == 2)
            {
                assert(!empty(), "vector empty before pop");
                _Orphan_range(_Get_data()._Mylast - 1, _Get_data()._Mylast);
            }
            destroy!false(_Get_data()._Mylast[-1]);
            --_Get_data()._Mylast;
        }

        ///
        void clear()
        {
            _Base._Orphan_all();
            _Destroy(_Get_data()._Myfirst, _Get_data()._Mylast);
            _Get_data()._Mylast = _Get_data()._Myfirst;
        }

        ///
        void resize()(const size_type newsize)
        {
            static assert(is(typeof({static T i;})), T.stringof ~ ".this() is annotated with @disable.");
            _Resize(newsize, (pointer _Dest, size_type _Count) => _Udefault(_Dest, _Count));
        }

        ///
        void resize()(const size_type newsize, auto ref T val)
        {
            _Resize(newsize, (pointer _Dest, size_type _Count) => _Ufill(_Dest, _Count, forward!val));
        }

        void emplace(Args...)(size_t offset, auto ref Args args)
        {
            pointer _Whereptr = _Get_data()._Myfirst + offset;
            pointer _Oldlast = _Get_data()._Mylast;
            if (_Has_unused_capacity())
            {
                if (_Whereptr == _Oldlast)
                    _Emplace_back_with_unused_capacity(forward!args);
                else
                {
                    T _Obj = T(forward!args);
                    static if (_ITERATOR_DEBUG_LEVEL == 2)
                        _Orphan_range(_Whereptr, _Oldlast);
                    move(_Oldlast[-1], *_Oldlast);
                    ++_Get_data()._Mylast;
                    _Move_backward_unchecked(_Whereptr, _Oldlast - 1, _Oldlast);
                    move(_Obj, *_Whereptr);
                }
                return;
            }
            _Emplace_reallocate(_Whereptr, forward!args);
        }

        ///
        void insert()(size_t offset, auto ref T value)
        {
            T[] array = (&value)[0 .. 1];
            insert(offset, array);
        }

        ///
        void insert(size_t offset, T[] array)
        {
            pointer _Where = _Get_data()._Myfirst + offset;
            pointer _First = array.ptr;
            pointer _Last = _First + array.length;

            const size_type _Count = array.length;
            const size_type _Whereoff = offset;
            const bool _One_at_back = _Count == 1 && _Get_data()._Myfirst + _Whereoff == _Get_data()._Mylast;

            if (_Count == 0)
            {
                // nothing to do, avoid invalidating iterators
            }
            else if (_Count > _Unused_capacity())
            {   // reallocate
                const size_type _Oldsize = size();

//                if (_Count > max_size() - _Oldsize)
//                    _Xlength();

                const size_type _Newsize = _Oldsize + _Count;
                const size_type _Newcapacity = _Calculate_growth(_Newsize);

                pointer _Newvec = _Getal().allocate(_Newcapacity);
                pointer _Constructed_last = _Newvec + _Whereoff + _Count;
                pointer _Constructed_first = _Constructed_last;

                try
                {
                    _Utransfer!false(_First, _Last, _Newvec + _Whereoff);
                    _Constructed_first = _Newvec + _Whereoff;

                    if (_One_at_back)
                    {
                        _Utransfer!(true, true)(_Get_data()._Myfirst, _Get_data()._Mylast, _Newvec);
                    }
                    else
                    {
                        _Utransfer!true(_Get_data()._Myfirst, _Where, _Newvec);
                        _Constructed_first = _Newvec;
                        _Utransfer!true(_Where, _Get_data()._Mylast, _Newvec + _Whereoff + _Count);
                    }
                }
                catch (Throwable e)
                {
                    _Destroy(_Constructed_first, _Constructed_last);
                    _Getal().deallocate(_Newvec, _Newcapacity);
                    throw e;
                }

                _Change_array(_Newvec, _Newsize, _Newcapacity);
            }
            else
            {   // Attempt to provide the strong guarantee for EmplaceConstructible failure.
                // If we encounter copy/move construction/assignment failure, provide the basic guarantee.
                // (For one-at-back, this provides the strong guarantee.)

                pointer _Oldlast = _Get_data()._Mylast;
                const size_type _Affected_elements = cast(size_type)(_Oldlast - _Where);

                if (_Count < _Affected_elements)
                {    // some affected elements must be assigned
                    _Get_data()._Mylast = _Utransfer!true(_Oldlast - _Count, _Oldlast, _Oldlast);
                    _Move_backward_unchecked(_Where, _Oldlast - _Count, _Oldlast);
                    _Destroy(_Where, _Where + _Count);

                    try
                    {
                        _Utransfer!false(_First, _Last, _Where);
                    }
                    catch (Throwable e)
                    {
                        // glue the broken pieces back together
                        try
                        {
                            _Utransfer!true(_Where + _Count, _Where + 2 * _Count, _Where);
                        }
                        catch (Throwable e)
                        {
                            // vaporize the detached piece
                            static if (_ITERATOR_DEBUG_LEVEL == 2)
                                _Orphan_range(_Where, _Oldlast);
                            _Destroy(_Where + _Count, _Get_data()._Mylast);
                            _Get_data()._Mylast = _Where;
                            throw e;
                        }

                        _Move_unchecked(_Where + 2 * _Count, _Get_data()._Mylast, _Where + _Count);
                        _Destroy(_Oldlast, _Get_data()._Mylast);
                        _Get_data()._Mylast = _Oldlast;
                        throw e;
                    }
                }
                else
                {   // affected elements don't overlap before/after
                    pointer _Relocated = _Where + _Count;
                    _Get_data()._Mylast = _Utransfer!true(_Where, _Oldlast, _Relocated);
                    _Destroy(_Where, _Oldlast);

                    try
                    {
                        _Utransfer!false(_First, _Last, _Where);
                    }
                    catch (Throwable e)
                    {
                        // glue the broken pieces back together
                        try
                        {
                            _Utransfer!true(_Relocated, _Get_data()._Mylast, _Where);
                        }
                        catch (Throwable e)
                        {
                            // vaporize the detached piece
                            static if (_ITERATOR_DEBUG_LEVEL == 2)
                                _Orphan_range(_Where, _Oldlast);
                            _Destroy(_Relocated, _Get_data()._Mylast);
                            _Get_data()._Mylast = _Where;
                            throw e;
                        }

                        _Destroy(_Relocated, _Get_data()._Mylast);
                        _Get_data()._Mylast = _Oldlast;
                        throw e;
                    }
                }
                static if (_ITERATOR_DEBUG_LEVEL == 2)
                    _Orphan_range(_Where, _Oldlast);
            }
        }

    private:
        import core.stdcpp.xutility : MSVCLinkDirectives;

        // Make sure the object files wont link against mismatching objects
        mixin MSVCLinkDirectives!true;

        pragma(inline, true)
        {
            ref inout(_Base.Alloc) _Getal() inout pure nothrow @safe @nogc       { return _Base._Mypair._Myval1; }
            ref inout(_Base.ValTy) _Get_data() inout pure nothrow @safe @nogc    { return _Base._Mypair._Myval2; }
        }

        void _Alloc_proxy() @nogc
        {
            static if (_ITERATOR_DEBUG_LEVEL > 0)
                _Base._Alloc_proxy();
        }

        void _AssignAllocator(ref const(allocator_type) al) nothrow @nogc
        {
            static if (_Base._Mypair._HasFirst)
                _Getal() = al;
        }

        bool _Buy(size_type _Newcapacity) @trusted @nogc
        {
            _Get_data()._Myfirst = null;
            _Get_data()._Mylast = null;
            _Get_data()._Myend = null;

            if (_Newcapacity == 0)
                return false;

            // TODO: how to handle this in D? kinda like a range exception...
//            if (_Newcapacity > max_size())
//                _Xlength();

            _Get_data()._Myfirst = _Getal().allocate(_Newcapacity);
            _Get_data()._Mylast = _Get_data()._Myfirst;
            _Get_data()._Myend = _Get_data()._Myfirst + _Newcapacity;

            return true;
        }

        static void _Destroy(pointer _First, pointer _Last)
        {
            for (; _First != _Last; ++_First)
                destroy!false(*_First);
        }

        void _Tidy()
        {
            _Base._Orphan_all();
            if (_Get_data()._Myfirst)
            {
                _Destroy(_Get_data()._Myfirst, _Get_data()._Mylast);
                _Getal().deallocate(_Get_data()._Myfirst, capacity());
                _Get_data()._Myfirst = null;
                _Get_data()._Mylast = null;
                _Get_data()._Myend = null;
            }
        }

        size_type _Unused_capacity() const pure nothrow @safe @nogc
        {
            return _Get_data()._Myend - _Get_data()._Mylast;
        }

        bool _Has_unused_capacity() const pure nothrow @safe @nogc
        {
            return _Get_data()._Myend != _Get_data()._Mylast;
        }

        ref T _Emplace_back_with_unused_capacity(Args...)(auto ref Args args)
        {
            core_emplace(_Get_data()._Mylast, forward!args);
            static if (_ITERATOR_DEBUG_LEVEL == 2)
                _Orphan_range(_Get_data()._Mylast, _Get_data()._Mylast);
            return *_Get_data()._Mylast++;
        }

        pointer _Emplace_reallocate(_Valty...)(pointer _Whereptr, auto ref _Valty _Val)
        {
            const size_type _Whereoff = _Whereptr - _Get_data()._Myfirst;
            const size_type _Oldsize = size();

            // TODO: what should we do in D? kinda like a range overflow?
//            if (_Oldsize == max_size())
//                _Xlength();

            const size_type _Newsize = _Oldsize + 1;
            const size_type _Newcapacity = _Calculate_growth(_Newsize);

            pointer _Newvec = _Getal().allocate(_Newcapacity);
            pointer _Constructed_last = _Newvec + _Whereoff + 1;
            pointer _Constructed_first = _Constructed_last;

            try
            {
                core_emplace(_Newvec + _Whereoff, forward!_Val);
                _Constructed_first = _Newvec + _Whereoff;
                if (_Whereptr == _Get_data()._Mylast)
                    _Utransfer!(true, true)(_Get_data()._Myfirst, _Get_data()._Mylast, _Newvec);
                else
                {
                    _Utransfer!true(_Get_data()._Myfirst, _Whereptr, _Newvec);
                    _Constructed_first = _Newvec;
                    _Utransfer!true(_Whereptr, _Get_data()._Mylast, _Newvec + _Whereoff + 1);
                }
            }
            catch (Throwable e)
            {
                _Destroy(_Constructed_first, _Constructed_last);
                _Getal().deallocate(_Newvec, _Newcapacity);
                throw e;
            }

            _Change_array(_Newvec, _Newsize, _Newcapacity);
            return _Get_data()._Myfirst + _Whereoff;
        }

        void _Resize(_Lambda)(const size_type _Newsize, _Lambda _Udefault_or_fill)
        {
            const size_type _Oldsize = size();
            const size_type _Oldcapacity = capacity();

            if (_Newsize > _Oldcapacity)
            {
//                if (_Newsize > max_size())
//                    _Xlength();

                const size_type _Newcapacity = _Calculate_growth(_Newsize);

                pointer _Newvec = _Getal().allocate(_Newcapacity);
                pointer _Appended_first = _Newvec + _Oldsize;
                pointer _Appended_last = _Appended_first;

                try
                {
                    _Appended_last = _Udefault_or_fill(_Appended_first, _Newsize - _Oldsize);
                    _Utransfer!(true, true)(_Get_data()._Myfirst, _Get_data()._Mylast, _Newvec);
                }
                catch (Throwable e)
                {
                    _Destroy(_Appended_first, _Appended_last);
                    _Getal().deallocate(_Newvec, _Newcapacity);
                    throw e;
                }
                _Change_array(_Newvec, _Newsize, _Newcapacity);
            }
            else if (_Newsize > _Oldsize)
            {
                pointer _Oldlast = _Get_data()._Mylast;
                _Get_data()._Mylast = _Udefault_or_fill(_Oldlast, _Newsize - _Oldsize);
                static if (_ITERATOR_DEBUG_LEVEL == 2)
                    _Orphan_range(_Oldlast, _Oldlast);
            }
            else if (_Newsize == _Oldsize)
            {
                // nothing to do, avoid invalidating iterators
            }
            else
            {
                pointer _Newlast = _Get_data()._Myfirst + _Newsize;
                static if (_ITERATOR_DEBUG_LEVEL == 2)
                    _Orphan_range(_Newlast, _Get_data()._Mylast);
                _Destroy(_Newlast, _Get_data()._Mylast);
                _Get_data()._Mylast = _Newlast;
            }
        }

        void _Reallocate_exactly(const size_type _Newcapacity)
        {
            const size_type _Size = size();
            pointer _Newvec = _Getal().allocate(_Newcapacity);

            try
            {
                for (size_t i = _Size; i > 0; )
                {
                    --i;
                    _Get_data()._Myfirst[i].moveEmplace(_Newvec[i]);
                }
            }
            catch (Throwable e)
            {
                _Getal().deallocate(_Newvec, _Newcapacity);
                throw e;
            }

            _Change_array(_Newvec, _Size, _Newcapacity);
        }

        void _Change_array(pointer _Newvec, const size_type _Newsize, const size_type _Newcapacity)
        {
            _Base._Orphan_all();

            if (_Get_data()._Myfirst != null)
            {
                _Destroy(_Get_data()._Myfirst, _Get_data()._Mylast);
                _Getal().deallocate(_Get_data()._Myfirst, capacity());
            }

            _Get_data()._Myfirst = _Newvec;
            _Get_data()._Mylast = _Newvec + _Newsize;
            _Get_data()._Myend = _Newvec + _Newcapacity;
        }

        size_type _Calculate_growth(const size_type _Newsize) const pure nothrow @nogc @safe
        {
            const size_type _Oldcapacity = capacity();
            if (_Oldcapacity > max_size() - _Oldcapacity/2)
                return _Newsize;
            const size_type _Geometric = _Oldcapacity + _Oldcapacity/2;
            if (_Geometric < _Newsize)
                return _Newsize;
            return _Geometric;
        }

        struct _Uninitialized_backout
        {
            this() @disable;
            this(pointer _Dest)
            {
                _First = _Dest;
                _Last = _Dest;
            }
            ~this()
            {
                _Destroy(_First, _Last);
            }
            void _Emplace_back(Args...)(auto ref Args args)
            {
                core_emplace(_Last, forward!args);
                ++_Last;
            }
            pointer _Release()
            {
                _First = _Last;
                return _Last;
            }
        private:
            pointer _First;
            pointer _Last;
        }
        pointer _Utransfer(bool _move, bool _ifNothrow = false)(pointer _First, pointer _Last, pointer _Dest)
        {
            // TODO: if copy/move are trivial, then we can memcpy/memmove
            auto _Backout = _Uninitialized_backout(_Dest);
            for (; _First != _Last; ++_First)
            {
                static if (_move && (!_ifNothrow || true)) // isNothrow!T (move in D is always nothrow! ...until opPostMove)
                    _Backout._Emplace_back(move(*_First));
                else
                    _Backout._Emplace_back(*_First);
            }
            return _Backout._Release();
        }
        pointer _Ufill()(pointer _Dest, size_t _Count, auto ref T val)
        {
            // TODO: if T.sizeof == 1 and no elaborate constructor, fast-path to memset
            // TODO: if copy ctor/postblit are nothrow, just range assign
            auto _Backout = _Uninitialized_backout(_Dest);
            for (; 0 < _Count; --_Count)
                _Backout._Emplace_back(val);
            return _Backout._Release();
        }
        pointer _Udefault()(pointer _Dest, size_t _Count)
        {
            // TODO: if zero init, then fast-path to zeromem
            auto _Backout = _Uninitialized_backout(_Dest);
            for (; 0 < _Count; --_Count)
                _Backout._Emplace_back();
            return _Backout._Release();
        }
        pointer _Move_unchecked(pointer _First, pointer _Last, pointer _Dest)
        {
            // TODO: can `memmove` if conditions are right...
            for (; _First != _Last; ++_Dest, ++_First)
                move(*_First, *_Dest);
            return _Dest;
        }
        pointer _Move_backward_unchecked(pointer _First, pointer _Last, pointer _Dest)
        {
            while (_First != _Last)
                move(*--_Last, *--_Dest);
            return _Dest;
        }

        static if (_ITERATOR_DEBUG_LEVEL == 2)
        {
            void _Orphan_range(pointer _First, pointer _Last) const @nogc
            {
                import core.stdcpp.xutility : _Lockit, _LOCK_DEBUG;

                alias const_iterator = _Base.const_iterator;
                auto _Lock = _Lockit(_LOCK_DEBUG);

                const_iterator** _Pnext = cast(const_iterator**)_Get_data()._Base._Getpfirst();
                if (!_Pnext)
                    return;

                while (*_Pnext)
                {
                    if ((*_Pnext)._Ptr < _First || _Last < (*_Pnext)._Ptr)
                    {
                        _Pnext = cast(const_iterator**)(*_Pnext)._Base._Getpnext();
                    }
                    else
                    {
                        (*_Pnext)._Base._Clrcont();
                        *_Pnext = *cast(const_iterator**)(*_Pnext)._Base._Getpnext();
                    }
                }
            }
        }

        _Vector_alloc!(_Vec_base_types!(T, Alloc)) _Base;
    }
    else version (CppRuntime_Gcc)
    {
    public:
        // construct/copy/destroy
        // (assign() and get_allocator() are also listed in this section)

        ///
        this(DefaultConstruct) @nogc { }

        ///
        this()(auto ref allocator_type a) nothrow
        {
            _Base = forward!a;
        }

        ///
        this()(size_type n, auto ref allocator_type a = allocator_type.init)
        {
            _Base.__ctor(n, forward!a);
            _M_default_initialize(n);
        }

        ///
        this()(size_type n, auto ref value_type value, auto ref allocator_type a = allocator_type.init)
        {
            _Base.__ctor(n, forward!a);
            _M_fill_initialize(n, forward!value);
        }

        ///
        this(ref vector x)
        {
            const __n = x.size();
            _Base.__ctor(__n, _Alloc_traits.select_on_container_copy_construction(x._Base._M_get_Tp_allocator()));
            emplaceSlice(x.as_array, _Base._M_impl._M_start[0 .. __n]);
            _Base._M_impl._M_finish = _Base._M_impl._M_start + __n;
        }

        this()(auto ref vector __x)
        if (!__traits(isRef, __x))
        {
            _Base = move(__x._Base);
        }

        /// Copy constructor with alternative allocator
        this()(ref vector x, auto ref allocator_type a)
        {
            const __n = x.size();
            _Base.__ctor(__n, forward!a);
            emplaceSlice(x.as_array, _Base._M_impl._M_start[0 .. __n]);
            _Base._M_impl._M_finish = _Base._M_impl._M_start + __n;
        }

        /// Move constructor with alternative allocator
        this()(auto ref vector __rv, auto ref allocator_type __m)
        if (!__traits(isRef, __rv))
        {
            _Base.__ctor(move(__rv._Base), forward!__m);
            static if (!_Alloc_traits.is_always_equal)
            {
                if (__rv.get_allocator() != __m)
                {
                    moveEmplaceSlice(__x.as_array, _Base._M_impl._M_start[0 .. __n]);
                    _Base._M_impl._M_finish = _Base._M_impl._M_start + __n;
                    __rv.clear();
                }
            }
        }

        ///
        this(T[] array, auto ref allocator_type a = allocator_type())
        {
            _Base = forward!a;
            _M_array_initialize(array);
        }

        ///
        ~this()
        {
            pointer __p = _Base._M_impl._M_start;
            pointer __end = _Base._M_impl._M_finish;
            for (; __p != __end; ++__p)
                destroy!false(*__p);
            mixin(_GLIBCXX_ASAN_ANNOTATE_BEFORE_DEALLOC);
        }

        ref vector opAssign()(auto ref vector __x)
        if (!__traits(isRef, __x))
        {
            enum bool __move_storage = _Alloc_traits.propagate_on_container_move_assignment
                                    || _Alloc_traits.is_always_equal;
            _M_move_assign!__move_storage(__x);
            return this;
        }

        ///
        ref vector opAssign(T[] array)
        {
            _M_assign_aux(array);
            return this;
        }

        ///
        void assign()(size_type n, auto ref T value)
        {
            _M_fill_assign(n, value);
        }

        ///
        void assign(T[] array)
        {
            this._M_assign_aux(array);
        }

        /// Get a copy of the memory allocation object.
        allocator_type get_allocator()
        {
            return _Base.get_allocator();
        }

        // capacity

        ///
        size_type size() const pure nothrow @safe @nogc
        {
            return size_type(_Base._M_impl._M_finish - _Base._M_impl._M_start);
        }

        ///
        size_type max_size() const pure nothrow @safe @nogc
        {
            return _Base._M_get_Tp_allocator().max_size;
        }

        ///
        void resize(size_type new_size)
        {
            if (new_size > size())
                _M_default_append(new_size - size());
            else if (new_size < size())
                _M_erase_at_end(_Base._M_impl._M_start + new_size);
        }

        ///
        void resize()(size_type new_size, auto ref T value)
        {
            if (new_size > size())
                _M_fill_insert(size(), new_size - size(), value);
            else if (new_size < size())
                _M_erase_at_end(_Base._M_impl._M_start + new_size);
        }

        ///
        void shrink_to_fit()
        {
            _M_shrink_to_fit();
        }

        ///
        size_type capacity() const pure nothrow @safe @nogc
        {
            return size_type(_Base._M_impl._M_end_of_storage - _Base._M_impl._M_start);
        }

        ///
        bool empty() const pure nothrow @safe @nogc
        {
            return _Base._M_impl._M_start == _Base._M_impl._M_finish;
        }

        ///
        void reserve(size_type n)
        {
//            import core.exception : RangeError;

            assert(n <= this.max_size());
//            if (n > this.max_size())
//                throw new RangeError("Length exceeds `max_size()`"); //__throw_length_error(__N("vector::reserve"));

            if (this.capacity() < n)
            {
                const size_type __old_size = size();
                pointer __tmp = _M_allocate_and_move_if_nothrow(n,
                        _Base._M_impl._M_start[0 .. __old_size]);
                mixin(_GLIBCXX_ASAN_ANNOTATE_REINIT);
                destroySlice!false(_Base._M_impl._M_start[0 .. __old_size]);
                _Base._M_deallocate(_Base._M_impl._M_start,
                        _Base._M_impl._M_end_of_storage - _Base._M_impl._M_start);
                _Base._M_impl._M_start = __tmp;
                _Base._M_impl._M_finish = __tmp + __old_size;
                _Base._M_impl._M_end_of_storage = _Base._M_impl._M_start + n;
            }
        }

    protected:
        // Safety check used only from at().
        void _M_range_check(size_type __n) const
        {
//            import core.exception : RangeError;

            assert(__n < this.size());
//            if (__n >= this.size())
//                throw new RangeError("Index exceeds `size()`"); //__throw_out_of_range_fmt(__N("vector::_M_range_check: __n "
        }

    public:

        ///
        ref inout(T) at(size_type n) inout pure nothrow @safe @nogc
        {
            _M_range_check(n);
            return this[n];
        }

        // data access

        ///
        inout(T)* data() inout pure nothrow @trusted @nogc
        {
            return _M_data_ptr(_Base._M_impl._M_start);
        }

        ///
        inout(T)[] as_array() inout pure nothrow @trusted @nogc
        {
            return _Base._M_impl._M_start[0 .. size()];
        }

        // modifiers

        ///
        void emplace_back(Args...)(auto ref Args __args)
        {
            if (_Base._M_impl._M_finish != _Base._M_impl._M_end_of_storage)
            {
                mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"1");
                core_emplace(_Base._M_impl._M_finish, forward!__args);
                ++_Base._M_impl._M_finish;
                mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"1");
            }
            else
                _M_realloc_insert(size(), forward!__args);
        }

        ///
        void pop_back()
        {
            assert(!empty);
            --_Base._M_impl._M_finish;
            destroy!false(*_Base._M_impl._M_finish);
            mixin(_GLIBCXX_ASAN_ANNOTATE_SHRINK!"1");
        }

        ///
        void emplace(Args)(size_type offset, auto ref Args args)
        {
            return _M_emplace_aux(offset, forward!args);
        }

        ///
        void insert(size_type offset, ref T value)
        {
            pointer __position = _Base._M_impl._M_start + offset;
            if (_Base._M_impl._M_finish != _Base._M_impl._M_end_of_storage)
            {
                if (__position == _Base._M_impl._M_finish)
                {
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"1");
                    core_emplace(_Base._M_impl._M_finish, value);
                    ++_Base._M_impl._M_finish;
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"1");
                }
                else
                {
                    // __x could be an existing element of this vector, so make a
                    // copy of it before _M_insert_aux moves elements around.
                    auto __x_copy = _Temporary_value(&this, value);
                    _M_insert_aux(offset, move(__x_copy._M_val));
                }
            }
            else
            {
                _M_realloc_insert(offset, value);
            }
        }

        ///
        void insert()(size_type offset, auto ref value_type value)
        if (!__traits(isRef, value))
        {
            return _M_insert_rval(offset, value);
        }

        ///
        void insert()(size_type offset, size_type n, auto ref T value)
        {
            _M_fill_insert(offset, n, forward!value);
        }

        ///
        void insert(size_type offset, T[] array)
        {
            _M_array_insert(offset, array);
        }

        ///
        void erase(size_type offset)
        {
            return _M_erase(offset);
        }

        ///
        void erase(size_type first, size_type last)
        {
            return _M_erase(first, last);
        }

        ///
        void swap(ref vector x) nothrow
        {
            static if (__cplusplus >= CppStdRevision.cpp11)
            {
                assert(_Alloc_traits.propagate_on_container_swap
                         || _Base._M_get_Tp_allocator() == x._Base._M_get_Tp_allocator());
            }
            _Base._M_impl._M_swap_data(x._Base._M_impl);
            _Base._M_impl.__alloc_on_swap(x._Base._M_get_Tp_allocator());
        }

        ///
        void clear()
        {
            _M_erase_at_end(_Base._M_impl._M_start);
        }

    protected:

        pointer _M_allocate_and_copy(size_type __n, value_type[] __array)
        {
            pointer __result = _Base._M_allocate(__n);
            try
            {
                emplaceSlice(__array, __result[0 .. __array.length]);
                return __result;
            }
            catch (Throwable e)
            {
                _Base._M_deallocate(__result, __n);
                throw e;
            }
        }

        pointer _M_allocate_and_move_if_nothrow(size_type __n, value_type[] __array)
        {
            pointer __result = _Base._M_allocate(__n);
            try
            {
                moveEmplaceSliceIfNothrow(__array, __result[0 .. __array.length]);
                return __result;
            }
            catch (Throwable e)
            {
                _Base._M_deallocate(__result, __n);
                throw e;
            }
        }

        // Internal constructor functions follow.

        // Called by the array constructor.
        void _M_array_initialize(bool __move_if_nothrow = false)(value_type[] __array)
        {
            const size_type __n = __array.length;
            _Base._M_impl._M_start = _Base._M_allocate(__n);
            _Base._M_impl._M_end_of_storage = _Base._M_impl._M_start + __n;
            static if (__move_if_nothrow) alias __emplacefn = moveEmplaceSliceIfNothrow;
            else                          alias __emplacefn = emplaceSlice;
            __emplacefn(__array, _Base._M_impl._M_start[0 .. __n]);
            _Base._M_impl._M_finish = _Base._M_impl._M_start + __n;
        }

        // Called by the vector(n,value,a) constructor.
        void _M_fill_initialize()(size_type __n, auto ref value_type __value)
        {
            emplaceFill(_Base._M_impl._M_start[0 .. __n], __value);
            _Base._M_impl._M_finish = _Base._M_impl._M_start + __n;
        }

        // Called by the vector(n) constructor.
        void _M_default_initialize(size_type __n)
        {
            foreach (i; 0 .. __n)
                emplaceInitializer(_Base._M_impl._M_start[i]);
            _Base._M_impl._M_finish = _Base._M_impl._M_start + __n;
        }

        // Internal assign functions follow.  The *_aux functions do the actual
        // assignment work for the range versions.

        // Called by the range assign to implement [23.1.1]/9
        void _M_assign_aux(bool __move_assign = false)(T[] __array)
        {
            const size_type __len = __array.length;

            if (__len > capacity())
            {
                pointer __tmp = _M_allocate_and_copy(__len, __array);
                mixin(_GLIBCXX_ASAN_ANNOTATE_REINIT);
                destroySlice!false(_Base._M_impl._M_start[0 .. size()]);
                _Base._M_deallocate(_Base._M_impl._M_start,
                        _Base._M_impl._M_end_of_storage - _Base._M_impl._M_start);
                _Base._M_impl._M_start = __tmp;
                _Base._M_impl._M_finish = _Base._M_impl._M_start + __len;
                _Base._M_impl._M_end_of_storage = _Base._M_impl._M_finish;
            }
            else if (size() >= __len)
            {
                static if (__move_assign)
                    moveSlice(__array, _Base._M_impl._M_start[0 .. __len]);
                else
                    _Base._M_impl._M_start[0 .. __len] = __array;
                _M_erase_at_end(_Base._M_impl._M_start + __len);
            }
            else
            {
                static if (__move_assign)
                    moveSlice(__array[0 .. size()], _Base._M_impl._M_start[0 .. size()]);
                else
                    _Base._M_impl._M_start[0 .. size()] = __array[0 .. size()];
                const size_type __n = __len - size();
                mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"__n");
                static if (__move_assign)
                    moveEmplaceSlice(__array[size() .. __len], _Base._M_impl._M_finish[0 .. __n]);
                else
                    emplaceSlice(__array[size() .. __len], _Base._M_impl._M_finish[0 .. __n]);
                _Base._M_impl._M_finish += __n;
                mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__n");
            }
        }

        // Called by assign(n,t), and the range assign when it turns out
        // to be the same thing.
        void _M_fill_assign()(size_type __n, auto ref value_type __val)
        {
            if (__n > capacity())
            {
                vector __tmp = vector(__n, __val);
                __tmp._M_impl._M_swap_data(_Base._M_impl);
            }
            else if (__n > size())
            {
                _Base._M_impl._M_start[0 .. size()] = __val;
                const size_type __add = __n - size();
                mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"__add");
                emplaceFill(_Base._M_impl._M_finish[0 .. __add], __val);
                _Base._M_impl._M_finish += __add;
                mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__add");
            }
            else
            {
                _Base._M_impl._M_start[0 .. __n] = __val;
                _M_erase_at_end(_Base._M_impl._M_start + __n);
            }
        }

        // Internal insert functions follow.

        // Called by the range insert to implement [23.1.1]/9

        void _M_array_insert()(size_type __offset, value_type[] __array)
        {
            if (const __n = __array.length)
            {
                pointer __position = _Base._M_impl._M_start + __offset;
                if (_Base._M_impl._M_end_of_storage - _Base._M_impl._M_finish >= __n)
                {
                    const size_type __elems_after = size() - __offset;
                    pointer __old_finish = _Base._M_impl._M_finish;
                    if (__elems_after > __n)
                    {
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"__n");
                        moveEmplaceSlice((_Base._M_impl._M_finish - __n)[0 .. __n],
                                _Base._M_impl._M_finish[0 .. __n]);
                        _Base._M_impl._M_finish += __n;
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__n");
                        const __remaining = __old_finish - __position - __n;
                        moveSliceBackward(__position[0 .. __remaining], __old_finish[0 .. __remaining]);
                        __position[0 .. __n] = __array;
                    }
                    else
                    {
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"__n");
                        emplaceSlice(__array[__elems_after .. __n],
                                _Base._M_impl._M_finish[0 .. __n - __elems_after]);
                        _Base._M_impl._M_finish += __n - __elems_after;
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__n - __elems_after");
                        moveEmplaceSlice(__position[0 .. __elems_after],
                                _Base._M_impl._M_finish[0 .. __elems_after]);
                        _Base._M_impl._M_finish += __elems_after;
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__elems_after");
                        __position[0 .. __elems_after] = __array[0 .. __elems_after];
                    }
                }
                else
                {
                    const size_type __len = _M_check_len(__n, "vector::_M_range_insert");
                    pointer __new_start = _Base._M_allocate(__len);
                    pointer __new_finish = __new_start;
                    try
                    {
                        moveEmplaceSliceIfNothrow(_Base._M_impl._M_start[0 .. __offset],
                                __new_start[0 .. __offset]);
                        __new_finish = __new_start + __offset;
                        emplaceSlice(__array, __new_finish[0 .. __n]);

                        __new_finish += __n;

                        const size_type __elems_after = size() - __offset;
                        moveEmplaceSliceIfNothrow(__position[0 .. __elems_after],
                                __new_finish[0 .. __elems_after]);
                        __new_finish += __elems_after;
                    }
                    catch (Throwable e)
                    {
                        destroySlice!false(__new_start[0 .. __new_finish - __new_start]);
                        _Base._M_deallocate(__new_start, __len);
                        throw e;
                    }
                    mixin(_GLIBCXX_ASAN_ANNOTATE_REINIT);
                    destroySlice!false(_Base._M_impl._M_start[0 .. size()]);
                    _Base._M_deallocate(_Base._M_impl._M_start,
                            _Base._M_impl._M_end_of_storage - _Base._M_impl._M_start);
                    _Base._M_impl._M_start = __new_start;
                    _Base._M_impl._M_finish = __new_finish;
                    _Base._M_impl._M_end_of_storage = __new_start + __len;
                }
            }
        }

        // Called by insert(p,n,x), and the range insert when it turns out to be
        // the same thing.
        void _M_fill_insert()(size_type __offset, size_type __n, auto ref value_type __x)
        {
            if (__n != 0)
            {
                if (size_type(_Base._M_impl._M_end_of_storage - _Base._M_impl._M_finish) >= __n)
                {
                    auto __tmp = _Temporary_value(&this, forward!__x);
                    const size_type __elems_after = size() - __offset;
                    pointer __old_finish = _Base._M_impl._M_finish;
                    pointer __position = _Base._M_impl._M_start;
                    if (__elems_after > __n)
                    {
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"__n");
                        moveEmplaceSlice((_Base._M_impl._M_finish - __n)[0 .. __n],
                                _Base._M_impl._M_finish[0 .. __n]);
                        _Base._M_impl._M_finish += __n;
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__n");
                        const __remaining = __old_finish - __position - __n;
                        moveSliceBackward(__position[0 .. __remaining], __old_finish[0 .. __remaining]);
                        __position[0 .. __n] = __tmp._M_val;
                    }
                    else
                    {
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"__n");
                        emplaceFill(_Base._M_impl._M_finish[0 .. __n - __elems_after], __tmp._M_val);
                        _Base._M_impl._M_finish += __n - __elems_after;
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__n - __elems_after");
                        moveEmplaceSlice(__position[0 .. __elems_after],
                                _Base._M_impl._M_finish[0 .. __elems_after]);
                        _Base._M_impl._M_finish += __elems_after;
                        mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__elems_after");
                        __position[0 .. __elems_after] = __tmp._M_val;
                    }
                }
                else
                {
                    const size_type __len = _M_check_len(__n, "vector::_M_fill_insert");
                    const size_type __elems_before = __offset;
                    pointer __new_start = _Base._M_allocate(__len);
                    pointer __new_finish = __new_start;
                    try
                    {
                        // See _M_realloc_insert above.

                        emplaceFill(__new_start[__offset .. __offset + __n], __x);
                        __new_finish = pointer();

                        moveEmplaceSliceIfNothrow(_Base._M_impl._M_start[0 .. __offset],
                                __new_start[0 .. __offset]);
                        __new_finish = __new_start + __offset;

                        __new_finish += __n;

                        const size_type __elems_after = size() - __offset;
                        moveEmplaceSliceIfNothrow(_Base._M_impl._M_start[__offset .. size()],
                                __new_finish[0 .. __elems_after]);
                        __new_finish += __elems_after;
                    }
                    catch (Throwable e)
                    {
                        _Base._M_deallocate(__new_start, __len);
                        if (!__new_finish)
                            destroySlice!false(__new_start[__elems_before .. __elems_before + __n]);
                        else
                            destroySlice!false(__new_start[0 .. __new_finish - __new_start]);
                        _Base._M_deallocate(__new_start, __len);
                        throw e;
                    }
                    mixin(_GLIBCXX_ASAN_ANNOTATE_REINIT);
                    destroySlice!false(_Base._M_impl._M_start[0 .. size()]);
                    _Base._M_deallocate(_Base._M_impl._M_start,
                            _Base._M_impl._M_end_of_storage - _Base._M_impl._M_start);
                    _Base._M_impl._M_start = __new_start;
                    _Base._M_impl._M_finish = __new_finish;
                    _Base._M_impl._M_end_of_storage = __new_start + __len;
                }
            }
        }

        // Called by resize(n).
        void _M_default_append(size_type __n)
        {
            if (__n != 0)
            {
                const size_type __size = size();
                size_type __navail = size_type(
                        _Base._M_impl._M_end_of_storage - _Base._M_impl._M_finish);

                if (__size > max_size() || __navail > max_size() - __size)
                    assert(0); //__builtin_unreachable();

                if (__navail >= __n)
                {
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"__n");
                    foreach (__i; 0 .. __n)
                        emplaceInitializer(_Base._M_impl._M_finish[__i]);
                    _Base._M_impl._M_finish += __n;
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"__n");
                }
                else
                {
                    const size_type __len = _M_check_len(__n, "vector::_M_default_append");
                    pointer __new_start = _Base._M_allocate(__len);
                    pointer __destroy_from = pointer();
                    try
                    {
                        foreach (__i; 0 .. __n)
                            emplaceInitializer(*(__new_start + __size + __i));
                        __destroy_from = __new_start + __size;
                        moveSliceIfNothrow(_Base._M_impl._M_start[0 .. size()],
                                __new_start[0 .. size()]);
                    }
                    catch (Throwable e)
                    {
                        if (__destroy_from)
                            destroySlice(__destroy_from[0 .. __n]);
                        _Base._M_deallocate(__new_start, __len);
                        throw e;
                    }
                    mixin(_GLIBCXX_ASAN_ANNOTATE_REINIT);
                    destroySlice(_Base._M_impl._M_start[0 .. size()]);
                    _Base._M_deallocate(_Base._M_impl._M_start,
                            _Base._M_impl._M_end_of_storage - _Base._M_impl._M_start);
                    _Base._M_impl._M_start = __new_start;
                    _Base._M_impl._M_finish = __new_start + __size + __n;
                    _Base._M_impl._M_end_of_storage = __new_start + __len;
                }
            }
        }

        bool _M_shrink_to_fit()
        {
            if (capacity() == size())
                return false;
            mixin(_GLIBCXX_ASAN_ANNOTATE_REINIT);
            auto tmp = vector(Default);
            enum __move_if_nothrow = true;
            tmp._M_array_initialize!__move_if_nothrow(this.as_array);
            this.swap(tmp);
            return true;
        }

        // Called by insert(p,x)
        void _M_insert_aux()(size_type __offset, auto ref value_type __x)
        {
            pointer __position = _Base._M_impl._M_start + __offset;
            mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"1");
            moveEmplace(*(_Base._M_impl._M_finish - 1), *_Base._M_impl._M_finish);
            ++_Base._M_impl._M_finish;
            mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"1");
            const __elems_after = (_Base._M_impl._M_finish - 2) - __position;
            moveSliceBackward(__position[0 .. __elems_after], __position[1 .. 1 + __elems_after]);
            *__position = forward!__x;
        }

        // reallocate or move existing elements.
        void _M_realloc_insert()(size_type __offset, auto ref value_type __x)
        {
            pointer __position = _Base._M_impl._M_start + __offset;
            const size_type __len = _M_check_len(size_type(1), "vector::_M_realloc_insert");
            pointer __old_start = _Base._M_impl._M_start;
            pointer __old_finish = _Base._M_impl._M_finish;
            const size_type __elems_before = __position - _Base._M_impl._M_start;
            const size_type __elems_after = _Base._M_impl._M_finish - __position;
            pointer __new_start = _Base._M_allocate(__len);
            pointer __new_finish = __new_start;
            try
            {
                // The order of the three operations is dictated by the C++11
                // case, where the moves could alter a new element belonging
                // to the existing vector.  This is an issue only for callers
                // taking the element by lvalue ref (see last bullet of C++11
                // [res.on.arguments]).
                static if (__traits(isRef, __x))
                    core_emplace(__new_start + __elems_before, __x);
                else
                    moveEmplace(__x, *(__new_start + __elems_before));

                __new_finish = pointer();

                moveEmplaceSliceIfNothrow(__old_start[0 .. __offset], __new_start[0 .. __offset]);
                __new_finish = __new_start + __offset;

                ++__new_finish;

                moveEmplaceSliceIfNothrow(__position[0 .. __elems_after],
                        __new_finish[0 .. __elems_after]);
                __new_finish += __elems_after;
            }

            catch (Throwable e)
            {
                if (!__new_finish)
                    destroy!false(*(__new_start + __elems_before));
                else
                    destroySlice!false(__new_start[0 .. __new_finish - __new_start]);
                _Base._M_deallocate(__new_start, __len);
                throw e;
            }

            mixin(_GLIBCXX_ASAN_ANNOTATE_REINIT);
            destroySlice!false(__old_start[0 .. __old_finish - __old_start]);
            _Base._M_deallocate(__old_start, _Base._M_impl._M_end_of_storage - __old_start);
            _Base._M_impl._M_start = __new_start;
            _Base._M_impl._M_finish = __new_finish;
            _Base._M_impl._M_end_of_storage = __new_start + __len;
        }

        // A value_type object constructed with _Alloc_traits::construct()
        // and destroyed with _Alloc_traits::destroy().
        struct _Temporary_value
        {
            this(_Args...)(vector* __vec, auto ref _Args __args)
            {
                _M_this = __vec;
                core_emplace(_M_ptr(), forward!__args);
            }

            ~this()
            {
                destroy!false(*_M_ptr());
            }

            ref value_type _M_val()
            {
                return *cast(value_type*)(&__buf[0]);
            }

        private:
            pointer _M_ptr()
            {
                return &_M_val();
            }

            vector* _M_this;
            align(value_type.alignof) ubyte[value_type.sizeof] __buf;
        }

        // Either move-construct at the end, or forward to _M_insert_aux.
        void _M_insert_rval(size_type __offset, ref value_type __v)
        {
            if (_Base._M_impl._M_finish != _Base._M_impl._M_end_of_storage)
            {
                if (__offset == size())
                {
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"1");
                    moveEmplace(__v, *_Base._M_impl._M_finish);
                    ++_Base._M_impl._M_finish;
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"1");
                }
                else
                    _M_insert_aux(__offset, move(__v));
            }
            else
                _M_realloc_insert(__offset, move(__v));
        }

        // Try to emplace at the end, otherwise forward to _M_insert_aux.
        void _M_emplace_aux(_Args...)(size_type __offset, auto ref _Args __args)
        {
            if (_Base._M_impl._M_finish != _Base._M_impl._M_end_of_storage)
            {
                if (__offset == size())
                {
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GROW!"1");
                    core_emplace(_Base._M_impl._M_finish, forward!__args);
                    ++_Base._M_impl._M_finish;
                    mixin(_GLIBCXX_ASAN_ANNOTATE_GREW!"1");
                }
                else
                {
                    // We need to construct a temporary because something in __args...
                    // could alias one of the elements of the container and so we
                    // need to use it before _M_insert_aux moves elements around.
                    auto __tmp = _Temporary_value(&this, forward!__args);
                    _M_insert_aux(__offset, move(__tmp._M_val()));
                }
            }
            else
            {
                _M_realloc_insert(__offset, forward!__args);
            }
        }

        // Emplacing an rvalue of the correct type can use _M_insert_rval.
        void _M_emplace_aux()(size_type __offset, auto ref value_type __v)
        if (!__traits(isRef, __v))
        {
            return _M_insert_rval(__offset, __v);
        }

        // Called by _M_fill_insert, _M_insert_aux etc.
        size_type _M_check_len(size_type __n, const char* __s) const
        {
//            import core.exception : RangeError;

            assert(max_size() - size() >= __n);
//            if (max_size() - size() < __n)
//                throw new RangeError("Length exceeds `max_size()`"); //__throw_length_error(__N(__s));

            static auto max(size_type a, size_type b)
            {
                return b > a ? b : a;
            }

            const size_type __len = size() + max(size(), __n);
            return (__len < size() || __len > max_size()) ? max_size() : __len;
        }

        // Internal erase functions follow.

        // Called by erase(q1,q2), clear(), resize(), _M_fill_assign,
        // _M_assign_aux.
        void _M_erase_at_end()(pointer __pos)
        {
            if (size_type __n = _Base._M_impl._M_finish - __pos)
            {
                destroySlice!false(__pos[0 .. __n]);
                _Base._M_impl._M_finish = __pos;
                mixin(_GLIBCXX_ASAN_ANNOTATE_SHRINK!"__n");
            }
        }

        void _M_erase(size_type __offset)
        {
            pointer __position = _Base._M_impl._M_start + __offset;
            const __elems_after = _Base._M_impl._M_finish - __position;
            if (__position + 1 != _Base._M_impl._M_finish)
                moveSlice(__position[1 .. __elems_after], __position[0 .. __elems_after - 1]);
            --_Base._M_impl._M_finish;
            destroy!false(*_Base._M_impl._M_finish);
            mixin(_GLIBCXX_ASAN_ANNOTATE_SHRINK!"1");
        }

        void _M_erase(size_type __first, size_type __last)
        {
            if (__first != __last)
            {
                if (__last != size())
                    moveSlice(_Base._M_impl._M_start[__last .. size()],
                            _Base._M_impl._M_start[__first .. __first + (size() - __last)]);
                _M_erase_at_end(_Base._M_impl._M_start + __first + (size() - __last));
            }
        }

    private:
        // Constant-time move assignment when source object's memory can be
        // moved, either because the source's allocator will move too
        // or because the allocators are equal.
        void _M_move_assign(bool __move_storage : true)(ref vector __x)
        {
            vector __tmp = vector(get_allocator());
            _Base._M_impl._M_swap_data(__tmp._Base._M_impl);
            _Base._M_impl._M_swap_data(__x._Base._M_impl);
            _Base._M_impl.__alloc_on_move(__x._Base._M_get_Tp_allocator());
        }

        // Do move assignment when it might not be possible to move source
        // object's memory, resulting in a linear-time operation.
        void _M_move_assign(bool __move_storage : false)(ref vector __x)
        {
            if (__x._Base._M_get_Tp_allocator() == _Base._M_get_Tp_allocator())
                _M_move_assign!true(__x);
            else
            {
                // The rvalue's allocator cannot be moved and is not equal,
                // so we need to individually move each element.
                enum __move_assign = true;
                _M_assign_aux!__move_assign(__x.as_array);
                __x.clear();
            }
        }

        _Up* _M_data_ptr(_Up)(_Up* __ptr) const pure nothrow @nogc @safe    { return __ptr; }

        _Vector_base!(T, Alloc) _Base;

        alias _Alloc_traits = allocator_traits!Alloc;
    }
    else version (CppRuntime_Clang)
    {
        import core.stdcpp.xutility : __split_buffer, _LIBCPP_DEBUG_LEVEL, _LIBCPP_HAS_NO_ASAN;

    public:
        alias __alloc_traits = __base.__alloc_traits;

        ///
        this()(DefaultConstruct) @nogc
        {
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);
        }

        ///
        this()(auto ref allocator_type __a)
        {
            __base = forward!__a;
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);
        }

        ///
        this(size_type __n)
        {
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            if (__n > 0)
            {
                __vallocate(__n);
                __construct_at_end(__n);
            }
        }

        ///
        this()(size_type __n, auto ref allocator_type __a)
        {
            __base = forward!__a;

            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            if (__n > 0)
            {
                __vallocate(__n);
                __construct_at_end(__n);
            }
        }

        ///
        this()(size_type __n, auto ref value_type __x)
        {
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            if (__n > 0)
            {
                __vallocate(__n);
                __construct_at_end(__n, forward!__x);
            }
        }

        ///
        this()(size_type __n, auto ref value_type __x, auto ref allocator_type __a)
        {
            __base = forward!__a;

            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            if (__n > 0)
            {
                __vallocate(__n);
                __construct_at_end(__n, forward!__x);
            }
        }

        ///
        this()(T[] __array)
        {
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            if (__array.length > 0)
            {
                __vallocate(__array.length);
                __construct_at_end(__array);
            }
        }

        ///
        this()(T[] __array, auto ref allocator_type __a)
        {
            __base = forward!__a;

            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            if (__array.length > 0)
            {
                __vallocate(__array.length);
                __construct_at_end(__array);
            }
        }

        ///
        ~this()
        {
            __annotate_delete();
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__erase_c(&this);
        }

        ///
        this(ref vector __x)
        {
            __base = __alloc_traits.select_on_container_copy_construction(__x.__base.__alloc());
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            const size_type __n = __x.size();
            if (__n > 0)
            {
                __vallocate(__n);
                __construct_at_end(__x.as_array());
            }
        }

        ///
        this()(ref vector __x, auto ref allocator_type __a)
        {
            __base = forward!__a;

            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            const size_type __n = __x.size();
            if (__n > 0)
            {
                __vallocate(__n);
                __construct_at_end(__x.as_array());
            }
        }

        ///
        this()(auto ref vector __x) if (!__traits(isRef, __x))
        {
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
            {
                __get_db().__insert_c(&this);
                __get_db().swap(&this, &__x);
            }
            __base.__begin_ = __x.__base.__begin_;
            __base.__end_ = __x.__base.__end_;
            __base.__end_cap() = __x.__base.__end_cap();
            __x.__base.__begin_ = __x.__base.__end_ = __x.__base.__end_cap() = null;
        }

        ///
        this()(auto ref vector __x, auto ref allocator_type __a)
        if (!__traits(isRef, __x))
        {
            __base = forward!__a;

            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__insert_c(&this);

            if (__a == __x.__base.__alloc())
            {
                __base.__begin_ = __x.__base.__begin_;
                __base.__end_ = __x.__base.__end_;
                __base.__end_cap() = __x.__base.__end_cap();
                __x.__base.__begin_ = __x.__base.__end_ = __x.__base.__end_cap() = null;
                static if (_LIBCPP_DEBUG_LEVEL >= 2)
                    __get_db().swap(&this, &__x);
            }
            else
            {
                __move_assign(__x.as_array());
            }
        }

        ///
        ref vector opAssign(ref vector __x)
        {
            if (&this != &__x)
            {
                __base.__copy_assign_alloc(__x.__base);
                assign(__x.as_array());
            }
            return this;
        }

        ///
        ref vector opAssign()(auto ref vector __x) if (!__traits(isRef, __x))
        {
            enum __propagate = __alloc_traits.propagate_on_container_move_assignment;
            __move_assign!__propagate(__x);
            return this;
        }

        ///
        ref vector opAssign(T[] __array)
        {
            assign(__array);
            return this;
        }

        ///
        void assign()(size_type __n, auto ref T __u)
        {
            if (__n <= capacity())
            {
                size_type __s = size();
                __base.__begin_[0 .. min(__n, __s)] = __u;
                if (__n > __s)
                    __construct_at_end(__n - __s, __u);
                else
                    __destruct_at_end(__base.__begin_ + __n);
            }
            else
            {
                __vdeallocate();
                __vallocate(__recommend(cast(size_type) __n));
                __construct_at_end(__n, forward!__u);
            }
            __invalidate_all_iterators();
        }

        ///
        void assign(T[] __array)
        {
            const size_type __new_size = __array.length;
            if (__new_size <= capacity())
            {
                size_type __mid = __array.length;
                bool __growing = false;
                if (__new_size > size())
                {
                    __growing = true;
                    __mid = size();
                }
                __base.__begin_[0 .. __mid] = __array[0 .. __mid];
                pointer __m = __base.__begin_ + __mid;
                if (__growing)
                    __construct_at_end(__array[__mid .. __new_size]);
                else
                    __destruct_at_end(__m);
            }
            else
            {
                __vdeallocate();
                __vallocate(__recommend(__new_size));
                __construct_at_end(__array);
            }
            __invalidate_all_iterators();
        }

        ///
        inout(allocator_type) get_allocator() inout pure nothrow @safe @nogc
        {
            return __base.__alloc();
        }

        ///
        size_type size() inout pure nothrow @safe @nogc
        {
            return cast(size_type)(__base.__end_ - __base.__begin_);
        }

        ///
        size_type capacity() inout pure nothrow @safe @nogc
        {
            return __base.capacity();
        }

        ///
        bool empty() inout pure nothrow @safe @nogc
        {
            return __base.__begin_ == __base.__end_;
        }

        ///
        size_type max_size() inout pure nothrow @safe @nogc
        {
            return cast(size_type) min(__base.__alloc().max_size, difference_type.max);
        }

        ///
        void reserve(size_type __n)
        {
            if (__n > capacity())
            {
                allocator_type* __a = &__base.__alloc();
                auto __v = __split_buffer!(value_type, allocator_type*)(__n, size(), *__a);
                __swap_out_circular_buffer(__v);
            }
        }

        ///
        void shrink_to_fit()
        {
            if (capacity() > size())
            {
                try
                {
                    allocator_type* __a = &__base.__alloc();
                    auto __v = __split_buffer!(value_type, allocator_type*)(size(), size(), *__a);
                    __swap_out_circular_buffer(__v);
                }
                catch (Throwable e)
                {
                }
            }
        }

        ///
        ref inout(T) at(size_type __n) inout pure nothrow @trusted @nogc
        {
            return __base.__begin_[0 .. size()][__n];
        }

        ///
        inout(T)* data() inout pure nothrow @safe @nogc
        {
            return __base.__begin_;
        }

        ///
        inout(T)[] as_array() inout pure nothrow @trusted @nogc
        {
            return __base.__begin_[0 .. size()];
        }

        alias __emplace_back = emplace_back;

        ///
        void push_back()(auto ref T __x)
        {
            if (__base.__end_ != __base.__end_cap())
            {
                auto __annotator = __RAII_IncreaseAnnotator(this);
                static if (__traits(isRef, __x))
                    core_emplace(__base.__end_, __x);
                else
                    moveEmplace(__x, *__base.__end_);
                __annotator.__done();
                ++__base.__end_;
            }
            else
                __push_back_slow_path(forward!__x);
        }

        ///
        void emplace_back(_Args...)(_Args __args)
        {
            if (__base.__end_ < __base.__end_cap())
            {
                auto __annotator = __RAII_IncreaseAnnotator(this);
                core_emplace(__base.__end_, forward!__args);
                __annotator.__done();
                ++__base.__end_;
            }
            else
                __emplace_back_slow_path(forward!__args);
        }

        ///
        void pop_back()
        {
            assert(!empty(), "vector::pop_back called for empty vector");
            __destruct_at_end(__base.__end_ - 1);
        }

        ///
        void insert()(size_type __offset, auto ref T __x)
        {
            //static if (_LIBCPP_DEBUG_LEVEL >= 2)
            //    assert(__get_const_db().__find_c_from_i(&__position) == this,
            //        "vector::insert(iterator, x) called with an iterator not"
            //        " referring to this vector");

            pointer __p = __base.__begin_ + __offset;
            if (__base.__end_ < __base.__end_cap())
            {
                auto __annotator = __RAII_IncreaseAnnotator(this);
                if (__p == __base.__end_)
                {
                    static if (__traits(isRef, __x))
                        core_emplace(__base.__end_, __x);
                    else
                        moveEmplace(__x, *__base.__end_);
                    ++__base.__end_;
                }
                else
                {
                    __move_range(__p, __base.__end_, __p + 1);
                    pointer __xr = &__x;
                    if (__p <= __xr && __xr < __base.__end_)
                        ++__xr;
                    static if (__traits(isRef, __x))
                        *__p = *__xr;
                    else
                        *__p = move(*__xr);
                }
                __annotator.__done();
            }
            else
            {
                allocator_type* __a = &__base.__alloc();
                auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + 1), __p - __base.__begin_, *__a);
                __v.push_back(forward!__x);
                __p = __swap_out_circular_buffer(__v, __p);
            }
        }

        ///
        void emplace(_Args...)(size_type __offset, auto ref _Args __args)
        {
            import core.stdcpp.xutility : __temp_value;

            //static if (_LIBCPP_DEBUG_LEVEL >= 2)
            //    assert(__get_const_db().__find_c_from_i(&__position) == this,
            //        "vector::emplace(iterator, x) called with an iterator not"
            //        " referring to this vector");

            pointer __p = __base.__begin_ + __offset;
            if (__base.__end_ < __base.__end_cap())
            {
                auto __annotator = __RAII_IncreaseAnnotator(this);
                if (__p == __base.__end_)
                {
                    core_emplace(__base.__end_, forward!__args);
                    ++__base.__end_;
                }
                else
                {
                    auto __tmp = __temp_value!(value_type, Alloc)(__base.__alloc(), forward!__args);
                    __move_range(__p, __base.__end_, __p + 1);
                    *__p = move(__tmp.get());
                }
                __annotator.__done();
            }
            else
            {
                allocator_type* __a = &__base.__alloc();
                auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + 1), __p - __base.__begin_, *__a);
                __v.emplace_back(forward!__args);
                __p = __swap_out_circular_buffer(__v, __p);
            }
        }

        ///
        void insert()(size_type __offset, size_type __n, auto ref T __x)
        {
            //static if (_LIBCPP_DEBUG_LEVEL >= 2)
            //    assert(__get_const_db().__find_c_from_i(&__position) == this,
            //        "vector::insert(iterator, n, x) called with an iterator not"
            //        " referring to this vector");

            pointer __p = __base.__begin_ + __offset;
            if (__n > 0)
            {
                if (__n <= cast(size_type)(__base.__end_cap() - __base.__end_))
                {
                    size_type __old_n = __n;
                    pointer __old_last = __base.__end_;
                    if (__n > cast(size_type)(__base.__end_ - __p))
                    {
                        size_type __cx = __n - (__base.__end_ - __p);
                        __construct_at_end(__cx, __x);
                        __n -= __cx;
                    }
                    if (__n > 0)
                    {
                        auto __annotator = __RAII_IncreaseAnnotator(this, __n);
                        __move_range(__p, __old_last, __p + __old_n);
                        __annotator.__done();
                        pointer __xr = &__x;
                        if (__p <= __xr && __xr < __base.__end_)
                            __xr += __old_n;
                        __p[0 .. __n] = *__xr;
                    }
                }
                else
                {
                    allocator_type* __a = &__base.__alloc();
                    auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + __n), __p - __base.__begin_, *__a);
                    __v.__construct_at_end(__n, forward!__x);
                    __p = __swap_out_circular_buffer(__v, __p);
                }
            }
        }

        ///
        void insert(size_type __offset, T[] __array)
        {
            //static if (_LIBCPP_DEBUG_LEVEL >= 2)
            //    assert(__get_const_db().__find_c_from_i(&__position) == this,
            //        "vector::insert(iterator, range) called with an iterator not"
            //        " referring to this vector");

            pointer __p = __base.__begin_ + __offset;
            difference_type __n = __array.length;
            if (__n > 0)
            {
                if (__n <= __base.__end_cap() - __base.__end_)
                {
                    size_type __old_n = __n;
                    pointer __old_last = __base.__end_;
                    size_type __m = __array.length;
                    difference_type __dx = __base.__end_ - __p;
                    if (__n > __dx)
                    {
                        difference_type __diff = __base.__end_ - __p;
                        __m = __diff;
                        __construct_at_end(__array[__m .. __n]);
                        __n = __dx;
                    }
                    if (__n > 0)
                    {
                        auto __annotator = __RAII_IncreaseAnnotator(this, __n);
                        __move_range(__p, __old_last, __p + __old_n);
                        __annotator.__done();
                        __p[0 .. __m] = __array[0 .. __m];
                    }
                }
                else
                {
                    allocator_type* __a = &__base.__alloc();
                    auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + __n), __p - __base.__begin_, *__a);
                    __v.__construct_at_end(__array);
                    __p = __swap_out_circular_buffer(__v, __p);
                }
            }
        }

        ///
        void erase(size_type __offset)
        {
            //static if (_LIBCPP_DEBUG_LEVEL >= 2)
            //    assert(__get_const_db().__find_c_from_i(&__position) == this,
            //        "vector::erase(iterator) called with an iterator not"
            //        " referring to this vector");

            assert(__offset < size(), "vector::erase(offset) called with an out of range offset");
            pointer __p = __base.__begin_ + __offset;
            moveSlice(__base.__begin_[__offset + 1 .. size()], __base.__begin_[__offset .. size() - 1]);
            __destruct_at_end(__base.__end_ - 1);
            __invalidate_iterators_past(__p - 1);
        }

        ///
        void erase(size_type __first, size_type __last)
        {
            //static if (_LIBCPP_DEBUG_LEVEL >= 2)
            //    assert(__get_const_db()->__find_c_from_i(&__first) == this,
            //        "vector::erase(iterator,  iterator) called with an iterator not"
            //        " referring to this vector");
            //    assert(__get_const_db()->__find_c_from_i(&__last) == this,
            //        "vector::erase(iterator,  iterator) called with an iterator not"
            //        " referring to this vector");
            //}
            assert(__first <= __last, "vector::erase(first, last) called with invalid range");
            assert(__last < size(), "vector::erase(first, last) called with an out of range offset");
            const size_type __n = __last - __first;
            pointer __p = __base.__begin_ + __first;
            if (__first != __last)
            {
                moveSlice(__base.__begin_[__last .. size()], __base.__begin_[__first .. size() - __n]);
                __destruct_at_end(__base.__end_ - __n);
                __invalidate_iterators_past(__p - 1);
            }
        }

        ///
        void clear()
        {
            size_type __old_size = size();
            __base.clear();
            __annotate_shrink(__old_size);
            //__invalidate_all_iterators();
        }

        ///
        void resize(size_type __sz)
        {
            size_type __cs = size();
            if (__cs < __sz)
                __append(__sz - __cs);
            else if (__cs > __sz)
                __destruct_at_end(__base.__begin_ + __sz);
        }

        ///
        void resize()(size_type __sz, auto ref T __x)
        {
            size_type __cs = size();
            if (__cs < __sz)
                __append(__sz - __cs, forward!__x);
            else if (__cs > __sz)
                __destruct_at_end(__base.__begin_ + __sz);
        }

        ///
        void swap(ref vector __x)
        {
            import core.stdcpp.allocator : __swap_allocator;
            import core.internal.lifetime : swap;

            assert(__alloc_traits.propagate_on_container_swap || __base.__alloc() == __x.__base.__alloc(),
                    "vector.swap: Either propagate_on_container_swap must be true or the allocators must compare equal");
            swap(__base.__begin_, __x.__base.__begin_);
            swap(__base.__end_, __x.__base.__end_);
            swap(__base.__end_cap(), __x.__base.__end_cap());
            __swap_allocator(__base.__alloc(), __x.__base.__alloc());
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().swap(&this, &__x);
        }

        bool __invariants() const
        {
            if (__base.__begin_ == null)
            {
                if (__base.__end_ != null || __base.__end_cap() != null)
                    return false;
            }
            else
            {
                if (__base.__begin_ > __base.__end_)
                    return false;
                if (__base.__begin_ == __base.__end_cap())
                    return false;
                if (__base.__end_ > __base.__end_cap())
                    return false;
            }
            return true;
        }

    private:
        //static if (_LIBCPP_DEBUG_LEVEL >= 2)
        //{
        //    bool __dereferenceable(const const_iterator* __i) const
        //    bool __decrementable(const const_iterator* __i) const;
        //    bool __addable(const const_iterator* __i, ptrdiff_t __n) const;
        //    bool __subscriptable(const const_iterator* __i, ptrdiff_t __n) const;
        //}  // _LIBCPP_DEBUG_LEVEL >= 2

    private:
        void __invalidate_all_iterators()
        {
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().__invalidate_all(&this);
        }

        void __invalidate_iterators_past(pointer __new_last)
        {
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
            {
                __c_node* __c = __get_db().__find_c_and_lock(&this);
                for (__i_node** __p = __c.end_; __p != __c.beg_; )
                {
                    --__p;
                    const_iterator* __i = cast(const_iterator*)((*__p).__i_);
                    if (__i.base() > __new_last)
                    {
                        (*__p).__c_ = null;
                        if (--__c.end_ != __p)
                            memmove(__p, __p + 1, (__c.end_ - __p) * (__i_node*).sizeof);
                    }
                }
                __get_db().unlock();
            }
            else
                (cast(void) __new_last);
        }

        void __vallocate(size_type __n)
        {
            assert(__n <= max_size());
            //if (__n > max_size())
            //    __throw_length_error();
            __base.__begin_ = __base.__end_ = __base.__alloc().allocate(__n);
            __base.__end_cap() = __base.__begin_ + __n;
            __annotate_new(0);
        }

        void __vdeallocate()
        {
            if (__base.__begin_ != null)
            {
                clear();
                __base.__alloc.deallocate(__base.__begin_, capacity());
                __base.__begin_ = __base.__end_ = __base.__end_cap() = null;
            }
        }

        size_type __recommend(size_type __new_size) const
        {
            const size_type __ms = max_size();
            assert(__new_size <= __ms);
            //if (__new_size > __ms)
            //    __throw_length_error();
            const size_type __cap = capacity();
            if (__cap >= __ms / 2)
                return __ms;

            return cast(size_type) max(2 * __cap, __new_size);
        }

        void __construct_at_end(size_type __n)
        {
            do
            {
                auto __annotator = __RAII_IncreaseAnnotator(this);
                emplaceInitializer(*__base.__end_);
                ++__base.__end_;
                --__n;
                __annotator.__done();
            }
            while (__n > 0);
        }

        void __construct_at_end()(size_type __n, auto ref value_type __x)
        {
            do
            {
                auto __annotator = __RAII_IncreaseAnnotator(this);
                core_emplace(__base.__end_, __x);
                ++__base.__end_;
                --__n;
                __annotator.__done();
            }
            while (__n > 0);
        }

        void __construct_at_end(value_type[] __array)
        {
            auto __annotator = __RAII_IncreaseAnnotator(this, __array.length);
            emplaceSlice(__array, __base.__end_[0 .. __array.length]);
            __base.__end_ += __array.length;
            __annotator.__done();
        }

        void __construct_move_at_end(value_type[] __array)
        {
            auto __annotator = __RAII_IncreaseAnnotator(this, __array.length);
            moveEmplaceSlice(__array, __base.__end_[0 .. __array.length]);
            __base.__end_ += __array.length;
            __annotator.__done();
        }

        void __append(size_type __n)
        {
            if (cast(size_type)(__base.__end_cap() - __base.__end_) >= __n)
                __construct_at_end(__n);
            else
            {
                allocator_type* __a = &__base.__alloc();
                auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + __n), size(), *__a);
                __v.__construct_at_end(__n);
                __swap_out_circular_buffer(__v);
            }
        }

        void __append()(size_type __n, auto ref value_type __x)
        {
            if (cast(size_type)(__base.__end_cap() - __base.__end_) >= __n)
                this.__construct_at_end(__n, forward!__x);
            else
            {
                allocator_type* __a = &__base.__alloc();
                auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + __n), size(), *__a);
                __v.__construct_at_end(__n, forward!__x);
                __swap_out_circular_buffer(__v);
            }
        }

        void __swap_out_circular_buffer(ref __split_buffer!(value_type, allocator_type*) __v)
        {
            import core.internal.lifetime : swap;

            __annotate_delete();
            for (pointer __first = __base.__begin_, __last = __base.__end_; __first != __last; )
                moveEmplaceIfNothrow(*(--__last), *(--__v.__begin_));
            swap(__base.__begin_, __v.__begin_);
            swap(__base.__end_, __v.__end_);
            swap(__base.__end_cap(), __v.__end_cap());
            __v.__first_ = __v.__begin_;
            __annotate_new(size());
            __invalidate_all_iterators();
        }

        pointer __swap_out_circular_buffer(ref __split_buffer!(value_type, allocator_type*) __v, pointer __p)
        {
            import core.internal.lifetime : swap;

            __annotate_delete();
            pointer __r = __v.__begin_;
            for (pointer __first = __base.__begin_, __last = __p; __first != __last; )
                moveEmplaceIfNothrow(*(--__last), *(--__v.__begin_));
            for (pointer __first = __p, __last = __base.__end_; __first != __last; )
                moveEmplaceIfNothrow(*(__first++), *(__v.__end_++));
            swap(__base.__begin_, __v.__begin_);
            swap(__base.__end_, __v.__end_);
            swap(__base.__end_cap(), __v.__end_cap());
            __v.__first_ = __v.__begin_;
            __annotate_new(size());
            __invalidate_all_iterators();
            return __r;
        }

        void __move_range(pointer __from_s, pointer __from_e, pointer __to)
        {
            pointer __old_last = __base.__end_;
            difference_type __n = __old_last - __to;
            for (pointer __i = __from_s + __n; __i < __from_e; ++__i, ++__base.__end_)
                moveEmplace(*__i, *__base.__end_);
            moveSliceBackward(__from_s[0 .. __n], __old_last[0 .. __n]);
        }

        void __move_assign(bool __propagate : true)(ref vector __c)
        {
            __vdeallocate();
            __base.__move_assign_alloc(__c.__base); // this can throw
            __base.__begin_ = __c.__base.__begin_;
            __base.__end_ = __c.__base.__end_;
            __base.__end_cap() = __c.__base.__end_cap();
            __c.__base.__begin_ = __c.__base.__end_ = __c.__base.__end_cap() = null;
            static if (_LIBCPP_DEBUG_LEVEL >= 2)
                __get_db().swap(&this, &__c);
        }

        void __move_assign(bool __propagate : false)(ref vector __c)
        {
            if (__base.__alloc() != __c.__base.__alloc())
                __move_assign(__array);
            else
                __move_assign!true(__c);
        }

        void __move_assign(T[] __array)
        {
            const size_type __new_size = __array.length;
            if (__new_size <= capacity())
            {
                size_type __mid = __array.length;
                bool __growing = false;
                if (__new_size > size())
                {
                    __growing = true;
                    __mid = size();
                }
                moveSlice(__array[0 .. __mid], __base.__begin_[0 .. __mid]);
                pointer __m = __base.__begin_ + __mid;
                if (__growing)
                    __construct_move_at_end(__array[__mid .. __new_size]);
                else
                    __destruct_at_end(__m);
            }
            else
            {
                __vdeallocate();
                __vallocate(__recommend(__new_size));
                __construct_move_at_end(__array);
            }
            __invalidate_all_iterators();
        }

        void __destruct_at_end(pointer __new_last)
        {
            __invalidate_iterators_past(__new_last);
            size_type __old_size = size();
            __base.__destruct_at_end(__new_last);
            __annotate_shrink(__old_size);
        }

        void __push_back_slow_path()(auto ref T __x)
        {
            allocator_type* __a = &__base.__alloc();
            auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + 1), size(), *__a);
            // __v.push_back(forward!__x);
            static if (__traits(isRef, __x))
                core_emplace(__v.__end_, __x);
            else
                moveEmplace(__x, *__v.__end_);
            __v.__end_++;
            __swap_out_circular_buffer(__v);
        }

        void __emplace_back_slow_path(_Args)(auto ref _Args __args)
        {
            allocator_type* __a = &__base.__alloc();
            auto __v = __split_buffer!(value_type, allocator_type*)(__recommend(size() + 1), size(), *__a);
            //    __v.emplace_back(_VSTD::forward<_Args>(__args)...);
            core_emplace(__v.__base.__end_, forward!__args);
            __v.__base.__end_++;
            __swap_out_circular_buffer(__v);
        }

        // The following functions are no-ops outside of AddressSanitizer mode.
        // We call annotatations only for the default Allocator because other allocators
        // may not meet the AddressSanitizer alignment constraints.
        // See the documentation for __sanitizer_annotate_contiguous_container for more details.
        static if (!_LIBCPP_HAS_NO_ASAN)
            void __annotate_contiguous_container(const void* __beg, const void* __end, const void* __old_mid, const void* __new_mid) const
            {
                if (__beg && is(allocator_type : allocator!value_type))
                    __sanitizer_annotate_contiguous_container(__beg, __end, __old_mid, __new_mid);
            }
        else
            void __annotate_contiguous_container(const void*, const void*, const void*, const void*) const {}

        void __annotate_new(size_type __current_size) const
        {
            __annotate_contiguous_container(data(), data() + capacity(),
                    data() + capacity(), data() + __current_size);
        }

        void __annotate_delete() const
        {
            __annotate_contiguous_container(data(), data() + capacity(),
                    data() + size(), data() + capacity());
        }

        void __annotate_increase(size_type __n) const
        {
            __annotate_contiguous_container(data(), data() + capacity(),
                    data() + size(), data() + size() + __n);
        }

        void __annotate_shrink(size_type __old_size) const
        {
            __annotate_contiguous_container(data(), data() + capacity(),
                    data() + __old_size, data() + size());
        }

        static if (!_LIBCPP_HAS_NO_ASAN) // The annotation for size increase should happen before the actual increase,
            // but if an exception is thrown after that the annotation has to be undone.
            struct __RAII_IncreaseAnnotator
            {
                this(const ref vector __v, size_type __n = 1)
                {
                    __commit = false;
                    __v = &__v;
                    __old_size = __v.size() + __n;
                    __v.__annotate_increase(__n);
                }

                void __done() { __commit = true; }

                ~this()
                {
                    if (__commit)
                        return;
                    __v.__annotate_shrink(__old_size);
                }

                bool __commit;
                const(vector)* __v;
                size_type __old_size;
            }
        else
            struct __RAII_IncreaseAnnotator
            {
                this(const ref vector, size_type __n = 1) {}
                void __done() {}
            }

    private:
        __vector_base!(T, Alloc) __base;
    }
    else version (None)
    {
        size_type size() const pure nothrow @safe @nogc                     { return 0; }
        size_type capacity() const pure nothrow @safe @nogc                 { return 0; }
        bool empty() const pure nothrow @safe @nogc                         { return true; }

        inout(T)* data() inout pure nothrow @safe @nogc                     { return null; }
        inout(T)[] as_array() inout pure nothrow @trusted @nogc             { return null; }
        ref inout(T) at(size_type i) inout pure nothrow @trusted @nogc      { data()[0]; }
    }
    else
    {
        static assert(false, "C++ runtime not supported");
    }
}


// platform detail
private:
version (CppRuntime_Microsoft)
{
    import core.stdcpp.xutility : _ITERATOR_DEBUG_LEVEL;

    extern (C++, struct) struct _Vec_base_types(_Ty, _Alloc0)
    {
        alias Ty = _Ty;
        alias Alloc = _Alloc0;
    }

    extern (C++, class) struct _Vector_alloc(_Alloc_types)
    {
        import core.stdcpp.xutility : _Compressed_pair;
    extern(D):
    @nogc:

        alias Ty = _Alloc_types.Ty;
        alias Alloc = _Alloc_types.Alloc;
        alias ValTy = _Vector_val!Ty;

        void _Orphan_all() nothrow @safe
        {
            static if (is(typeof(ValTy._Base)))
                _Mypair._Myval2._Base._Orphan_all();
        }

        static if (_ITERATOR_DEBUG_LEVEL != 0)
        {
            import core.stdcpp.xutility : _Container_proxy;

            alias const_iterator = _Vector_const_iterator!(ValTy);

            ~this()
            {
                _Free_proxy();
            }

            void _Alloc_proxy() @trusted
            {
                import core.lifetime : emplace;

                alias _Alproxy = Alloc.rebind!_Container_proxy;
                _Alproxy _Proxy_allocator = _Alproxy(_Mypair._Myval1);
                _Mypair._Myval2._Base._Myproxy = _Proxy_allocator.allocate(1);
                emplace(_Mypair._Myval2._Base._Myproxy);
                _Mypair._Myval2._Base._Myproxy._Mycont = &_Mypair._Myval2._Base;
            }
            void _Free_proxy()
            {
                alias _Alproxy = Alloc.rebind!_Container_proxy;
                _Alproxy _Proxy_allocator = _Alproxy(_Mypair._Myval1);
                _Orphan_all();
                destroy!false(_Mypair._Myval2._Base._Myproxy);
                _Proxy_allocator.deallocate(_Mypair._Myval2._Base._Myproxy, 1);
                _Mypair._Myval2._Base._Myproxy = null;
            }
        }

        _Compressed_pair!(Alloc, ValTy) _Mypair;
    }

    extern (C++, class) struct _Vector_val(T)
    {
        import core.stdcpp.xutility : _Container_base;
        import core.stdcpp.type_traits : is_empty;

        alias pointer = T*;

        static if (!is_empty!_Container_base.value)
            _Container_base _Base;

        pointer _Myfirst;   // pointer to beginning of array
        pointer _Mylast;    // pointer to current end of sequence
        pointer _Myend;     // pointer to end of array
    }

    static if (_ITERATOR_DEBUG_LEVEL > 0)
    {
        extern (C++, class) struct _Vector_const_iterator(_Myvec)
        {
            import core.stdcpp.xutility : _Iterator_base;
            import core.stdcpp.type_traits : is_empty;

            static if (!is_empty!_Iterator_base.value)
                _Iterator_base _Base;
            _Myvec.pointer _Ptr;
        }
    }
}
version (CppRuntime_Gcc)
{
    import core.stdcpp.xutility : __cplusplus, CppStdRevision;
    import core.lifetime : forward;

    version (_GLIBCXX_SANITIZE_STD_ALLOCATOR) enum _GLIBCXX_SANITIZE_STD_ALLOCATOR = true;
    else                                      enum _GLIBCXX_SANITIZE_STD_ALLOCATOR = false;

    version (_GLIBCXX_SANITIZE_VECTOR) enum _GLIBCXX_SANITIZE_VECTOR = true;
    else                               enum _GLIBCXX_SANITIZE_VECTOR = false;

    extern (C++) struct _Vector_base(_Tp, _Alloc)
    {
        import core.stdcpp.type_traits : is_empty;

        alias _Tp_alloc_type = _Alloc;
        alias pointer = _Tp*;

        extern (C++) struct _Vector_impl
        {
            // to simulate C++ struct inheritance properly,
            // don't make _Alloc a field if has zero fields
            static if (!is_empty!_Tp_alloc_type.value)
                _Tp_alloc_type _Alloc;
            else
                ref _Tp_alloc_type _Alloc() { return *cast(_Tp_alloc_type*)&this; }

            pointer _M_start;
            pointer _M_finish;
            pointer _M_end_of_storage;

            this()(auto ref _Tp_alloc_type __a)
            if (!is_empty!_Tp_alloc_type.value)
            {
                this._Alloc = forward!__a;
            }

            this()(auto ref _Tp_alloc_type __a)
            if (is_empty!_Tp_alloc_type.value)
            {
                static if (is(typeof(this._Alloc = _Tp_alloc_type(forward!a))))
                    this._Alloc = _Tp_alloc_type(forward!__a);
                else {} // _Alloc has no state and no copy/move constructor. Do nothing.
            }

            void _M_swap_data(ref _Vector_impl __x) nothrow
            {
                import core.internal.lifetime : swap;

                swap(_M_start, __x._M_start);
                swap(_M_finish, __x._M_finish);
                swap(_M_end_of_storage, __x._M_end_of_storage);
            }

            void __alloc_on_move()(ref _Tp_alloc_type __a)
            if (!is_empty!_Tp_alloc_type.value)
            {
                static if (allocator_traits!_Tp_alloc_type.propagate_on_container_move_assignment)
                    this._Alloc = move(__a);
            }

            void __alloc_on_move()(ref _Tp_alloc_type __a)
            if (is_empty!_Tp_alloc_type.value)
            {
                static if (allocator_traits!_Tp_alloc_type.propagate_on_container_move_assignment)
                {
                    static if (is(typeof(this._Alloc.opAssign(move(__a)))))
                        this._Alloc.opAssign(move(__a));
                }
            }

            void __alloc_on_swap()(ref _Tp_alloc_type __a)
            if (!is_empty!_Tp_alloc_type.value)
            {
                import core.internal.lifetime : swap;

                static if (allocator_traits!_Tp_alloc_type.propagate_on_container_swap)
                  swap(this._Alloc, __a);
            }

            void __alloc_on_swap()(ref _Tp_alloc_type __a)
            if (is_empty!_Tp_alloc_type.value)
            {
                import core.internal.lifetime : swap;

                static if (allocator_traits!_Tp_alloc_type.propagate_on_container_swap)
                {
                    static if (is(typeof(this._Alloc.opAssign(move(__a)))))
                        swap(this._Alloc, __a);
                }
            }

            static if (_GLIBCXX_SANITIZE_STD_ALLOCATOR && _GLIBCXX_SANITIZE_VECTOR)
            {
                extern (C++) struct _Asan(_AllocT = _Tp_alloc_type)
                if (!is(_AllocT : allocator!U, U))
                {
                    alias size_type = size_t;

                    static void _S_shrink(ref _Vector_impl, size_type) {}

                    static void _S_on_dealloc(ref _Vector_impl) {}

                    extern (C++) struct _Reinit
                    {
                        this(ref _Vector_impl _M_impl) { _M_implp = &_M_impl; }
                        ref _Vector_impl _M_impl() { return *_M_implp; }

                        _Vector_impl* _M_implp;
                        alias _M_impl this;
                    }

                    extern (C++) struct _Grow
                    {
                        this(ref _Vector_impl, size_type) {}
                        void _M_grew(size_type) {}
                    }
                }

                // Enable ASan annotations for memory obtained from std::allocator.
                extern (C++) struct _Asan(_AllocT = _Tp_alloc_type)
                if (is(_AllocT : allocator!U, U))
                {
                    alias size_type = size_t;

                    // Adjust ASan annotation for [_M_start, _M_end_of_storage) to
                    // mark end of valid region as __curr instead of __prev.
                    static void _S_adjust(ref _Vector_impl __impl, pointer __prev, pointer __curr)
                    {
                        __sanitizer_annotate_contiguous_container(__impl._M_start, __impl._M_end_of_storage, __prev, __curr);
                    }

                    static void _S_grow(ref _Vector_impl __impl, size_type __n)
                    {
                        _S_adjust(__impl, __impl._M_finish, __impl._M_finish + __n);
                    }

                    static void _S_shrink(ref _Vector_impl __impl, size_type __n)
                    {
                        _S_adjust(__impl, __impl._M_finish + __n, __impl._M_finish);
                    }

                    static void _S_on_dealloc(ref _Vector_impl __impl)
                    {
                        if (__impl._M_start)
                            _S_adjust(__impl, __impl._M_finish, __impl._M_end_of_storage);
                    }

                    // Used on reallocation to tell ASan unused capacity is invalid.
                    extern (C++) struct _Reinit
                    {
                        this(ref _Vector_impl __impl)
                        {
                            _M_impl = __impl;
                            // Mark unused capacity as valid again before deallocating it.
                            _S_on_dealloc(_M_impl);
                        }

                        ~this()
                        {
                            // Mark unused capacity as invalid after reallocation.
                            if (_M_impl._M_start)
                                _S_adjust(_M_impl, _M_impl._M_end_of_storage, _M_impl._M_finish);
                        }

                        _Vector_impl* _M_implp;
                        ref _Vector_impl _M_impl() { return *_M_implp; }

                        @disable this(this);
                    }

                    // Tell ASan when unused capacity is initialized to be valid.
                    extern (C++) struct _Grow
                    {
                        this(ref _Vector_impl __impl, size_type __n)
                        {
                            _M_impl = __impl;
                            _M_n = __n;
                            _S_grow(_M_impl, __n);
                        }

                        ~this()
                        {
                            if (_M_n)
                                _S_shrink(_M_impl, _M_n);
                        }

                        void _M_grew(size_type __n)
                        {
                            _M_n -= __n;
                        }

                        @disable this(this);

                    private:
                        _Vector_impl* _M_implp;
                        ref _Vector_impl _M_impl() { return *_M_implp; }

                        size_type _M_n;
                    }
                }
            } // (_GLIBCXX_SANITIZE_STD_ALLOCATOR && _GLIBCXX_SANITIZE_VECTOR)
        }

    public:
        alias allocator_type = _Alloc;

        ref inout(_Tp_alloc_type) _M_get_Tp_allocator() inout pure nothrow @trusted @nogc { return *cast(inout _Tp_alloc_type*)(&this._M_impl); }

        inout(allocator_type) get_allocator() inout pure nothrow @safe @nogc              { return _M_get_Tp_allocator(); }

        this()(auto ref allocator_type a)
        if (!is_empty!_Tp_alloc_type.value)
        {
            _M_impl._Alloc = forward!a;
        }

        this()(auto ref allocator_type a)
        if (is_empty!_Tp_alloc_type.value)
        {
            static if (is(typeof(_M_impl._Alloc = _Tp_alloc_type(forward!a))))
                _M_impl._Alloc = _Tp_alloc_type(forward!a);
            else {} // _Alloc has no state and no copy/move constructor. Do nothing.
        }

        this()(size_t __n) { _M_create_storage(__n); }

        this()(size_t n, auto ref allocator_type a)
        {
            _M_impl = forward!a;
            _M_create_storage(n);
        }

        this()(auto ref _Vector_base __x)
        if (!__traits(isRef, __x))
        {
            _M_impl = move(__x._M_get_Tp_allocator());
            _M_impl._M_swap_data(__x._M_impl);
        }

        this()(auto ref _Vector_base __x, auto ref allocator_type __a)
        if (!__traits(isRef, __x))
        {
            _M_impl = forward!__a;
            if (__x.get_allocator() == __a)
                this._M_impl._M_swap_data(__x._M_impl);
            else
            {
                size_t __n = __x._M_impl._M_finish - __x._M_impl._M_start;
                _M_create_storage(__n);
            }
        }

        ~this() { _M_deallocate(_M_impl._M_start, _M_impl._M_end_of_storage - _M_impl._M_start); }

    public:
        _Vector_impl _M_impl;

        pointer _M_allocate(size_t __n)
        {
            return __n != 0 ? _M_impl._Alloc.allocate(__n) : pointer();
        }

        void _M_deallocate(pointer __p, size_t __n)
        {
            if (__p)
                _M_impl._Alloc.deallocate(__p, __n);
        }

    private:
        void _M_create_storage(size_t __n)
        {
            this._M_impl._M_start = this._M_allocate(__n);
            this._M_impl._M_finish = this._M_impl._M_start;
            this._M_impl._M_end_of_storage = this._M_impl._M_start + __n;
        }
    }

    static if (_GLIBCXX_SANITIZE_STD_ALLOCATOR && _GLIBCXX_SANITIZE_VECTOR)
    {
        extern(C) void __sanitizer_annotate_contiguous_container(const void*, const void*, const void*, const void*);

        enum _GLIBCXX_ASAN_ANNOTATE_REINIT = `const __reinit_guard = _Base._Vector_impl._Asan!()._Reinit(_Base._M_impl);`;
        enum _GLIBCXX_ASAN_ANNOTATE_GROW(string n) = `auto __grow_guard = _Base._Vector_impl._Asan!()._Grow(_Base._M_impl, ` ~ n ~ `);`;
        enum _GLIBCXX_ASAN_ANNOTATE_GREW(string n) = `__grow_guard._M_grew(` ~ n ~ `);`;
        enum _GLIBCXX_ASAN_ANNOTATE_SHRINK(string n) = `_Base._Vector_impl._Asan!()._S_shrink(_Base._M_impl, ` ~ n ~ `);`;
        enum _GLIBCXX_ASAN_ANNOTATE_BEFORE_DEALLOC = `_Base._Vector_impl._Asan!()._S_on_dealloc(_Base._M_impl);`;
    }
    else // ! (_GLIBCXX_SANITIZE_STD_ALLOCATOR && _GLIBCXX_SANITIZE_VECTOR)
    {
        enum _GLIBCXX_ASAN_ANNOTATE_REINIT = "";
        enum _GLIBCXX_ASAN_ANNOTATE_GROW(string n) = "";
        enum _GLIBCXX_ASAN_ANNOTATE_GREW(string n) = "";
        enum _GLIBCXX_ASAN_ANNOTATE_SHRINK(string n) = "";
        enum _GLIBCXX_ASAN_ANNOTATE_BEFORE_DEALLOC = "";
    } // (_GLIBCXX_SANITIZE_STD_ALLOCATOR && _GLIBCXX_SANITIZE_VECTOR)
}
version (CppRuntime_Clang)
{
    extern (C++, class) struct __vector_base(T, Allocator)
    {
        import core.stdcpp.xutility : __compressed_pair;

    public:
        alias allocator_type = Allocator;
        alias __alloc_traits = allocator_traits!allocator_type;
        alias size_type = __alloc_traits.size_type;

    protected:
        alias value_type = T;
        alias difference_type = __alloc_traits.difference_type;
        alias pointer = __alloc_traits.pointer;

        pointer __begin_;
        pointer __end_;
        __compressed_pair!(pointer, allocator_type) __end_cap_;

        ref inout(allocator_type) __alloc() inout pure nothrow @nogc @safe
        {
            return __end_cap_.second();
        }

        ref inout(pointer) __end_cap() inout pure nothrow @nogc @safe
        {
            return __end_cap_.first();
        }

        this()(auto ref allocator_type __a)
        {
            import core.lifetime : emplace, moveEmplace;

            static if (__traits(isRef, __a))
                emplace(&__end_cap_.second, __a);
            else
                moveEmplace(__a, __end_cap_.second);
        }

        ~this()
        {
            if (__begin_ != null)
            {
                clear();
                __alloc().deallocate(__begin_, capacity());
            }
        }

        void clear()
        {
            __destruct_at_end(__begin_);
        }

        size_type capacity() const pure nothrow @nogc @safe
        {
            return cast(size_type)(__end_cap() - __begin_);
        }

        void __destruct_at_end(pointer __new_last)
        {
            pointer __soon_to_be_end = __end_;
            while (__new_last != __soon_to_be_end)
                destroy!false(*--__soon_to_be_end);
            __end_ = __new_last;
        }

        void __copy_assign_alloc()(auto ref __vector_base __c)
        {
            static if (__alloc_traits.propagate_on_container_copy_assignment)
            {
                if (__alloc() != __c.__alloc())
                {
                    clear();
                    __alloc().deallocate(__begin_, capacity());
                    __begin_ = __end_ = __end_cap() = null;
                }
                __alloc() = __c.__alloc();
            }
        }

        void __move_assign_alloc()(ref __vector_base __c)
        {
            import core.lifetime : move;
            static if (__alloc_traits.propagate_on_container_move_assignment)
                __alloc() = move(__c.__alloc());
        }
    }
}

// -- Helpers --

extern(D) void emplaceSlice(T)(T[] src, T[] dst)
{
    import core.lifetime : emplace;

    size_t i;
    try
    {
        for (i = 0; i < src.length; ++i)
            emplace(&dst[i], src[i]);
    }
    catch (Throwable e)
    {
        destroySlice!false(dst[0 .. i]);
        throw e;
    }
}

extern(D) void emplaceFill(T, Args...)(T[] dst, auto ref Args args)
{
    import core.lifetime : emplace;

    size_t i;
    try
    {
        for (i = 0; i < dst.length; ++i)
            emplace(&dst[i], args);
    }
    catch (Throwable e)
    {
        destroySlice!false(dst[0 .. i]);
        throw e;
    }
}

extern(D) void moveEmplaceSlice(T)(T[] src, T[] dst)
{
    import core.lifetime : moveEmplace;

    size_t i;
    try
    {
        for (i = 0; i < src.length; ++i)
            moveEmplace(src[i], dst[i]);
    }
    catch (Throwable e)
    {
        destroySlice!false(dst[0 .. i]);
        throw e;
    }
}

extern(D) void moveEmplaceSliceIfNothrow(T)(T[] src, T[] dst)
{
    static if (isMoveEmplaceNothrow!T)
        moveEmplaceSlice(src, dst);
    else
        emplaceSlice(src, dst);
}

void moveEmplaceIfNothrow(T)(ref T src, ref T target)
{
    import core.lifetime : emplace, moveEmplace;

    static if (isMoveEmplaceNothrow!T)
        moveEmplace(src, target);
    else
        emplace(&target, src);
}

enum isMoveEmplaceNothrow(T) = __traits(compiles, () nothrow {
        import core.lifetime : moveEmplace;

        T a = void, b;
        moveEmplace(a, b);
    });

enum isMoveNothrow(T) = __traits(compiles, () nothrow {
        import core.lifetime : move;

        T a, b;
        move(a, b);
    });

extern(D) void moveSlice(T)(T[] src, T[] dst)
{
    import core.lifetime : move;

    foreach (i; 0 .. src.length)
        move(src[i], dst[i]);
}

extern(D) void moveSliceBackward(T)(T[] src, T[] dst)
{
    import core.lifetime : move;

    foreach_reverse (i; 0 .. src.length)
        move(src[i], dst[i]);
}

extern(D) void moveSliceIfNothrow(T)(T[] src, T[] dst)
{
    static if (isMoveNothrow!T)
        moveSlice(src, dst);
    else
        dst[] = src[];
}

extern(D) void destroySlice(bool initialize = true, T : U[], U)(T obj)
{
    foreach_reverse (ref e; obj)
        destroy!initialize(e);
}

T min(T)(T a, T b) { return a < b ? a : b; }
T max(T)(T a, T b) { return a > b ? a : b; }
