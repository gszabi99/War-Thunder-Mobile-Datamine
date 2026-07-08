options gen2
options indenting = 4
options remove_unused_symbols = false


module fio shared

require fio_core public
require strings
require math

typedef file = FILE const?


[generic]
def fopen(name : string; mode : string; blk : block<(f : file) : void>) {
    let f = fopen(name, mode)
    invoke(blk, f)
    if (f != null) {
        fclose(f)
    }
}

[generic]
def dir(path : string; blk : block<(filename : string) : void>) {
    builtin_dir(path, blk)
}

[generic]
def stat(path : string) : FStat {
    var fs : FStat
    if (stat(path, fs)) {
        fs.is_valid = true
    }
    return fs
}

[generic]
def fstat(f : file) : FStat {
    var fs : FStat
    if (fstat(f, fs)) {
        fs.is_valid = true
    }
    return fs
}

[generic]
def fread(f : file; blk : block<(data : string const#)>) {
    var stmp = fread(f)
    unsafe {
        invoke(blk, reinterpret<string#>(stmp))
        delete_string(stmp)
    }
}

let {
    df_magic = 0x12345678
}

struct df_header {
    magic : uint
    size : int
}

[generic]
def fload(file : file; size : int; blk : block<(data : array<uint8>) : void>) : void {
    _builtin_load(file, size, blk)
}

[generic]
def fload(f : file; buf : auto(BufType) -const) {
    var dfh : df_header
    let r1 = _builtin_read(f, dfh, typeinfo sizeof(type<df_header>))
    if (r1 < 0 || dfh.magic != df_magic) return false
    var loaded = false
    _builtin_load(f, dfh.size) $(data : array<uint8>) {
        if (length(data) != 0) {
            binary_load(buf, data)
            loaded = true
        }
    }
    return loaded
}

[generic]
def fsave(f : file; buf : auto(BufType) const) {
    var r1, r2 : int
    binary_save(buf) $(data) {
        let len = length(data)
        let dfh = df_header(magic = df_magic, size = len)
        r1 = _builtin_write(f, dfh, typeinfo sizeof(type<df_header>))
        unsafe {
            r2 = _builtin_write(f, addr(data[0]), len)
        }
    }
    if (r1 < 0) return r1
    if (r2 < 0) return r2
    return (r1 + r2)
}

[generic]
def fread(f : file; buf : auto(BufType) const implicit) {
    concept_assert(typeinfo is_raw(buf), "'fread' accepts only raw POD types")
    unsafe {
        return _builtin_read(f, addr(buf), typeinfo sizeof(buf))
    }
}

[generic]
def fread(f : file; buf : array<auto(BufType)> const implicit) {
    concept_assert(typeinfo is_raw(type<BufType>), "'fread' accepts only raw POD type arrays")
    unsafe {
        return _builtin_read(f, addr(buf[0]), length(buf) * (typeinfo sizeof(type<BufType>)))
    }
}

[generic]
def fwrite(f : file; buf : auto(BufType) const implicit) {
    concept_assert(typeinfo is_raw(buf), "'fwrite' accepts only raw POD types")
    unsafe {
        return _builtin_write(f, addr(buf), typeinfo sizeof(buf))
    }
}

[generic]
def fwrite(f : file; buf : array<auto(BufType)> const implicit) {
    concept_assert(typeinfo is_raw(type<BufType>), "'fwrite' accepts only raw POD type arrays")
    unsafe {
        return _builtin_write(f, addr(buf[0]), length(buf) * (typeinfo sizeof(type<BufType>)))
    }
}

[generic]
def mkdir_rec(path : string) : bool {
    return true if (path == "")
    var st : FStat
    return true if (stat(path, st) && st.is_dir)
    mkdir_rec(dir_name(path))
    return mkdir(path)
}

[generic]
def mkdir_rec(path : string; var error : string&) : bool {
    return true if (path == "")
    var st : FStat
    return true if (stat(path, st) && st.is_dir)
    if (!mkdir_rec(dir_name(path), error)) return false
    return mkdir(path, error)
}


[generic]
def fread(path : string) : string {
    var result : string
    fopen(path, "rb") $(f) {
        if (f != null) {
            result = fread(f)
        }
    }
    return result
}


[generic]
def fwrite(path : string; text : string) : bool {
    var ok = false
    fopen(path, "wb") $(f) {
        if (f != null) {
            fwrite(f, text)
            ok = true
        }
    }
    return ok
}


[generic]
def dir_rec(path : string; blk : block<(filename : string; is_dir : bool) : void>) {
    var error : string
    builtin_dir_rec(path, blk, error)
}

[generic]
def dir_rec(path : string; blk : block<(filename : string; is_dir : bool) : void>; var error : string&) {
    builtin_dir_rec(path, blk, error)
}





def private _match_glob_bytes(p : array<uint8> const#; var pi : int; s : array<uint8> const#; var si : int) : bool {
    let plen = length(p)
    let slen = length(s)
    while (pi < plen) {
        let pc = p[pi]
        if (pc == uint8('*')) {
            let is_double = (pi + 1 < plen && p[pi + 1] == uint8('*'))
            if (is_double) {
                
                
                
                if (pi + 2 < plen && p[pi + 2] == uint8('/')) {
                    if (_match_glob_bytes(p, pi + 3, s, si)) return true
                    var k = si
                    while (k < slen) {
                        if (s[k] == uint8('/') && _match_glob_bytes(p, pi + 3, s, k + 1)) return true
                        k++
                    }
                    return false
                }
                pi += 2
                var k = si
                while (k <= slen) {
                    if (_match_glob_bytes(p, pi, s, k)) return true
                    k++
                }
                return false
            } else {
                pi++
                var k = si
                while (k <= slen) {
                    if (_match_glob_bytes(p, pi, s, k)) return true
                    return false if (k < slen && s[k] == uint8('/'))
                    k++
                }
                return false
            }
        } elif (pc == uint8('?')) {
            return false if (si >= slen || s[si] == uint8('/'))
            pi++
            si++
        } elif (pc == uint8('[')) {
            
            
            var scan = pi + 1
            if (scan < plen && (p[scan] == uint8('!') || p[scan] == uint8('^'))) {
                scan++
            }
            
            
            if (scan < plen && p[scan] == uint8(']')) {
                scan++
            }
            while (scan < plen && p[scan] != uint8(']')) {
                scan++
            }
            if (scan >= plen) {
                
                return false if (si >= slen || s[si] != pc)
                pi++
                si++
            } else {
                return false if (si >= slen)
                let sc = s[si]
                return false if (sc == uint8('/'))
                pi++
                var negate = false
                if (pi < plen && (p[pi] == uint8('!') || p[pi] == uint8('^'))) {
                    negate = true
                    pi++
                }
                var matched = false
                
                
                if (pi < plen && p[pi] == uint8(']')) {
                    if (sc == uint8(']')) {
                        matched = true
                    }
                    pi++
                }
                while (pi < plen && p[pi] != uint8(']')) {
                    if (pi + 2 < plen && p[pi + 1] == uint8('-') && p[pi + 2] != uint8(']')) {
                        let lo = uint(p[pi])
                        let hi = uint(p[pi + 2])
                        let scv = uint(sc)
                        if (scv >= lo && scv <= hi) {
                            matched = true
                        }
                        pi += 3
                    } else {
                        if (sc == p[pi]) {
                            matched = true
                        }
                        pi++
                    }
                }
                if (pi < plen) {
                    pi++
                }
                return false if (matched == negate)
                si++
            }
        } else {
            return false if (si >= slen || s[si] != pc)
            pi++
            si++
        }
    }
    return si == slen
}





def match_glob(pattern : string; path : string) : bool {
    let plen = length(pattern)
    let slen = length(path)
    return true if (plen == 0 && slen == 0)
    return false if (plen == 0)
    
    if (slen == 0) return empty(replace(pattern, "*", ""))
    var result = false
    peek_data(pattern) $(parr) {
        peek_data(path) $(sarr) {
            result = _match_glob_bytes(parr, 0, sarr, 0)
        }
    }
    return result
}







def to_generic_path(s : string) : string {
    return replace(s, "\\", "/")
}





[generic]
def glob(root : string; pattern : string; blk : block<(filename : string; is_dir : bool) : void>) {
    dir_rec(root) $(filename, is_dir) {
        let normalized = to_generic_path(filename)
        if (match_glob(pattern, normalized)) {
            invoke(blk, normalized, is_dir)
        }
    }
}




[generic]
def glob_filtered(root : string; includes : array<string>; excludes : array<string>;
                  blk : block<(filename : string; is_dir : bool) : void>) {
    dir_rec(root) $(filename, is_dir) {
        let normalized = to_generic_path(filename)
        var included = false
        for (pat in includes) {
            if (match_glob(pat, normalized)) {
                included = true
                break
            }
        }
        if (included) {
            for (pat in excludes) {
                if (match_glob(pat, normalized)) {
                    included = false
                    break
                }
            }
        }
        if (included) {
            invoke(blk, normalized, is_dir)
        }
    }
}



def is_glob_pattern(pattern : string) : bool {
    return find(pattern, '*') >= 0 || find(pattern, '?') >= 0 || find(pattern, '[') >= 0
}








def expand_glob(pattern : string; var result : array<string>) {
    let normalized_pattern = to_generic_path(pattern)
    let split = _split_literal_prefix(normalized_pattern)
    let dir_part = split._0
    let file_pattern = split._1
    
    let recursive = (find(file_pattern, "**") >= 0
                     || find(file_pattern, "/") >= 0)
    var matches : array<string>
    if (recursive) {
        glob(dir_part, file_pattern) $(fname, is_dir) {
            if (is_dir) return
            matches |> push(_join_path(dir_part, fname))
        }
    } else {
        
        
        dir(dir_part) $(fname) {
            if (fname == "." || fname == "..") return
            if (match_glob(file_pattern, fname)) {
                let full = _join_path(dir_part, fname)
                let st = stat(full)
                if (st.is_valid && st.is_dir) return
                matches |> push(full)
            }
        }
    }
    sort(matches)
    result |> push_from(matches)
}



def private _join_path(dir_part : string; fname : string) : string {
    if (dir_part == ".") return fname
    if (dir_part |> ends_with("/") || dir_part |> ends_with("\\")) return "{dir_part}{fname}"
    return "{dir_part}/{fname}"
}




def private _split_literal_prefix(pattern : string) : tuple<string; string> {
    var first_meta = find(pattern, '*')
    let qmark = find(pattern, '?')
    if (qmark >= 0 && (first_meta < 0 || qmark < first_meta)) {
        first_meta = qmark
    }
    let lbrack = find(pattern, '[')
    if (lbrack >= 0 && (first_meta < 0 || lbrack < first_meta)) {
        first_meta = lbrack
    }
    let scan_end = first_meta < 0 ? length(pattern) : first_meta
    let prefix = slice(pattern, 0, scan_end)
    let sep_fwd = rfind(prefix, "/")
    let sep_back = rfind(prefix, "\\")
    let sep = max(sep_fwd, sep_back)
    if (sep < 0) return "." => pattern
    let raw_dir = slice(pattern, 0, sep)
    let raw_sep = slice(pattern, sep, sep + 1)
    let remainder = slice(pattern, sep + 1)
    
    
    if (empty(raw_dir)) return raw_sep => remainder
    
    
    if (length(raw_dir) == 2 && raw_dir |> ends_with(":")) return "{raw_dir}{raw_sep}" => remainder
    return raw_dir => remainder
}





def parse_file_list(file : string; var result : array<string>) {
    if (find(file, ",") < 0 && find(file, "\n") < 0) {
        let part = strip(file)
        if (empty(part)) return
        if (is_glob_pattern(part)) {
            expand_glob(part, result)
        } else {
            result |> push(part)
        }
        return
    }
    builtin_string_split_by_char(file, ",\n") $(arr : array<string>#) : void {
        for (raw in arr) {
            let part = strip(raw)
            if (empty(part)) continue
            if (is_glob_pattern(part)) {
                expand_glob(part, result)
            } else {
                result |> push(part)
            }
        }
    }
}


[generic]
def disk_space(path : string) : DiskSpaceInfo {
    var info = DiskSpaceInfo()
    var error : string
    builtin_disk_space(path, info, error)
    return info
}

[generic]
def disk_space(path : string; var error : string&) : DiskSpaceInfo {
    var info = DiskSpaceInfo()
    builtin_disk_space(path, info, error)
    return info
}



variant fs_result_bool {
    value : bool;
    error : string;
}

variant fs_result_int64 {
    value : int64;
    error : string;
}

variant fs_result_string {
    value : string;
    error : string;
}



[generic]
def file_size_result(path : string) : fs_result_int64 {
    var error : string
    let sz = file_size(path, error)
    if (!empty(error)) return fs_result_int64(error = error)
    return fs_result_int64(value = sz)
}

[generic]
def equivalent_result(a : string; b : string) : fs_result_bool {
    var error : string
    let res = equivalent(a, b, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def is_symlink_result(path : string) : fs_result_bool {
    var error : string
    let res = is_symlink(path, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def copy_file_result(src : string; dst : string; overwrite : bool) : fs_result_bool {
    var error : string
    let res = copy_file(src, dst, overwrite, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def set_mtime_result(path : string; time : Time) : fs_result_bool {
    var error : string
    let res = set_mtime(path, time, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def temp_directory_result() : fs_result_string {
    var error : string
    let res = temp_directory(error)
    if (!empty(error)) return fs_result_string(error = error)
    return fs_result_string(value = res)
}

[generic]
def create_temp_file_result(prefix : string; ext : string) : fs_result_string {
    var error : string
    let res = create_temp_file(prefix, ext, error)
    if (!empty(error)) return fs_result_string(error = error)
    return fs_result_string(value = res)
}

[generic]
def create_temp_directory_result(prefix : string) : fs_result_string {
    var error : string
    let res = create_temp_directory(prefix, error)
    if (!empty(error)) return fs_result_string(error = error)
    return fs_result_string(value = res)
}

[generic]
def relative_result(path : string; base : string) : fs_result_string {
    var error : string
    let res = relative(path, base, error)
    if (!empty(error)) return fs_result_string(error = error)
    return fs_result_string(value = res)
}

[generic]
def remove_result(path : string) : fs_result_bool {
    var error : string
    let res = remove(path, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def rename_result(old_name : string; new_name : string) : fs_result_bool {
    var error : string
    let res = rename(old_name, new_name, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def mkdir_result(path : string) : fs_result_bool {
    var error : string
    let res = mkdir(path, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def rmdir_result(path : string) : fs_result_bool {
    var error : string
    let res = rmdir(path, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

[generic]
def rmdir_rec_result(path : string) : fs_result_bool {
    var error : string
    let res = rmdir_rec(path, error)
    if (!empty(error)) return fs_result_bool(error = error)
    return fs_result_bool(value = res)
}

def run_and_capture(args : array<string>; var output : string&; timeout_sec : float = 0.0) : int {
    
    
    
    
    
    
    
    
    
    
    
    
    var captured : string
    let exit_code = unsafe(popen_argv(args, timeout_sec, $(f) {
        if (f != null) {
            captured := unsafe(fread_to_eof(f))
        }
    }))
    output := captured
    return exit_code
}
