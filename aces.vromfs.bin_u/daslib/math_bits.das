options gen2
options no_unused_block_arguments = false
options no_unused_function_arguments = false
options indenting = 4
options strict_smart_pointers = true

module math_bits shared private




def public int_bits_to_float(x : int) {
    
    unsafe {
        return reinterpret<float> x
    }
}

def public int64_bits_to_double(x : int64) {
    
    unsafe {
        return reinterpret<double> x
    }
}

def public int_bits_to_float(x : int2) {
    unsafe {
        return reinterpret<float2> x
    }
}

def public int_bits_to_float(x : int3) {
    unsafe {
        return reinterpret<float3> x
    }
}

def public int_bits_to_float(x : int4) {
    unsafe {
        return reinterpret<float4> x
    }
}

def public uint_bits_to_float(x : uint) {
    
    unsafe {
        return reinterpret<float> x
    }
}

def public uint64_bits_to_double(x : uint64) {
    
    unsafe {
        return reinterpret<double> x
    }
}

def public uint_bits_to_float(x : uint2) {
    unsafe {
        return reinterpret<float2> x
    }
}

def public uint_bits_to_float(x : uint3) {
    unsafe {
        return reinterpret<float3> x
    }
}

def public uint_bits_to_float(x : uint4) {
    unsafe {
        return reinterpret<float4> x
    }
}

def public float_bits_to_int(x : float) {
    
    unsafe {
        return reinterpret<int> x
    }
}

def public double_bits_to_int64(x : double) {
    
    unsafe {
        return reinterpret<int64> x
    }
}

def public float_bits_to_int(x : float2) {
    unsafe {
        return reinterpret<int2> x
    }
}

def public float_bits_to_int(x : float3) {
    unsafe {
        return reinterpret<int3> x
    }
}

def public float_bits_to_int(x : float4) {
    unsafe {
        return reinterpret<int4> x
    }
}

def public float_bits_to_uint(x : float) {
    
    unsafe {
        return reinterpret<uint> x
    }
}

def public double_bits_to_uint64(x : double) {
    
    unsafe {
        return reinterpret<uint64> x
    }
}

def public float_bits_to_uint(x : float2) {
    unsafe {
        return reinterpret<uint2> x
    }
}

def public float_bits_to_uint(x : float3) {
    unsafe {
        return reinterpret<uint3> x
    }
}

def public float_bits_to_uint(x : float4) {
    unsafe {
        return reinterpret<uint4> x
    }
}

variant Vec4f {
    
    data : float4
    i64  : int64
    i32  : int
    i16  : int16
    i8   : int8
    str  : string
    ptr  : void?
    b    : bool
}

def public cast_to_vec4f(x : bool) {
    
    var v : Vec4f
    unsafe {
        v.b = x
        return v.data
    }
}

def public cast_to_vec4f(x : int64) {
    
    var v : Vec4f
    unsafe {
        v.i64 = x
        return v.data
    }
}

def public cast_to_int64(data : float4) {
    
    var v : Vec4f
    unsafe {
        v.data  = data
        return v.i64
    }
}

def public cast_to_int32(data : float4) {
    
    var v : Vec4f
    unsafe {
        v.data  = data
        return v.i32
    }
}

def public cast_to_int16(data : float4) {
    
    var v : Vec4f
    unsafe {
        v.data  = data
        return v.i16
    }
}

def public cast_to_int8(data : float4) {
    
    var v : Vec4f
    unsafe {
        v.data  = data
        return v.i8
    }
}

def public cast_to_string(data : float4) {
    
    var v : Vec4f
    unsafe {
        v.data  = data
        return v.str
    }
}

def public cast_to_pointer(data : float4) {
    
    var v : Vec4f
    unsafe {
        v.data  = data
        return v.ptr
    }
}
