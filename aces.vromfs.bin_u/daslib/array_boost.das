options gen2
options indenting = 4

options strict_smart_pointers

module array_boost shared public







require daslib/templates
require daslib/contracts

[unsafe_operation, template(a), unused_argument(a)]
def private array_helper(var arr : auto implicit ==const; a : auto(TT)) : array<TT -const -#> {
    
    var res : array<TT -const -#>
    static_if (typeinfo is_array(arr)) {
        let lenA = _::long_length(arr)
        if (lenA >= 1_l) {
            unsafe {
                _builtin_make_temp_array_i64(res, addr(arr[0]), lenA)
            }
        }
    } else {
        let lenA = _::length(arr)
        if (lenA >= 1) {
            unsafe {
                _builtin_make_temp_array(res, addr(arr[0]), lenA)
            }
        }
    }
    return <- res
}

[unsafe_operation, template(a), unused_argument(a)]
def private array_helper(arr : auto implicit ==const; a : auto(TT)) : array<TT -const -#> {
    
    var res : array<TT -const -#>
    static_if (typeinfo is_array(arr)) {
        let lenA = _::long_length(arr)
        if (lenA >= 1_l) {
            unsafe {
                _builtin_make_temp_array_i64(res, addr(arr[0]), lenA)
            }
        }
    } else {
        let lenA = _::length(arr)
        if (lenA >= 1) {
            unsafe {
                _builtin_make_temp_array(res, addr(arr[0]), lenA)
            }
        }
    }
    return <- res
}

[unsafe_operation]
def public temp_array(var arr : auto implicit ==const) {
    
    
    
    
    
    
    unsafe {
        return <- array_helper(arr, decltype(arr[0]))
    }
}

[unsafe_operation]
def public temp_array(arr : auto implicit ==const) {
    
    
    
    
    
    
    unsafe {
        return <- array_helper(arr, decltype(arr[0]))
    }
}

[expect_any_array(v)]
def empty(v : auto(VecT)) {
    
    return _::length(v) == 0
}

[unsafe_operation, template(a), unused_argument(a)]
def public temp_array(var data : auto? ==const; lenA : int | int64; a : auto(TT)) : array<TT -const -#> {
    
    
    
    
    
    
    var res : array<TT -const -#>
    static_if (typeinfo is_int(lenA)) {
        if (lenA >= 1) {
            unsafe(_builtin_make_temp_array(res, data, lenA))
        }
    } else {
        if (lenA >= 1_l) {
            unsafe(_builtin_make_temp_array_i64(res, data, lenA))
        }
    }
    return <- res
}

[unsafe_operation, template(a), unused_argument(a)]
def public temp_array(data : auto? ==const; lenA : int | int64; a : auto(TT)) : array<TT -const -#> const {
    
    
    
    
    
    
    var res : array<TT -const -#>
    static_if (typeinfo is_int(lenA)) {
        if (lenA >= 1) {
            unsafe(_builtin_make_temp_array(res, data, lenA))
        }
    } else {
        if (lenA >= 1_l) {
            unsafe(_builtin_make_temp_array_i64(res, data, lenA))
        }
    }
    return <- res
}

def array_view(bytes : array<auto(TT)> ==const; offset, length : int | int64; blk : block<(view : array<TT>#) : void>) {
    
    unsafe {
        static_if (typeinfo is_int(offset)) {
            
            if (offset < 0 || length < 0 || uint(offset) + uint(length) > uint(_::length(bytes))) {
                panic("array_view: out of range")
            }
            __builtin_array_lock_mutable(bytes)
            var res : array<TT>#
            _builtin_make_temp_array(res, addr(bytes[offset]), length)
            invoke(blk, res)
            __builtin_array_unlock_mutable(bytes)
        } else {
            if (offset < 0_l || length < 0_l || uint64(offset) + uint64(length) > uint64(_::long_length(bytes))) {
                panic("array_view: out of range")
            }
            __builtin_array_lock_mutable(bytes)
            var res : array<TT>#
            _builtin_make_temp_array_i64(res, addr(bytes[offset]), length)
            invoke(blk, res)
            __builtin_array_unlock_mutable(bytes)
        }
    }
}

def array_view(var bytes : array<auto(TT)> ==const; offset, length : int | int64; blk : block<(var view : array<TT>#) : void>) {
    
    unsafe {
        static_if (typeinfo is_int(offset)) {
            if (offset < 0 || length < 0 || uint(offset) + uint(length) > uint(_::length(bytes))) {
                panic("array_view: out of range")
            }
            __builtin_array_lock(bytes)
            var res : array<TT>#
            _builtin_make_temp_array(res, addr(bytes[offset]), length)
            invoke(blk, res)
            __builtin_array_unlock(bytes)
        } else {
            if (offset < 0_l || length < 0_l || uint64(offset) + uint64(length) > uint64(_::long_length(bytes))) {
                panic("array_view: out of range")
            }
            __builtin_array_lock(bytes)
            var res : array<TT>#
            _builtin_make_temp_array_i64(res, addr(bytes[offset]), length)
            invoke(blk, res)
            __builtin_array_unlock(bytes)
        }
    }
}