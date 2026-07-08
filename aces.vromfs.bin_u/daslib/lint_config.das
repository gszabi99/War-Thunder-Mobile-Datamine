options gen2
options indenting = 4
options no_global_variables = false

module lint_config shared private




















require daslib/json
require daslib/toml
require daslib/ast_boost






def private resolved_config_path() : string {
    return "{get_das_root()}/.lint_config"
}




def public load_lint_config(var disabled_codes : table<string>) : void {
    load_lint_config_from_path(resolved_config_path(), disabled_codes)
}




def public load_lint_config_from_path(path : string; var disabled_codes : table<string>) : void {
    let body = ""
    if (empty(body)) return
    var error : string
    var root : JsonValue? = read_toml(body, error)
    
    if (root == null || !(root.value is _object)) return
    var root_obj & = unsafe(root.value as _object)   
    if (!key_exists(root_obj, "rules")) return
    var rules_obj : JsonValue? = root_obj["rules"]
    if (rules_obj == null || !(rules_obj.value is _object)) return
    var rules & = unsafe(rules_obj.value as _object)   
    for (code, val_jv in keys(rules), values(rules)) {
        if (val_jv == null || !(val_jv.value is _bool)) continue
        let enabled = val_jv.value as _bool
        if (enabled) {
            
            if (key_exists(disabled_codes, code)) {
                disabled_codes |> erase(code)
            }
        } else {
            
            if (!key_exists(disabled_codes, code)) {
                disabled_codes |> insert(code)
            }
        }
    }
}






def public seed_default_disabled(var disabled_codes : table<string>) : void {
    if (!key_exists(disabled_codes, "STYLE005")) {
        disabled_codes |> insert("STYLE005")
    }
}






var private _cache_off : table<string>
var private _cache_on  : table<string>
var private _cache_loaded = false

def private ensure_cache_loaded() : void {
    if (_cache_loaded) return
    _cache_loaded = true
    let body = ""
    if (empty(body)) return
    var error : string
    var root : JsonValue? = read_toml(body, error)
    if (root == null || !(root.value is _object)) return
    var root_obj & = unsafe(root.value as _object)   
    if (!key_exists(root_obj, "rules")) return
    var rules_obj : JsonValue? = root_obj["rules"]
    if (rules_obj == null || !(rules_obj.value is _object)) return
    var rules & = unsafe(rules_obj.value as _object)   
    for (code, val_jv in keys(rules), values(rules)) {
        if (val_jv == null || !(val_jv.value is _bool)) continue
        let enabled = val_jv.value as _bool
        if (enabled) {
            if (!key_exists(_cache_on, code)) _cache_on |> insert(code)
        } else {
            if (!key_exists(_cache_off, code)) _cache_off |> insert(code)
        }
    }
}








def public build_lint_macro_disabled(prog : ProgramPtr) : table<string> {
    let force_default_off = prog._options |> find_arg("_enable_default_off_rules") ?as tBool ?? false
    var disabled : table<string>
    if (!force_default_off) {
        seed_default_disabled(disabled)
    }
    ensure_cache_loaded()
    for (code in keys(_cache_off)) {
        if (!key_exists(disabled, code)) disabled |> insert(code)
    }
    for (code in keys(_cache_on)) {
        if (key_exists(disabled, code)) disabled |> erase(code)
    }
    return <- disabled
}
