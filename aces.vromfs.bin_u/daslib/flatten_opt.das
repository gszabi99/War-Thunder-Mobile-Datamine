options gen2
options indenting = 4
options strict_smart_pointers = true
options _comment_hygiene = true

module flatten_opt shared private








require daslib/ast
require daslib/ast_boost
require daslib/ast_match
require daslib/templates_boost
require daslib/macro_boost
require daslib/match
require daslib/rtti
require strings

def private is_flat_temp(name : das_string) : bool {
    return name |> starts_with("__flat_")
}





class private FlatScan : AstVisitor {
    reads : table<uint64>
    risky : bool
    def override preVisitExprVar(expr : ExprVar?) : void {
        if (is_flat_temp(expr.name)) reads |> insert(hash(expr.name))
    }
    def override preVisitExprCall(expr : ExprCall?) : void {
        risky = true
    }
    def override preVisitExprAt(expr : ExprAt?) : void {
        risky = true
    }
    def override preVisitExprOp2(expr : ExprOp2?) : void {
        if (expr.op == "/" || expr.op == "%") {
            risky = true
        }
    }
}



def private scan_flat(var e : ExpressionPtr; var reads : table<uint64>; var risky : bool&) {
    if (e == null) return
    var v = new FlatScan()
    make_visitor(*v) $(adapter) {
        visit(e, adapter)
    }
    for (nm in keys(v.reads)) {
        reads |> insert(nm)
    }
    if (v.risky) {
        risky = true
    }
    unsafe {
        delete v
    }
}





def private const_bool(e : ExpressionPtr; var val : bool&) : bool {
    if (e == null) return false
    if (e is ExprConstBool) {
        val = (e as ExprConstBool).value
        return true
    }
    return false
}

def private fold_const(e : ExpressionPtr; constmap : table<uint64; bool>) : ExpressionPtr {
    if (e == null) return null
    if (e is ExprVar) {
        let h = hash((e as ExprVar).name)
        if (key_exists(constmap, h)) return new ExprConstBool(at = e.at, value = constmap?[h] ?? false)
        return clone_expression(e)
    }
    if (e is ExprOp1) {
        let o = e as ExprOp1
        var sub = fold_const(o.subexpr, constmap)
        var bv = false
        if (o.op == "!" && const_bool(sub, bv)) {
            return new ExprConstBool(at = e.at, value = !bv)
        }
        return new ExprOp1(at = e.at, atEnclosure = o.atEnclosure, genFlags = o.genFlags,
            op := o.op, subexpr = sub)
    }
    if (e is ExprOp2) {
        let o = e as ExprOp2
        var l = fold_const(o.left, constmap)
        var r = fold_const(o.right, constmap)
        var lb = false
        var rb = false
        let lc = const_bool(l, lb)
        let rc = const_bool(r, rb)
        if (o.op == "&&") {
            if (lc) {
                return r if (lb)
                return new ExprConstBool(at = e.at, value = false)
            }
            if (rc) {
                return l if (rb)
                return new ExprConstBool(at = e.at, value = false)
            }
        } elif (o.op == "||") {
            if (lc) {
                return new ExprConstBool(at = e.at, value = true) if (lb)
                return r
            }
            if (rc) {
                return new ExprConstBool(at = e.at, value = true) if (rb)
                return l
            }
        }
        return new ExprOp2(at = e.at, atEnclosure = o.atEnclosure, genFlags = o.genFlags,
            op := o.op, left = l, right = r)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        var c = fold_const(o.subexpr, constmap)
        var cb = false
        if (const_bool(c, cb)) {
            return cb ? fold_const(o.left, constmap) : fold_const(o.right, constmap)
        }
        return new ExprOp3(at = e.at, atEnclosure = o.atEnclosure, genFlags = o.genFlags,
            op := o.op, subexpr = c,
            left = fold_const(o.left, constmap),
            right = fold_const(o.right, constmap))
    }
    if (e is ExprCall) {
        let o = e as ExprCall
        var n = new ExprCall(at = e.at, atEnclosure = o.atEnclosure, genFlags = o.genFlags, name := o.name)
        for (ai in range(length(o.arguments))) {
            emplace_new(n.arguments) <| fold_const(o.arguments[ai], constmap)
        }
        return n
    }
    return clone_expression(e)
}




def private fold_stmt(var s : ExpressionPtr; constmap : table<uint64; bool>) : ExpressionPtr {
    if (s is ExprCopy) {
        var cp = s as ExprCopy
        cp.right = fold_const(cp.right, constmap)
        return s
    } elif (s is ExprLet) {
        var lc = s as ExprLet
        for (v in lc.variables) {
            if (v.init != null) {
                v.init = fold_const(v.init, constmap)
            }
        }
        return s
    } elif (s is ExprReturn) {
        var r = s as ExprReturn
        if (r.subexpr != null) {
            r.subexpr = fold_const(r.subexpr, constmap)
        }
        return s
    }
    return fold_const(s, constmap)
}





class private FlatVarRef : AstVisitor {
    name  : string
    count : int
    def override preVisitExprVar(expr : ExprVar?) : void {
        
        
        
        if (expr.name == name) count ++
    }
}

def private count_refs(var e : ExpressionPtr; name : string) : int {
    if (e == null) return 0
    var v = new FlatVarRef(name = name, count = 0)
    make_visitor(*v) $(adapter) {
        visit(e, adapter)
    }
    let c = v.count
    unsafe {
        delete v
    }
    return c
}

class private FlatScanAll : AstVisitor {
    reads : table<uint64>
    risky : bool
    def override preVisitExprVar(expr : ExprVar?) : void {
        reads |> insert(hash(expr.name))
    }
    def override preVisitExprCall(expr : ExprCall?) : void {
        risky = true
    }
    def override preVisitExprAt(expr : ExprAt?) : void {
        risky = true
    }
    def override preVisitExprOp2(expr : ExprOp2?) : void {
        if (expr.op == "/" || expr.op == "%") {
            risky = true
        }
    }
}



def private scan_src(var e : ExpressionPtr; var reads : table<uint64>; var risky : bool&) {
    if (e == null) return
    var v = new FlatScanAll()
    make_visitor(*v) $(adapter) {
        visit(e, adapter)
    }
    for (nm in keys(v.reads)) {
        reads |> insert(nm)
    }
    if (v.risky) {
        risky = true
    }
    unsafe {
        delete v
    }
}




class private FlatUsesBuilder : AstVisitor {
    nameUses : table<uint64; array<int>>
    nameCount : table<uint64; int>
    seen : table<uint64>
    j : int
    def override preVisitExprVar(expr : ExprVar?) : void {
        let h = hash(expr.name)
        nameCount[h] ++
        if (!key_exists(seen, h)) {
            seen |> insert(h)
            nameUses[h] |> push(j)
        }
    }
}

def public copy_prop_pass(var out : array<ExpressionPtr>) {
    
    
    
    var emptyConstMap : table<uint64; bool>
    var changed = true
    while (changed) {
        changed = false
        let n = length(out)
        
        
        
        var storeIdx : table<uint64; array<int>>
        for (j in range(n)) {
            if (out[j] is ExprCopy && (out[j] as ExprCopy).left is ExprVar) {
                storeIdx[hash(((out[j] as ExprCopy).left as ExprVar).name)] |> push(j)
            }
        }
        var ub = new FlatUsesBuilder()
        make_visitor(*ub) $(adapter) {
            for (j in range(n)) {
                ub.j = j
                clear(ub.seen)
                visit(out[j], adapter)
            }
        }
        var srcReads : table<uint64>
        var useJs : array<int>   
        for (k in range(n)) {
            if (!(out[k] is ExprLet)) continue
            var lc = out[k] as ExprLet
            if (length(lc.variables) != 1 || !is_flat_temp(lc.variables[0].name)) continue
            let hk = hash(lc.variables[0].name)
            let nStores = key_exists(storeIdx, hk) ? length(storeIdx[hk]) : 0
            
            
            
            var src : ExpressionPtr = null
            var si = -1
            if (lc.variables[0].init != null && nStores == 0) {
                src = lc.variables[0].init                    
            } elif (lc.variables[0].init == null && nStores == 1) {
                si = storeIdx[hk][0]
                var cp = out[si] as ExprCopy
                src = cp.right                                
            } else {
                continue                                      
            }
            let defIdx = si >= 0 ? si : k
            clear(srcReads)
            var srcRisky = false
            scan_src(src, srcReads, srcRisky)
            if (key_exists(srcReads, hk)) continue            
            
            
            let refCount = (key_exists(ub.nameCount, hk) ? ub.nameCount[hk] : 0) - (si >= 0 ? 1 : 0)
            var firstRef = n
            var maxUseIdx = -1
            clear(useJs)
            if (key_exists(ub.nameUses, hk)) {
                for (j in ub.nameUses[hk]) {
                    if (j == k || j == si) continue
                    useJs |> push(j)
                    if (j < firstRef) {
                        firstRef = j
                    }
                    if (j > maxUseIdx) {
                        maxUseIdx = j
                    }
                }
            }
            if ((refCount > 0 && firstRef < defIdx) || (srcRisky && refCount > 1)) continue
            
            
            var blocked = false
            for (rn in keys(srcReads)) {
                if (!key_exists(storeIdx, rn)) continue
                for (r in storeIdx[rn]) {
                    if (r > defIdx && r <= maxUseIdx) {
                        blocked = true
                        break
                    }
                }
                if (blocked) break
            }
            if (blocked) continue
            
            let nm = "{lc.variables[0].name}"
            var rules : Template
            rules |> replaceVariable(nm, src)   
            let constSrc = src is ExprConstBool
            for (j in useJs) {
                out[j] = apply_template(rules, out[j].at, out[j], false)   
                if (constSrc) {
                    out[j] = fold_stmt(out[j], emptyConstMap)   
                }
            }
            unsafe { delete rules }
            out <- [for (j in range(n)); out[j]; where j != k && j != si]
            changed = true
            break
        }
        delete srcReads
        delete storeIdx
        delete useJs
        unsafe {
            delete ub
        }
    }
    delete emptyConstMap
}

def public dse_pass(var out : array<ExpressionPtr>) {
    let n = length(out)
    
    
    var storeTargets : table<uint64>
    for (s in out) {
        if (s is ExprCopy && (s as ExprCopy).left is ExprVar) {
            let lv = (s as ExprCopy).left as ExprVar
            if (is_flat_temp(lv.name)) storeTargets |> insert(hash(lv.name))
        }
    }
    var live : table<uint64>
    var dead : table<int>
    var reads : table<uint64>   
    var i = n - 1
    while (i >= 0) {
        var stmt = out[i]
        var handled = false
        clear(reads)
        if (stmt is ExprCopy) {
            var cp = stmt as ExprCopy
            if (cp.left is ExprVar && is_flat_temp((cp.left as ExprVar).name)) {
                handled = true
                let lh = hash((cp.left as ExprVar).name)
                var risky = false
                scan_flat(cp.right, reads, risky)
                if (!key_exists(live, lh) && !risky) {
                    dead |> insert(i)   
                } else {
                    live |> erase(lh)
                    for (nm in keys(reads)) {
                        live |> insert(nm)
                    }
                }
            }
        }
        if (!handled && stmt is ExprLet) {
            var lc = stmt as ExprLet
            if (length(lc.variables) == 1 && is_flat_temp(lc.variables[0].name)) {
                handled = true
                let dh = hash(lc.variables[0].name)
                var risky = false
                scan_flat(lc.variables[0].init, reads, risky)
                if (!key_exists(live, dh) && !key_exists(storeTargets, dh) && !risky) {
                    dead |> insert(i)   
                } else {
                    live |> erase(dh)
                    for (nm in keys(reads)) {
                        live |> insert(nm)
                    }
                }
            }
        }
        if (!handled) {
            
            
            var risky = false
            scan_flat(stmt, reads, risky)
            for (nm in keys(reads)) {
                live |> insert(nm)
            }
        }
        i --
    }
    delete storeTargets
    delete live
    delete reads
    if (empty(dead)) {
        delete dead
        return
    }
    out <- [for (j in range(n)); out[j]; where !key_exists(dead, j)]
    delete dead
}













def private reads_known(var e : ExpressionPtr; known : table<uint64; bool>; var reads : table<uint64>) : bool {
    clear(reads)
    var risky = false
    scan_flat(e, reads, risky)
    for (h in keys(reads)) {
        if (key_exists(known, h)) return true
    }
    return false
}

def public mask_const_prop_pass(var out : array<ExpressionPtr>) {
    var known : table<uint64; bool>   
    var reads : table<uint64>         
    let n = length(out)
    for (i in range(n)) {
        var s = out[i]
        
        if (s is ExprLet && length((s as ExprLet).variables) == 1 && is_flat_temp((s as ExprLet).variables[0].name)) {
            var lc = s as ExprLet
            let h = hash(lc.variables[0].name)
            if (lc.variables[0].init != null) {
                if (!empty(known) && reads_known(lc.variables[0].init, known, reads)) {
                    lc.variables[0].init = fold_const(lc.variables[0].init, known)
                }
                var bv = false
                if (const_bool(lc.variables[0].init, bv)) {
                    known[h] = bv
                } else {
                    known |> erase(h)
                }
            } else {
                known |> erase(h)
            }
            continue
        }
        
        if (s is ExprCopy && (s as ExprCopy).left is ExprVar && is_flat_temp(((s as ExprCopy).left as ExprVar).name)) {
            var cp = s as ExprCopy
            let h = hash((cp.left as ExprVar).name)
            if (!empty(known) && reads_known(cp.right, known, reads)) {
                cp.right = fold_const(cp.right, known)
            }
            var bv = false
            if (const_bool(cp.right, bv)) {
                known[h] = bv
            } else {
                known |> erase(h)
            }
            continue
        }
        
        if (!empty(known) && reads_known(s, known, reads)) {
            out[i] = fold_stmt(s, known)
        }
    }
    delete known
    delete reads
}





def private rename_reads(var e : ExpressionPtr; current : table<string; string>) : ExpressionPtr {
    if (e == null) return null
    var tmpl : Template
    var any = false
    for (orig in keys(current)) {
        let vn = current?[orig] ?? ""
        tmpl |> replaceVariable(orig, qmacro($i(vn)))
        any = true
    }
    if (!any) return e
    var res = apply_template(tmpl, e.at, e, false)
    unsafe { delete tmpl }
    return res
}

def public ssa_rename_pass(var out : array<ExpressionPtr>) {
    
    var declaredInit : table<uint64>
    for (s in out) {
        if (s is ExprLet && length((s as ExprLet).variables) == 1) {
            let v = (s as ExprLet).variables[0]
            if (!is_flat_temp(v.name) && v.init != null) declaredInit |> insert(hash(v.name))
        }
    }
    if (empty(declaredInit)) {
        delete declaredInit
        return
    }
    
    var ssaNames : table<uint64>
    for (s in out) {
        if (s is ExprCopy && (s as ExprCopy).left is ExprVar) {
            let h = hash(((s as ExprCopy).left as ExprVar).name)
            if (key_exists(declaredInit, h)) ssaNames |> insert(h)
        }
    }
    delete declaredInit
    if (empty(ssaNames)) {
        delete ssaNames
        return
    }
    
    
    var current : table<string; string>
    var counter = 0
    var i = 0
    while (i < length(out)) {
        var s = out[i]
        if (s is ExprLet && length((s as ExprLet).variables) == 1 &&
                key_exists(ssaNames, hash((s as ExprLet).variables[0].name))) {
            let orig = "{(s as ExprLet).variables[0].name}"
            let newInit = rename_reads((s as ExprLet).variables[0].init, current)
            counter ++
            let vn = "__ssa_{orig}_{counter}"
            out[i] = qmacro_expr(${ var $i(vn) = $e(newInit); })
            current[orig] = vn
        } elif (s is ExprCopy && (s as ExprCopy).left is ExprVar &&
                key_exists(ssaNames, hash(((s as ExprCopy).left as ExprVar).name))) {
            let orig = "{((s as ExprCopy).left as ExprVar).name}"
            let newRhs = rename_reads((s as ExprCopy).right, current)
            counter ++
            let vn = "__ssa_{orig}_{counter}"
            out[i] = qmacro_expr(${ var $i(vn) = $e(newRhs); })
            current[orig] = vn
        } else {
            out[i] = rename_reads(s, current)
        }
        i ++
    }
    delete ssaNames
    delete current
}




let private DEG_TO_RAD = 0.017453292f
let private RAD_TO_DEG = 57.295776f

class private FoldVisitor : AstVisitor {
    changed : bool
    noFastMath : bool
    expandLerp : bool
    def override visitExprOp2(var that : ExprOp2?) : ExpressionPtr {
        
        
        
        if (is_all_const(that) && eval_to_const_supported(that._type)) {
            var folded = eval_to_const(that)
            if (folded |> is_expr_const()) { changed = true; return folded }
        }
        
        
        
        match (that.op) {
            if ("*") {
                if (is_one_const_op(that.right) && same_base_type(that, that.left)) { changed = true; return that.left }
                if (is_one_const_op(that.left) && same_base_type(that, that.right)) { changed = true; return that.right }
                if (is_neg_one_const_op(that.right) && same_base_type(that, that.left)) { changed = true; return negate(that.left) }
                if (is_neg_one_const_op(that.left) && same_base_type(that, that.right)) { changed = true; return negate(that.right) }
                
                if (is_zero_const_op(that.right) && !has_sideeffects(that.left) && (!noFastMath || !is_float_valued(that))) {
                    var z = zero_const_of(that._type, that.at)
                    if (z != null) { changed = true; return z }
                }
                if (is_zero_const_op(that.left) && !has_sideeffects(that.right) && (!noFastMath || !is_float_valued(that))) {
                    var z = zero_const_of(that._type, that.at)
                    if (z != null) { changed = true; return z }
                }
                
                
                
                if (!noFastMath || !is_float_valued(that)) {
                    if (ctor_lane_kill(that.left, that.right) || ctor_lane_kill(that.right, that.left)) {
                        changed = true
                        return that
                    }
                }
                
                
                var spm = splat_scalar_arg(that.right)
                if (spm != null && is_float_vec(expr_bt(that.left))) {
                    changed = true
                    that.right = spm
                    return that
                }
                spm = splat_scalar_arg(that.left)
                if (spm != null && is_float_vec(expr_bt(that.right))) {
                    changed = true
                    that.left = spm
                    return that
                }
            }
            if ("+") {
                if (is_zero_const_op(that.right)) { changed = true; return that.left }
                if (is_zero_const_op(that.left)) { changed = true; return that.right }
            }
            if ("-") {
                if (is_zero_const_op(that.right)) { changed = true; return that.left }
                if (is_zero_const_op(that.left)) { changed = true; return negate(that.right) }
                
                
                if (describe(that.left) == describe(that.right) && !has_sideeffects(that.left) &&
                        (!noFastMath || !is_float_valued(that))) {
                    var z = zero_const_of(that._type, that.at)
                    if (z != null) { changed = true; return z }
                }
            }
            if ("/") {
                
                
                if (!noFastMath && is_float_valued(that)) {
                    var rec = recip_const(that.right)
                    if (rec != null) {
                        changed = true
                        return new ExprOp2(at = that.at, op := "*", left = that.left, right = rec)
                    }
                }
                
                
                var spd = splat_scalar_arg(that.right)
                if (spd != null && is_float_vec(expr_bt(that.left))) {
                    changed = true
                    that.right = spd
                    return that
                }
                spd = splat_scalar_arg(that.left)
                if (spd != null && is_float_vec(expr_bt(that.right))) {
                    changed = true
                    that.left = spd
                    return that
                }
            }
            if ("&&") {
                
                
                if (is_bool_val(that.left, true)) { changed = true; return that.right }
                if (is_bool_val(that.right, true)) { changed = true; return that.left }
                if (is_bool_val(that.left, false)) { changed = true; return that.left }
                if (is_bool_val(that.right, false) && !has_sideeffects(that.left)) { changed = true; return that.right }
            }
            if ("||") {
                
                if (is_bool_val(that.left, false)) { changed = true; return that.right }
                if (is_bool_val(that.right, false)) { changed = true; return that.left }
                if (is_bool_val(that.left, true)) { changed = true; return that.left }
                if (is_bool_val(that.right, true) && !has_sideeffects(that.left)) { changed = true; return that.right }
            }
        }
        return that
    }
    def override visitExprOp1(var that : ExprOp1?) : ExpressionPtr {
        
        
        
        
        
        if (that.op == "!") {
            if (is_bool_val(that.subexpr, true)) { changed = true; return new ExprConstBool(at = that.at, value = false) }
            if (is_bool_val(that.subexpr, false)) { changed = true; return new ExprConstBool(at = that.at, value = true) }
            var neg = negate_bool(that.subexpr, noFastMath)
            if (neg != null) { changed = true; return neg }
        }
        return that
    }
    def override visitExprOp3(var that : ExprOp3?) : ExpressionPtr {
        
        
        if (that.subexpr is ExprConstBool) {
            changed = true
            return (that.subexpr as ExprConstBool).value ? that.left : that.right
        }
        
        
        if (is_bool_val(that.left, true) && is_bool_val(that.right, false)) {
            changed = true
            return that.subexpr
        }
        if (is_bool_val(that.left, false) && is_bool_val(that.right, true)) {
            changed = true
            return new ExprOp1(at = that.at, op := "!", subexpr = that.subexpr)
        }
        
        
        if (describe(that.left) == describe(that.right) && !has_sideeffects(that.subexpr)) {
            changed = true
            return that.left
        }
        return that
    }
    def override visitExprCall(var that : ExprCall?) : ExpressionPtr {
        
        
        
        if (is_all_const(that)) {
            var folded = eval_to_const(that)
            if (!(folded is ExprCall)) {   
                changed = true
                return folded
            }
        }
        
        
        
        
        
        if (that.func != null && that.func.flags.builtIn && length(that.arguments) == 1
                && is_float_family(expr_bt(that.arguments[0]))) {
            let nm = psh_simple_name("{that.func.name}")
            if (nm == "radians" || nm == "degrees") {
                changed = true
                let k = nm == "radians" ? DEG_TO_RAD : RAD_TO_DEG
                return new ExprOp2(at = that.at, op := "*", left = that.arguments[0],
                    right = new ExprConstFloat(at = that.at, value = k))
            }
        }
        
        
        
        if (that.func != null && length(that.arguments) == 3) {
            let fname = psh_simple_name("{that.func.name}")
            let ta = expr_bt(that.arguments[0])
            let tb = expr_bt(that.arguments[1])
            let tc = expr_bt(that.arguments[2])
            if (fname == "lerp" && lerp_shape(ta, tb, tc)) {
                var aArg = that.arguments[0]
                var bArg = that.arguments[1]
                var tArg = that.arguments[2]
                
                
                if (!noFastMath) {
                    if (is_zero_const_op(tArg) && !has_sideeffects(bArg)) { changed = true; return aArg }
                    if (is_one_const_op(tArg) && !has_sideeffects(aArg)) { changed = true; return bArg }
                    if (describe(aArg) == describe(bArg) && !has_sideeffects(bArg) && !has_sideeffects(tArg)) {
                        changed = true
                        return aArg
                    }
                }
                if (!expandLerp) return that
                changed = true
                var sub = new ExprOp2(at = that.at, op := "-", left = bArg, right = clone_expression(aArg))
                var mul = new ExprOp2(at = that.at, op := "*", left = sub, right = tArg)
                return new ExprOp2(at = that.at, op := "+", left = mul, right = aArg)
            }
            if (fname == "mad" && mad_shape(ta, tb, tc)) {
                changed = true
                var mul = new ExprOp2(at = that.at, op := "*", left = that.arguments[0], right = that.arguments[1])
                return new ExprOp2(at = that.at, op := "+", left = mul, right = that.arguments[2])
            }
        }
        return that
    }
    def override visitExprSwizzle(var that : ExprSwizzle?) : ExpressionPtr {
        var r = swizzle_fold_rewrite(that)
        if (r != null) {
            changed = true
            return r
        }
        return that
    }
}




def private is_zero_const(e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e is ExprConstInt) return (e as ExprConstInt).value == 0
    if (e is ExprConstInt8) return (e as ExprConstInt8).value == int8(0)
    if (e is ExprConstInt16) return (e as ExprConstInt16).value == int16(0)
    if (e is ExprConstInt64) return (e as ExprConstInt64).value == 0l
    if (e is ExprConstUInt) return (e as ExprConstUInt).value == 0u
    if (e is ExprConstUInt8) return (e as ExprConstUInt8).value == uint8(0)
    if (e is ExprConstUInt16) return (e as ExprConstUInt16).value == uint16(0)
    if (e is ExprConstUInt64) return (e as ExprConstUInt64).value == 0ul
    if (e is ExprConstFloat) return (e as ExprConstFloat).value == 0.0f
    if (e is ExprConstDouble) return (e as ExprConstDouble).value == 0.0lf
    if (e is ExprConstBool) return !(e as ExprConstBool).value
    return false
}




def private int_const(e : ExpressionPtr; var v : int64&; var signed : bool&) : bool {
    if (e == null) return false
    if (e is ExprConstInt) { v = int64((e as ExprConstInt).value); signed = true; return true }
    if (e is ExprConstInt8) { v = int64((e as ExprConstInt8).value); signed = true; return true }
    if (e is ExprConstInt16) { v = int64((e as ExprConstInt16).value); signed = true; return true }
    if (e is ExprConstInt64) { v = (e as ExprConstInt64).value; signed = true; return true }
    if (e is ExprConstUInt) { v = int64((e as ExprConstUInt).value); signed = false; return true }
    if (e is ExprConstUInt8) { v = int64((e as ExprConstUInt8).value); signed = false; return true }
    if (e is ExprConstUInt16) { v = int64((e as ExprConstUInt16).value); signed = false; return true }
    if (e is ExprConstUInt64) { v = int64((e as ExprConstUInt64).value); signed = false; return true }
    return false
}

def private is_int_val(e : ExpressionPtr; want : int64) : bool {
    var v = 0l
    var signed = false
    return int_const(e, v, signed) && v == want
}

def private is_int_neg_one(e : ExpressionPtr) : bool {
    
    var v = 0l
    var signed = false
    return int_const(e, v, signed) && signed && v == -1l
}




def private is_real_val(e : ExpressionPtr; want : double) : bool {
    if (e == null) return false
    if (e is ExprConstFloat) return double((e as ExprConstFloat).value) == want
    if (e is ExprConstDouble) return (e as ExprConstDouble).value == want
    return false
}




def private is_real_vec_val(e : ExpressionPtr; want : double) : bool {
    if (e == null) return false
    if (e is ExprConstFloat2) { let v = (e as ExprConstFloat2).getValue; return double(v.x) == want && double(v.y) == want }
    if (e is ExprConstFloat3) { let v = (e as ExprConstFloat3).getValue; return double(v.x) == want && double(v.y) == want && double(v.z) == want }
    if (e is ExprConstFloat4) { let v = (e as ExprConstFloat4).getValue; return double(v.x) == want && double(v.y) == want && double(v.z) == want && double(v.w) == want }
    return false
}



def private is_int_vec_val(e : ExpressionPtr; want : int64) : bool {
    if (e == null) return false
    if (e is ExprConstInt2) { let v = (e as ExprConstInt2).getValue; return int64(v.x) == want && int64(v.y) == want }
    if (e is ExprConstInt3) { let v = (e as ExprConstInt3).getValue; return int64(v.x) == want && int64(v.y) == want && int64(v.z) == want }
    if (e is ExprConstInt4) { let v = (e as ExprConstInt4).getValue; return int64(v.x) == want && int64(v.y) == want && int64(v.z) == want && int64(v.w) == want }
    if (e is ExprConstUInt2) { let v = (e as ExprConstUInt2).getValue; return int64(v.x) == want && int64(v.y) == want }
    if (e is ExprConstUInt3) { let v = (e as ExprConstUInt3).getValue; return int64(v.x) == want && int64(v.y) == want && int64(v.z) == want }
    if (e is ExprConstUInt4) { let v = (e as ExprConstUInt4).getValue; return int64(v.x) == want && int64(v.y) == want && int64(v.z) == want && int64(v.w) == want }
    return false
}




def private is_int_vec_neg_one(e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e is ExprConstInt2) { let v = (e as ExprConstInt2).getValue; return v.x == -1 && v.y == -1 }
    if (e is ExprConstInt3) { let v = (e as ExprConstInt3).getValue; return v.x == -1 && v.y == -1 && v.z == -1 }
    if (e is ExprConstInt4) { let v = (e as ExprConstInt4).getValue; return v.x == -1 && v.y == -1 && v.z == -1 && v.w == -1 }
    return false
}




def private is_zero_const_op(e : ExpressionPtr) : bool {
    return is_int_val(e, 0l) || is_real_val(e, 0.0lf) || is_int_vec_val(e, 0l) || is_real_vec_val(e, 0.0lf)
}

def private is_one_const_op(e : ExpressionPtr) : bool {
    return is_int_val(e, 1l) || is_real_val(e, 1.0lf) || is_int_vec_val(e, 1l) || is_real_vec_val(e, 1.0lf)
}

def private is_neg_one_const_op(e : ExpressionPtr) : bool {
    return is_int_neg_one(e) || is_real_val(e, -1.0lf) || is_int_vec_neg_one(e) || is_real_vec_val(e, -1.0lf)
}



def private is_bool_val(e : ExpressionPtr; want : bool) : bool {
    if (e == null) return false
    if (e is ExprConstBool) return (e as ExprConstBool).value == want
    return false
}




def public is_unfolded_identity_op2(e : ExprOp2?) : bool {
    if (e == null) return false
    if (e.op == "*") {
        return (((is_one_const_op(e.right) || is_neg_one_const_op(e.right)) && same_base_type(e, e.left)) ||
            ((is_one_const_op(e.left) || is_neg_one_const_op(e.left)) && same_base_type(e, e.right)))
    }
    if (e.op == "+" || e.op == "-") {
        return (is_zero_const_op(e.right) || is_zero_const_op(e.left))
    }
    return false
}

def private same_base_type(a, b : ExpressionPtr) : bool {
    if (a == null || b == null || a._type == null || b._type == null) return false
    return a._type.baseType == b._type.baseType
}

def private negate(var e : ExpressionPtr) : ExpressionPtr {
    return new ExprOp1(at = e.at, op := "-", subexpr = e)
}






def private negate_bool(var e : ExpressionPtr; noFastMath : bool) : ExpressionPtr {
    if (e is ExprConstBool) {
        return new ExprConstBool(at = e.at, value = !((e as ExprConstBool).value))
    }
    if (e is ExprOp1 && (e as ExprOp1).op == "!") {
        return (e as ExprOp1).subexpr               
    }
    if (e is ExprOp2) {
        var o = e as ExprOp2
        if (o.op == ">" || o.op == "<" || o.op == ">=" || o.op == "<=" || o.op == "==" || o.op == "!=") {
            
            
            
            
            if (o.func == null || !o.func.flags.builtIn ||
                    ((o.op == ">" || o.op == "<" || o.op == ">=" || o.op == "<=") && noFastMath && is_float_valued(o.left))) {
                return null
            }
            if (o.op == ">") return new ExprOp2(at = e.at, op := "<=", left = o.left, right = o.right)
            if (o.op == "<") return new ExprOp2(at = e.at, op := ">=", left = o.left, right = o.right)
            if (o.op == ">=") return new ExprOp2(at = e.at, op := "<",  left = o.left, right = o.right)
            if (o.op == "<=") return new ExprOp2(at = e.at, op := ">",  left = o.left, right = o.right)
            if (o.op == "==") return new ExprOp2(at = e.at, op := "!=", left = o.left, right = o.right)
            if (o.op == "!=") return new ExprOp2(at = e.at, op := "==", left = o.left, right = o.right)
        }
        if (o.op == "&&" || o.op == "||") {        
            var nl = negate_bool(o.left, noFastMath)
            if (nl == null) return null
            var nr = negate_bool(o.right, noFastMath)
            if (nr == null) return null
            if (o.op == "&&") return new ExprOp2(at = e.at, op := "||", left = nl, right = nr)
            return new ExprOp2(at = e.at, op := "&&", left = nl, right = nr)
        }
    }
    return null
}




def public can_negate_bool(e : ExpressionPtr; noFastMath : bool) : bool {
    if (e is ExprConstBool || (e is ExprOp1 && (e as ExprOp1).op == "!")) return true   
    if (e is ExprOp2) {
        let o = e as ExprOp2
        if (o.op == "==" || o.op == "!=") return o.func != null && o.func.flags.builtIn
        if (o.op == ">" || o.op == "<" || o.op == ">=" || o.op == "<=") {
            return o.func != null && o.func.flags.builtIn && !(noFastMath && is_float_valued(o.left))
        }
        if (o.op == "&&" || o.op == "||") {
            return can_negate_bool(o.left, noFastMath) && can_negate_bool(o.right, noFastMath)
        }
    }
    return false
}




def public zero_const_of(t : TypeDeclPtr; at : LineInfo) : ExpressionPtr {
    if (t == null) return null
    match (t.baseType) {
        if (Type.tInt) { return new ExprConstInt(at = at, value = 0) }
        if (Type.tInt8) { return new ExprConstInt8(at = at, value = int8(0)) }
        if (Type.tInt16) { return new ExprConstInt16(at = at, value = int16(0)) }
        if (Type.tInt64) { return new ExprConstInt64(at = at, value = 0l) }
        if (Type.tUInt) { return new ExprConstUInt(at = at, value = 0u) }
        if (Type.tUInt8) { return new ExprConstUInt8(at = at, value = uint8(0)) }
        if (Type.tUInt16) { return new ExprConstUInt16(at = at, value = uint16(0)) }
        if (Type.tUInt64) { return new ExprConstUInt64(at = at, value = 0ul) }
        if (Type.tFloat) { return new ExprConstFloat(at = at, value = 0.0f) }
        if (Type.tDouble) { return new ExprConstDouble(at = at, value = 0.0lf) }
        if (Type.tFloat2) { return new ExprConstFloat2(at = at, value = float2(0.0)) }
        if (Type.tFloat3) { return new ExprConstFloat3(at = at, value = float3(0.0)) }
        if (Type.tFloat4) { return new ExprConstFloat4(at = at, value = float4(0.0)) }
        if (Type.tInt2) { return new ExprConstInt2(at = at, value = int2(0)) }
        if (Type.tInt3) { return new ExprConstInt3(at = at, value = int3(0)) }
        if (Type.tInt4) { return new ExprConstInt4(at = at, value = int4(0)) }
        if (Type.tUInt2) { return new ExprConstUInt2(at = at, value = uint2(0u)) }
        if (Type.tUInt3) { return new ExprConstUInt3(at = at, value = uint3(0u)) }
        if (Type.tUInt4) { return new ExprConstUInt4(at = at, value = uint4(0u)) }
    }
    return null
}

def private expr_bt(e : ExpressionPtr) : Type {
    return (e == null || e._type == null) ? Type.none : e._type.baseType
}


def private vec_elem_bt(bt : Type) : Type {
    if (bt == Type.tFloat2 || bt == Type.tFloat3 || bt == Type.tFloat4) return Type.tFloat
    if (bt == Type.tInt2 || bt == Type.tInt3 || bt == Type.tInt4) return Type.tInt
    if (bt == Type.tUInt2 || bt == Type.tUInt3 || bt == Type.tUInt4) return Type.tUInt
    return Type.none
}

def private is_float_family(bt : Type) : bool {
    return bt == Type.tFloat || bt == Type.tFloat2 || bt == Type.tFloat3 || bt == Type.tFloat4
}



def private is_float_valued(e : ExpressionPtr) : bool {
    let bt = expr_bt(e)
    return is_float_family(bt) || bt == Type.tDouble
}



def private ctor_dim_by_name(c : ExprCall?) : int {
    if (c == null) return 0
    let nm = psh_simple_name("{c.name}")
    var d = 0
    if (nm == "float2" || nm == "int2" || nm == "uint2") {
        d = 2
    } elif (nm == "float3" || nm == "int3" || nm == "uint3") {
        d = 3
    } elif (nm == "float4" || nm == "int4" || nm == "uint4") {
        d = 4
    }
    return length(c.arguments) == d ? d : 0
}

def private is_float_vec(bt : Type) : bool {
    return bt == Type.tFloat2 || bt == Type.tFloat3 || bt == Type.tFloat4
}


def private splat_scalar_arg(e : ExpressionPtr) : ExpressionPtr {
    if (e == null || !(e is ExprCall)) return null
    var c = e as ExprCall
    let nm = psh_simple_name("{c.name}")
    if ((nm != "float2" && nm != "float3" && nm != "float4") || length(c.arguments) != 1) return null
    return expr_bt(c.arguments[0]) == Type.tFloat ? c.arguments[0] : null
}


def private const_vec_zero_mask(e : ExpressionPtr) : int {
    if (e == null) return 0
    var m = 0
    if (e is ExprConstFloat2) {
        let v = (e as ExprConstFloat2).value
        if (v.x == 0.0) { m |= 1; }; if (v.y == 0.0) { m |= 2; }
    } elif (e is ExprConstFloat3) {
        let v = (e as ExprConstFloat3).value
        if (v.x == 0.0) { m |= 1; }; if (v.y == 0.0) { m |= 2; }; if (v.z == 0.0) { m |= 4; }
    } elif (e is ExprConstFloat4) {
        let v = (e as ExprConstFloat4).value
        if (v.x == 0.0) { m |= 1; }; if (v.y == 0.0) { m |= 2; }; if (v.z == 0.0) { m |= 4; }; if (v.w == 0.0) { m |= 8; }
    } elif (e is ExprConstInt2) {
        let v = (e as ExprConstInt2).value
        if (v.x == 0) { m |= 1; }; if (v.y == 0) { m |= 2; }
    } elif (e is ExprConstInt3) {
        let v = (e as ExprConstInt3).value
        if (v.x == 0) { m |= 1; }; if (v.y == 0) { m |= 2; }; if (v.z == 0) { m |= 4; }
    } elif (e is ExprConstInt4) {
        let v = (e as ExprConstInt4).value
        if (v.x == 0) { m |= 1; }; if (v.y == 0) { m |= 2; }; if (v.z == 0) { m |= 4; }; if (v.w == 0) { m |= 8; }
    } elif (e is ExprConstUInt2) {
        let v = (e as ExprConstUInt2).value
        if (v.x == 0u) { m |= 1; }; if (v.y == 0u) { m |= 2; }
    } elif (e is ExprConstUInt3) {
        let v = (e as ExprConstUInt3).value
        if (v.x == 0u) { m |= 1; }; if (v.y == 0u) { m |= 2; }; if (v.z == 0u) { m |= 4; }
    } elif (e is ExprConstUInt4) {
        let v = (e as ExprConstUInt4).value
        if (v.x == 0u) { m |= 1; }; if (v.y == 0u) { m |= 2; }; if (v.z == 0u) { m |= 4; }; if (v.w == 0u) { m |= 8; }
    }
    return m
}




def private ctor_lane_kill(var ctorE : ExpressionPtr; constE : ExpressionPtr) : bool {
    if (ctorE == null || !(ctorE is ExprCall)) return false
    var c = ctorE as ExprCall
    let d = ctor_dim_by_name(c)
    if (d == 0) return false
    let m = const_vec_zero_mask(constE)
    if (m == 0) return false
    var any = false
    for (i in range(d)) {
        if ((m & (1 << i)) != 0 && !is_zero_const(c.arguments[i])) {
            var z = zero_const_of(c.arguments[i]._type, c.arguments[i].at)
            if (z != null) {
                c.arguments[i] = z
                any = true
            }
        }
    }
    return any
}


def public is_uncollapsed_splat_op2(var e : ExprOp2?) : bool {
    if (e == null || (e.op != "*" && e.op != "/")) return false
    return ((splat_scalar_arg(e.left) != null && is_float_vec(expr_bt(e.right))) ||
        (splat_scalar_arg(e.right) != null && is_float_vec(expr_bt(e.left))))
}

def public is_unkilled_ctor_zero_lane(var e : ExprOp2?; no_fast_math : bool = false) : bool {
    
    if (e == null || e.op != "*" || (no_fast_math && is_float_valued(e))) return false
    var ctorE = e.left
    var constE = e.right
    if (const_vec_zero_mask(constE) == 0) {
        ctorE = e.right
        constE = e.left
    }
    if (!(ctorE is ExprCall)) return false
    var c = ctorE as ExprCall
    let d = ctor_dim_by_name(c)
    if (d == 0) return false
    let m = const_vec_zero_mask(constE)
    if (m == 0) return false
    for (i in range(d)) {
        if ((m & (1 << i)) != 0 && !is_zero_const(c.arguments[i])) return true
    }
    return false
}



def private is_mad_elem(bt : Type) : bool {
    return (is_float_family(bt) || bt == Type.tDouble ||
        bt == Type.tInt || bt == Type.tInt2 || bt == Type.tInt3 || bt == Type.tInt4 ||
        bt == Type.tUInt || bt == Type.tUInt2 || bt == Type.tUInt3 || bt == Type.tUInt4)
}



def private mad_shape(ta, tb, tc : Type) : bool {
    if (ta == tb && tb == tc) return is_mad_elem(ta)
    return ta == tc && tb != Type.none && vec_elem_bt(ta) == tb
}




def private lerp_shape(ta, tb, tt : Type) : bool {
    return ta == tb && is_float_family(ta) && tt == Type.tFloat
}




def public is_all_const(e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e |> is_expr_const()) return true
    if (e is ExprVar) return false
    if (e is ExprOp1) return is_all_const((e as ExprOp1).subexpr)
    if (e is ExprOp2) {
        let o = e as ExprOp2
        return is_all_const(o.left) && is_all_const(o.right)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        return is_all_const(o.subexpr) && is_all_const(o.left) && is_all_const(o.right)
    }
    if (e is ExprCall) {
        let c = e as ExprCall
        
        if (c.func == null || !c.func.flags.builtIn || has_sideeffects(e)) return false
        for (a in c.arguments) {
            if (!is_all_const(a)) return false
        }
        return true
    }
    return false
}




def public eval_to_const_supported(t : TypeDeclPtr) : bool {
    if (t == null) return false
    let bt = t.baseType
    return (bt == Type.tFloat || bt == Type.tFloat2 || bt == Type.tFloat3 || bt == Type.tFloat4 ||
        bt == Type.tInt || bt == Type.tInt2 || bt == Type.tInt3 || bt == Type.tInt4 ||
        bt == Type.tUInt || bt == Type.tUInt2 || bt == Type.tUInt3 || bt == Type.tUInt4)
}




def private fully_inferred(e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e is ExprOp1) {
        return e._type != null && fully_inferred((e as ExprOp1).subexpr)
    }
    if (e is ExprOp2) {
        let o = e as ExprOp2
        return e._type != null && fully_inferred(o.left) && fully_inferred(o.right)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        return e._type != null && fully_inferred(o.subexpr) && fully_inferred(o.left) && fully_inferred(o.right)
    }
    if (e is ExprCall) {
        if (e._type == null) {
            return false
        }
        for (a in (e as ExprCall).arguments) {
            if (!fully_inferred(a)) {
                return false
            }
        }
        return true
    }
    return true
}




def private eval_to_const(var e : ExpressionPtr) : ExpressionPtr {
    if (e == null || e._type == null || !fully_inferred(e)) return e
    var ok = false
    var val : float4
    unsafe {
        val = eval_single_expression(e, ok)
    }
    if (!ok) return e
    let bt = e._type.baseType
    if (bt == Type.tFloat) return new ExprConstFloat(at = e.at, value = val.x)
    if (bt == Type.tFloat2) return new ExprConstFloat2(at = e.at, value = float2(val.x, val.y))
    if (bt == Type.tFloat3) return new ExprConstFloat3(at = e.at, value = float3(val.x, val.y, val.z))
    if (bt == Type.tFloat4) return new ExprConstFloat4(at = e.at, value = val)
    unsafe {
        if (bt == Type.tInt) return new ExprConstInt(at = e.at, value = reinterpret<int>(val.x))
        if (bt == Type.tInt2) return new ExprConstInt2(at = e.at, value = int2(reinterpret<int>(val.x), reinterpret<int>(val.y)))
        if (bt == Type.tInt3) return new ExprConstInt3(at = e.at, value = int3(reinterpret<int>(val.x), reinterpret<int>(val.y), reinterpret<int>(val.z)))
        if (bt == Type.tInt4) return new ExprConstInt4(at = e.at, value = int4(reinterpret<int>(val.x), reinterpret<int>(val.y), reinterpret<int>(val.z), reinterpret<int>(val.w)))
        if (bt == Type.tUInt) return new ExprConstUInt(at = e.at, value = reinterpret<uint>(val.x))
        if (bt == Type.tUInt2) return new ExprConstUInt2(at = e.at, value = uint2(reinterpret<uint>(val.x), reinterpret<uint>(val.y)))
        if (bt == Type.tUInt3) return new ExprConstUInt3(at = e.at, value = uint3(reinterpret<uint>(val.x), reinterpret<uint>(val.y), reinterpret<uint>(val.z)))
        if (bt == Type.tUInt4) return new ExprConstUInt4(at = e.at, value = uint4(reinterpret<uint>(val.x), reinterpret<uint>(val.y), reinterpret<uint>(val.z), reinterpret<uint>(val.w)))
    }
    return e
}





def private reads_any(var e : ExpressionPtr; names : table<string; ExpressionPtr>) : bool {
    for (nm in keys(names)) {
        if (count_refs(e, nm) > 0) return true
    }
    return false
}

def private subst_consts(var e : ExpressionPtr; constmap : table<string; ExpressionPtr>) : ExpressionPtr {
    if (e == null) return null
    var tmpl : Template
    for (nm in keys(constmap)) {
        
        var ex = unsafe(reinterpret<Expression? -const>(constmap?[nm] ?? null))
        tmpl |> replaceVariable(nm, ex)
    }
    var res = apply_template(tmpl, e.at, e, false)
    unsafe { delete tmpl }
    return res
}

def private body_read_count(var blk : ExprBlock?; nm : string) : int {
    var total = 0
    for (j in range(length(blk.list))) {
        total += count_refs(blk.list[j], nm)
    }
    return total
}

def private const_prop_locals(var blk : ExprBlock?) : bool {
    var changed = false
    var constmap : table<string; ExpressionPtr>
    var i = 0
    while (i < length(blk.list)) {
        
        if (!empty(constmap) && reads_any(blk.list[i], constmap)) {
            blk.list[i] = subst_consts(blk.list[i], constmap)
            changed = true
        }
        
        var s = blk.list[i]
        if (s is ExprLet && length((s as ExprLet).variables) == 1) {
            var lc = s as ExprLet
            if (!is_flat_temp(lc.variables[0].name) && lc.variables[0].init != null && is_all_const(lc.variables[0].init)) {
                var oldInit = lc.variables[0].init
                if (oldInit |> is_expr_const()) {
                    
                    constmap["{lc.variables[0].name}"] = oldInit
                    changed = true
                } else {
                    
                    var folded = eval_to_const(oldInit)
                    if (folded |> is_expr_const() && folded != oldInit) {
                        lc.variables[0].init = folded
                        constmap["{lc.variables[0].name}"] = folded
                        changed = true
                    }
                }
            }
        }
        i ++
    }
    
    if (!empty(constmap)) {
        var dead : table<int>
        for (j in range(length(blk.list))) {
            let s = blk.list[j]
            if (s is ExprLet && length((s as ExprLet).variables) == 1) {
                let nm = "{(s as ExprLet).variables[0].name}"
                if (key_exists(constmap, nm) && body_read_count(blk, nm) == 0) {
                    dead |> insert(j)
                }
            }
        }
        if (!empty(dead)) {
            
            var si = length(blk.list) - 1
            while (si >= 0) {
                if (key_exists(dead, si)) {
                    blk.list |> erase(si)
                }
                si --
            }
            changed = true
        }
        delete dead
    }
    return changed
}





struct private ReTerm {
    neg : bool          
    e : ExpressionPtr
}




def private collect_add(var e : ExpressionPtr; neg : bool; var terms : array<ReTerm>) {
    if (e == null) return
    if (e is ExprOp2) {
        var o = e as ExprOp2
        if (o.op == "+" || o.op == "-") {
            collect_add(o.left, neg, terms)
            collect_add(o.right, o.op == "-" ? !neg : neg, terms)
            return
        }
    } elif (e is ExprOp1) {
        var o = e as ExprOp1
        if (o.op == "-") {
            collect_add(o.subexpr, !neg, terms)
            return
        }
    }
    terms |> push(ReTerm(neg = neg, e = e))
}


def private collect_mul(var e : ExpressionPtr; var terms : array<ReTerm>) {
    if (e == null) return
    if (e is ExprOp2) {
        var o = e as ExprOp2
        if (o.op == "*") {
            collect_mul(o.left, terms)
            collect_mul(o.right, terms)
            return
        }
    }
    terms |> push(ReTerm(neg = false, e = e))
}



def private chain_has_const(e : ExpressionPtr; addOp : string) : bool {
    if (e == null) return false
    if (e is ExprOp2) {
        let o = e as ExprOp2
        let isChainOp = addOp == "+" ? (o.op == "+" || o.op == "-") : (o.op == addOp)
        if (isChainOp) {
            return chain_has_const(o.left, addOp) || chain_has_const(o.right, addOp)
        }
    } elif (e is ExprOp1) {
        let o = e as ExprOp1
        if (addOp == "+" && o.op == "-") {
            return chain_has_const(o.subexpr, addOp)
        }
    }
    return is_all_const(e)
}




def private already_grouped(that : ExprOp2?; addOp : string) : bool {
    return that.op == addOp && is_all_const(that.right) && !chain_has_const(that.left, addOp)
}




def private build_chain(var terms : array<ReTerm>; at : LineInfo; addOp, subOp : string) : ExpressionPtr {
    var acc = terms[0].neg ? negate(terms[0].e) : terms[0].e
    for (i in range(1, length(terms))) {
        acc = new ExprOp2(at = at, op := terms[i].neg ? subOp : addOp, left = acc, right = terms[i].e)
    }
    return acc
}




def private vars_sorted(vars : array<ReTerm>) : bool {
    for (i in range(1, length(vars))) {
        if ((vars[i - 1].neg && !vars[i].neg) ||
            (vars[i - 1].neg == vars[i].neg && describe(vars[i].e) < describe(vars[i - 1].e))) {
            return false
        }
    }
    return true
}




def private regroup(that : ExprOp2?; var terms : array<ReTerm>; addOp, subOp : string) : ExpressionPtr {
    var vars : array<ReTerm>
    var consts : array<ReTerm>
    for (t in terms) {
        if (is_all_const(t.e)) {
            consts |> push(t)
        } else {
            vars |> push(t)
        }
    }
    if (empty(vars)) {
        return null
    }
    var pure = true
    for (t in vars) {
        if (has_sideeffects(t.e)) {
            pure = false
            break
        }
    }
    let needs_gather = length(consts) >= 2 && !already_grouped(that, addOp)
    let needs_sort = pure && length(vars) >= 2 && !vars_sorted(vars)
    if (!needs_gather && !needs_sort) {
        return null
    }
    if (pure) {
        sort(vars) $(a, b : ReTerm) : bool {
            if (a.neg != b.neg) {
                return !a.neg
            }
            return describe(a.e) < describe(b.e)
        }
    }
    var vt = build_chain(vars, that.at, addOp, subOp)
    if (empty(consts)) {
        return vt
    }
    var ct = build_chain(consts, that.at, addOp, subOp)
    return new ExprOp2(at = that.at, op := addOp, left = vt, right = ct)
}



def private count_terms(e : ExpressionPtr; addOp : string; var nv : int&; var nc : int&) {
    if (e == null) return
    if (e is ExprOp2) {
        let o = e as ExprOp2
        let isChainOp = addOp == "+" ? (o.op == "+" || o.op == "-") : (o.op == addOp)
        if (isChainOp) {
            count_terms(o.left, addOp, nv, nc)
            count_terms(o.right, addOp, nv, nc)
            return
        }
    } elif (e is ExprOp1) {
        let o = e as ExprOp1
        if (addOp == "+" && o.op == "-") {
            count_terms(o.subexpr, addOp, nv, nc)
            return
        }
    }
    if (is_all_const(e)) {
        nc ++
    } else {
        nv ++
    }
}




def public has_scattered_consts(that : ExprOp2?; no_fast_math : bool = false) : bool {
    if (that == null || (no_fast_math && is_float_valued(that))) return false
    var nv = 0
    var nc = 0
    if (that.op == "+" || that.op == "-") {
        if (already_grouped(that, "+")) return false
        count_terms(that, "+", nv, nc)
    } elif (that.op == "*") {
        if (already_grouped(that, "*")) return false
        count_terms(that, "*", nv, nc)
    } else {
        return false
    }
    return nv >= 1 && nc >= 2
}

class private ReassocVisitor : AstVisitor {
    changed : bool
    noFastMath : bool
    def override visitExprOp2(var that : ExprOp2?) : ExpressionPtr {
        
        
        if (noFastMath && is_float_valued(that)) {
            return that
        }
        var res : ExpressionPtr = null
        if (that.op == "*") {
            var terms : array<ReTerm>
            collect_mul(that, terms)
            res = regroup(that, terms, "*", "/")
        } elif (that.op == "+" || that.op == "-") {
            var terms : array<ReTerm>
            collect_add(that, false, terms)
            res = regroup(that, terms, "+", "-")
        }
        if (res != null) {
            changed = true
            return res
        }
        return that
    }
}












def private sel3(e : ExpressionPtr) : ExprOp3? {
    return (e != null && e is ExprOp3) ? (e as ExprOp3) : null   
}


def private select_let_name(s : ExpressionPtr) : string {
    if (s is ExprLet && length((s as ExprLet).variables) == 1 &&
            sel3((s as ExprLet).variables[0].init) != null) {
        return "{(s as ExprLet).variables[0].name}"
    }
    return ""
}


def private ref_var_name(e : ExpressionPtr) : string {
    var x = e
    if (x != null && x is ExprRef2Value) {
        x = (x as ExprRef2Value).subexpr
    }
    return (x != null && x is ExprVar) ? "{(x as ExprVar).name}" : ""
}








def private select_arm_eval_safe(e : ExpressionPtr) : bool {
    if (e == null || e is ExprVar || e |> is_expr_const()) return true   
    if (e is ExprOp1) return select_arm_eval_safe((e as ExprOp1).subexpr)
    if (e is ExprOp2) {
        let o = e as ExprOp2
        if ((o.op == "/" || o.op == "%") && !is_float_valued(e)) return false
        return select_arm_eval_safe(o.left) && select_arm_eval_safe(o.right)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        return select_arm_eval_safe(o.subexpr) && select_arm_eval_safe(o.left) && select_arm_eval_safe(o.right)
    }
    if (e is ExprCall) {
        for (a in (e as ExprCall).arguments) {
            if (!select_arm_eval_safe(a)) return false
        }
        return true
    }
    if (e is ExprRef2Value) return select_arm_eval_safe((e as ExprRef2Value).subexpr)
    if (e is ExprSwizzle) return select_arm_eval_safe((e as ExprSwizzle).value)
    if (e is ExprField) return select_arm_eval_safe((e as ExprField).value)
    if (e is ExprCast) return select_arm_eval_safe((e as ExprCast).subexpr)
    if (e is ExprMakeTuple) {
        for (v in (e as ExprMakeTuple).values) {
            if (!select_arm_eval_safe(v)) return false
        }
        return true
    }
    return false   
}



def private chain_successor(var ub : FlatUsesBuilder?; var blk : ExprBlock?; accName, condKey : string;
                            afterIdx : int; consumed : table<int>) : int {
    let hk = hash(accName)
    
    if (!key_exists(ub.nameUses, hk) || length(ub.nameUses[hk]) != 1) return -1
    let j = ub.nameUses[hk][0]
    
    if (j <= afterIdx || key_exists(consumed, j) || select_let_name(blk.list[j]) == "") return -1
    let succSel = sel3((blk.list[j] as ExprLet).variables[0].init)
    
    if (describe(succSel.subexpr) != condKey || ref_var_name(succSel.right) != accName) return -1
    return j
}






def private build_select_chain(var ub : FlatUsesBuilder?; var blk : ExprBlock?; mutableVars : table<string>;
                               consumed : table<int>; i : int) : array<int> {
    var chain : array<int>
    let headName = select_let_name(blk.list[i])
    if (headName == "") return <- chain
    var headSel = sel3((blk.list[i] as ExprLet).variables[0].init)
    if (reads_mutable(headSel.subexpr, mutableVars)) return <- chain
    let condKey = describe(headSel.subexpr)
    chain |> push(i)
    var accName = headName
    while (true) {
        let j = chain_successor(ub, blk, accName, condKey, chain[length(chain) - 1], consumed)
        if (j < 0) break
        
        
        
        
        let tailSel = sel3((blk.list[chain[length(chain) - 1]] as ExprLet).variables[0].init)
        if (!select_arm_eval_safe(tailSel.left)) break
        chain |> push(j)
        accName = "{(blk.list[j] as ExprLet).variables[0].name}"
    }
    return <- chain
}

def public fuse_select_chains(var blk : ExprBlock?) : bool {
    let n = length(blk.list)
    if (n < 2) return false
    var mutableVars <- collect_mutable(blk)
    var ub = new FlatUsesBuilder()
    make_visitor(*ub) $(adapter) {
        for (j in range(n)) {
            ub.j = j
            clear(ub.seen)
            visit(blk.list[j], adapter)
        }
    }
    var consumed : table<int>
    var changed = false
    for (i in range(n)) {
        if (key_exists(consumed, i)) continue
        var chain <- build_select_chain(ub, blk, mutableVars, consumed, i)
        if (length(chain) >= 2) {
            
            var baseExpr = clone_expression(sel3((blk.list[chain[0]] as ExprLet).variables[0].init).right)
            for (ci in range(length(chain) - 1)) {     
                var lc = blk.list[chain[ci]] as ExprLet
                lc.variables[0].init = sel3(lc.variables[0].init).left
                consumed |> insert(chain[ci])
            }
            let lastIdx = chain[length(chain) - 1]      
            sel3((blk.list[lastIdx] as ExprLet).variables[0].init).right = baseExpr
            consumed |> insert(lastIdx)
            changed = true
        }
        delete chain
    }
    delete consumed
    delete mutableVars
    unsafe {
        delete ub
    }
    return changed
}


def public has_fusable_select_chain(var blk : ExprBlock?) : bool {
    let n = length(blk.list)
    if (n < 2) return false
    var mutableVars <- collect_mutable(blk)
    var ub = new FlatUsesBuilder()
    make_visitor(*ub) $(adapter) {
        for (j in range(n)) {
            ub.j = j
            clear(ub.seen)
            visit(blk.list[j], adapter)
        }
    }
    var consumed : table<int>   
    var found = false
    for (i in range(n)) {
        var chain <- build_select_chain(ub, blk, mutableVars, consumed, i)
        let isChain = length(chain) >= 2
        delete chain
        if (isChain) {
            found = true
            break
        }
    }
    delete consumed
    delete mutableVars
    unsafe {
        delete ub
    }
    return found
}

def public fold_body(var func : FunctionPtr; no_fast_math : bool = false; expand_lerp : bool = false) : bool {
    
    
    
    if (!(func.body is ExprBlock)) return false
    let nfm = no_fast_math
    var changed = const_prop_locals(func.body as ExprBlock)
    
    
    if (fuse_select_chains(func.body as ExprBlock)) {
        changed = true
    }
    
    
    
    var rv = new ReassocVisitor()
    rv.noFastMath = nfm
    make_visitor(*rv) $(adapter) {
        visit(func.body, adapter)
    }
    if (rv.changed) {
        changed = true
    }
    unsafe {
        delete rv
    }
    var v = new FoldVisitor(noFastMath = nfm, expandLerp = expand_lerp)
    make_visitor(*v) $(adapter) {
        visit(func.body, adapter)
    }
    if (v.changed) {
        changed = true
    }
    unsafe {
        delete v
    }
    
    
    
    var blk = func.body as ExprBlock
    var si = length(blk.list) - 1
    while (si >= 0) {
        var s = blk.list[si]
        if (s is ExprCopy) {
            let cp = s as ExprCopy
            if (describe(cp.left) == describe(cp.right) && !has_sideeffects(cp.left)) {
                blk.list |> erase(si)
                changed = true
            }
        }
        si --
    }
    
    
    
    if (!changed) {
        si = length(blk.list) - 1
        while (si >= 0) {
            var s = blk.list[si]
            if (s is ExprLet) {
                var lt = s as ExprLet
                for (lv in lt.variables) {
                    if (is_zero_const(lv.init)) {
                        lv.init = null
                        changed = true
                    }
                }
            }
            si --
        }
    }
    return changed
}





struct private LaneSrc {
    lane : int          
    e : ExpressionPtr   
}

def private lane_letter(i : int) : string {
    if (i == 0) return "x"
    if (i == 1) return "y"
    if (i == 2) return "z"
    return "w"
}


def private float_ctor_of(e : ExpressionPtr) : ExprCall? {
    if (e == null || !(e is ExprCall)) return null
    var c = e as ExprCall
    let nm = psh_simple_name("{c.name}")
    if (nm != "float2" && nm != "float3" && nm != "float4") return null
    return c
}

def private r2v_unwrap(var e : ExpressionPtr) : ExpressionPtr {
    return e is ExprRef2Value ? (e as ExprRef2Value).subexpr : e
}


def private swizzle_decomposable(e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e is ExprRef2Value) return swizzle_decomposable((e as ExprRef2Value).subexpr)
    if (e is ExprConstFloat2 || e is ExprConstFloat3 || e is ExprConstFloat4) return true
    if (e is ExprSwizzle) return float_vec_dim(expr_bt((e as ExprSwizzle).value)) > 0
    return float_ctor_of(e) != null
}




def private resolve_lanes(var e : ExpressionPtr; var out : array<LaneSrc>) : bool {
    if (e == null) return false
    if (e is ExprRef2Value) return resolve_lanes((e as ExprRef2Value).subexpr, out)
    let d = float_vec_dim(expr_bt(e))
    if (d == 0) return false
    if (e is ExprConstFloat2) {
        let v = (e as ExprConstFloat2).value
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.x)))
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.y)))
        return true
    }
    if (e is ExprConstFloat3) {
        let v = (e as ExprConstFloat3).value
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.x)))
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.y)))
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.z)))
        return true
    }
    if (e is ExprConstFloat4) {
        let v = (e as ExprConstFloat4).value
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.x)))
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.y)))
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.z)))
        out |> push(LaneSrc(lane = -1, e = new ExprConstFloat(at = e.at, value = v.w)))
        return true
    }
    if (e is ExprSwizzle) {
        var sw = e as ExprSwizzle
        var inner : array<LaneSrc>
        var ok = resolve_lanes(sw.value, inner)
        if (ok) {
            for (f in sw.fields) {
                if (int(f) >= length(inner)) {
                    ok = false
                } else {
                    out |> push(inner[int(f)])
                }
            }
        }
        unsafe {
            delete inner
        }
        return ok && length(sw.fields) == d
    }
    var c = float_ctor_of(e)
    if (c != null) {
        
        if (length(c.arguments) == 1 && expr_bt(c.arguments[0]) == Type.tFloat) {
            for (_i in range(d)) {
                out |> push(LaneSrc(lane = -1, e = c.arguments[0]))
            }
            return true
        }
        var total = 0
        for (i in range(length(c.arguments))) {
            var a = c.arguments[i]
            let abt = expr_bt(a)
            if (abt == Type.tFloat) {
                var bk = ""
                var base : ExpressionPtr
                var comp = ""
                if (component_read_of(a, bk, base, comp)) {
                    out |> push(LaneSrc(lane = lane_index(comp), e = base))
                } else {
                    out |> push(LaneSrc(lane = -1, e = a))
                }
                total ++
            } elif (float_vec_dim(abt) > 0) {
                if (!resolve_lanes(a, out)) return false
                total += float_vec_dim(abt)
            } else {
                return false
            }
        }
        return total == d
    }
    
    for (i in range(d)) {
        out |> push(LaneSrc(lane = i, e = e))
    }
    return true
}

let private SWF_NONE = 0
let private SWF_VALUE = 1      
let private SWF_BASE = 2       
let private SWF_SWIZZLE = 3    
let private SWF_SCALAR = 4     
let private SWF_SPLAT = 5      
let private SWF_CTOR = 6       



def private swizzle_sel_runs(sel : array<LaneSrc>; var runs : array<int2>) {
    var i = 0
    while (i < length(sel)) {
        if (sel[i].lane < 0) {
            runs |> push(int2(i, 1))
            i ++
        } else {
            let bk = describe(sel[i].e)
            var j = i + 1
            while (j < length(sel) && sel[j].lane >= 0 && describe(sel[j].e) == bk) {
                j ++
            }
            runs |> push(int2(i, j - i))
            i = j
        }
    }
}



def private swizzle_fold_classify(var that : ExprSwizzle?; var sel : array<LaneSrc>) : int {
    if (that == null || that.fieldFlags.write) return SWF_NONE
    let nOut = length(that.fields)
    if (nOut < 1 || nOut > 4 || !swizzle_decomposable(that.value)) return SWF_NONE
    var lanes : array<LaneSrc>
    var ok = resolve_lanes(that.value, lanes)
    let nLanes = length(lanes)
    if (ok) {
        for (f in that.fields) {
            if (int(f) >= nLanes) {
                ok = false
            }
        }
    }
    if (ok) {
        for (f in that.fields) {
            sel |> push(lanes[int(f)])
        }
    }
    unsafe {
        delete lanes
    }
    if (!ok) return SWF_NONE
    var nScalar = 0
    for (s in sel) {
        if (s.lane < 0) {
            nScalar ++
        }
    }
    
    if (nScalar == 0) {
        let k0 = describe(sel[0].e)
        var same = true
        for (s in sel) {
            if (describe(s.e) != k0) {
                same = false
            }
        }
        if (same) {
            var ident = nOut == float_vec_dim(expr_bt(sel[0].e))
            for (i in range(nOut)) {
                if (sel[i].lane != i) {
                    ident = false
                }
            }
            return ident ? SWF_BASE : SWF_SWIZZLE
        }
    }
    if (nOut == 1) return SWF_SCALAR    
    
    var ident = nOut == nLanes
    if (ident) {
        for (i in range(nOut)) {
            if (int(that.fields[i]) != i) {
                ident = false
            }
        }
    }
    if (ident) return SWF_VALUE
    
    if (nScalar == nOut) {
        let k0 = describe(sel[0].e)
        var same = true
        for (s in sel) {
            if (describe(s.e) != k0) {
                same = false
            }
        }
        var cv = 0.0
        if (same && !scalar_float_const(sel[0].e, cv)) return SWF_SPLAT
    }
    
    if (nOut > nLanes) return SWF_NONE
    var runs : array<int2>
    swizzle_sel_runs(sel, runs)
    var bad = false
    for (r in runs) {
        if (sel[r.x].lane >= 0) {
            if (r.y != float_vec_dim(expr_bt(sel[r.x].e))) {
                bad = true
            } else {
                for (k in range(r.y)) {
                    if (sel[r.x + k].lane != k) {
                        bad = true
                    }
                }
            }
        }
    }
    
    if (!bad) {
        var vc = float_ctor_of(r2v_unwrap(that.value))
        if (vc != null && length(vc.arguments) == length(runs)) {
            var same = true
            for (idx in range(length(runs))) {
                if (describe(sel[runs[idx].x].e) != describe(vc.arguments[idx])) {
                    same = false
                }
            }
            bad = same
        }
    }
    delete runs
    return bad ? SWF_NONE : SWF_CTOR
}


def public is_unfolded_swizzle_lanes(var e : ExprSwizzle?) : bool {
    var sel : array<LaneSrc>
    let k = swizzle_fold_classify(e, sel)
    unsafe {
        delete sel
    }
    return k != SWF_NONE
}



def private swizzle_fold_rewrite(var that : ExprSwizzle?) : ExpressionPtr {
    var sel : array<LaneSrc>
    let kind = swizzle_fold_classify(that, sel)
    var res : ExpressionPtr
    if (kind == SWF_VALUE) {
        res = that.value
    } elif (kind == SWF_BASE || kind == SWF_SCALAR) {
        res = sel[0].e
    } elif (kind == SWF_SWIZZLE) {
        var mask = ""
        for (s in sel) {
            mask += lane_letter(s.lane)     
        }
        res = new ExprSwizzle(at = that.at, value = sel[0].e, mask := mask)
    } elif (kind == SWF_SPLAT) {
        var sc = sel[0].e
        res = make_float_splat(length(sel), that.at, sc)
    } elif (kind == SWF_CTOR) {
        var runs : array<int2>
        swizzle_sel_runs(sel, runs)
        var args : array<ExpressionPtr>
        args |> reserve(length(runs))
        var seen : table<string>
        for (r in runs) {
            var a = sel[r.x].e
            let k = describe(a)
            if (key_exists(seen, k)) {
                a = clone_expression(a)
            } else {
                seen |> insert(k)
            }
            args |> push(a)
        }
        res = make_float_ctor(length(sel), that.at, args)
        delete runs
        delete seen
        unsafe {
            delete args
        }
    }
    unsafe {
        delete sel
    }
    return res
}





def private psh_simple_name(fullname : string) : string {
    let t1 = find(fullname, 96, 0)
    if (t1 < 0) return fullname
    let t2 = find(fullname, 96, t1 + 1)
    let endp = t2 < 0 ? length(fullname) : t2
    return slice(fullname, t1 + 1, endp)
}

def private psh_reserved(name : das_string) : bool {
    return name |> starts_with("__flat_") || name |> starts_with("__ssa_") || name |> starts_with("_preshader_")
}



def private name_counter_suffix(name : das_string; prefix : string) : int {
    if (!(name |> starts_with(prefix))) return -1
    let s = slice("{name}", length(prefix))
    if (empty(s)) return -1
    let v = to_int(s)
    return "{v}" == s ? v : -1
}




def private psh_has_compute(e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e is ExprRef2Value) return psh_has_compute((e as ExprRef2Value).subexpr)
    if (e is ExprOp1 || e is ExprOp2 || e is ExprOp3 || e is ExprCall) return true
    if (e is ExprField) return psh_has_compute((e as ExprField).value)
    if (e is ExprSwizzle) return psh_has_compute((e as ExprSwizzle).value)
    if (e is ExprCast) return psh_has_compute((e as ExprCast).subexpr)
    if (e is ExprPtr2Ref) return psh_has_compute((e as ExprPtr2Ref).subexpr)
    if (e is ExprAt) {
        let o = e as ExprAt
        return psh_has_compute(o.subexpr) || psh_has_compute(o.index)
    }
    return false
}

struct private PEX {
    paramNames : table<string>
    localColor : table<string; bool>    
    mutableVars : table<string>         
    top : array<ExpressionPtr>          
    dedup : table<string; string>       
    rename : table<string; ExpressionPtr>   
    counter : int
    changed : bool
    noFastMath : bool                       
}




def private is_rcp_candidate(pe : PEX; barriers : table<string>; o : ExprOp2?) : bool {
    return (o.op == "/" && expr_bt(o.right) == Type.tFloat && is_float_valued(o) &&
        !(o.right |> is_expr_const()) && !pex_eligible(pe, barriers, o) &&
        pex_eligible(pe, barriers, o.right))
}



def private pex_eligible(pe : PEX; barriers : table<string>; e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e |> is_expr_const()) return true
    if (e is ExprVar) {
        let nm = "{(e as ExprVar).name}"
        if (key_exists(pe.mutableVars, nm)) return false   
        if (key_exists(pe.localColor, nm)) return pe.localColor?[nm] ?? false
        return !key_exists(pe.paramNames, nm)   
    }
    if (e is ExprRef2Value) return pex_eligible(pe, barriers, (e as ExprRef2Value).subexpr)
    if (e is ExprField) return pex_eligible(pe, barriers, (e as ExprField).value)
    if (e is ExprSwizzle) return pex_eligible(pe, barriers, (e as ExprSwizzle).value)
    if (e is ExprCast) return pex_eligible(pe, barriers, (e as ExprCast).subexpr)
    if (e is ExprPtr2Ref) return pex_eligible(pe, barriers, (e as ExprPtr2Ref).subexpr)
    if (e is ExprAt) {
        let o = e as ExprAt
        return pex_eligible(pe, barriers, o.subexpr) && pex_eligible(pe, barriers, o.index)
    }
    if (e is ExprMakeTuple) {
        for (v in (e as ExprMakeTuple).values) {
            if (!pex_eligible(pe, barriers, v)) return false
        }
        return true
    }
    if (e is ExprOp1) return pex_eligible(pe, barriers, (e as ExprOp1).subexpr)
    if (e is ExprOp2) {
        let o = e as ExprOp2
        return pex_eligible(pe, barriers, o.left) && pex_eligible(pe, barriers, o.right)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        return pex_eligible(pe, barriers, o.subexpr) && pex_eligible(pe, barriers, o.left) && pex_eligible(pe, barriers, o.right)
    }
    if (e is ExprCall) {
        let c = e as ExprCall
        
        if (key_exists(barriers, psh_simple_name("{c.name}"))) return false
        for (a in c.arguments) {
            if (!pex_eligible(pe, barriers, a)) return false
        }
        return true
    }
    return false
}



def private pex_hoist_name(var pe : PEX; var e : ExpressionPtr) : string {
    let key = describe(e)
    if (key_exists(pe.dedup, key)) return pe.dedup[key]
    let nm = "_preshader_{pe.counter}"
    pe.counter ++
    pe.dedup[key] = nm
    pe.localColor[nm] = true
    pe.top |> push <| qmacro_expr(${ let $i(nm) = $e(e); })
    return nm
}



def private pex_extract(var pe : PEX; barriers : table<string>; var e : ExpressionPtr) : ExpressionPtr {
    if (e == null) return null
    if (psh_has_compute(e) && pex_eligible(pe, barriers, e)) {
        let nm = pex_hoist_name(pe, e)
        pe.changed = true
        return new ExprVar(at = e.at, name := nm)
    }
    if (e is ExprOp1) {
        var o = e as ExprOp1
        o.subexpr = pex_extract(pe, barriers, o.subexpr)
    } elif (e is ExprOp2) {
        var o = e as ExprOp2
        
        if (!pe.noFastMath && is_rcp_candidate(pe, barriers, o)) {
            var one = new ExprConstFloat(at = o.at, value = 1.0)
            var recip = new ExprOp2(at = o.at, op := "/", left = one, right = o.right)
            let nm = pex_hoist_name(pe, recip)
            pe.changed = true
            return new ExprOp2(at = o.at, op := "*",
                left = pex_extract(pe, barriers, o.left),
                right = new ExprVar(at = o.at, name := nm))
        }
        o.left = pex_extract(pe, barriers, o.left)
        o.right = pex_extract(pe, barriers, o.right)
    } elif (e is ExprOp3) {
        var o = e as ExprOp3
        o.subexpr = pex_extract(pe, barriers, o.subexpr)
        o.left = pex_extract(pe, barriers, o.left)
        o.right = pex_extract(pe, barriers, o.right)
    } elif (e is ExprCall) {
        var c = e as ExprCall
        for (i in range(length(c.arguments))) {
            c.arguments[i] = pex_extract(pe, barriers, c.arguments[i])
        }
    } elif (e is ExprField) {
        var o = e as ExprField
        o.value = pex_extract(pe, barriers, o.value)
    } elif (e is ExprSwizzle) {
        var o = e as ExprSwizzle
        o.value = pex_extract(pe, barriers, o.value)
    } elif (e is ExprRef2Value) {
        var o = e as ExprRef2Value
        o.subexpr = pex_extract(pe, barriers, o.subexpr)
    } elif (e is ExprCast) {
        var o = e as ExprCast
        o.subexpr = pex_extract(pe, barriers, o.subexpr)
    } elif (e is ExprPtr2Ref) {
        var o = e as ExprPtr2Ref
        o.subexpr = pex_extract(pe, barriers, o.subexpr)
    } elif (e is ExprAt) {
        var o = e as ExprAt
        o.subexpr = pex_extract(pe, barriers, o.subexpr)
        o.index = pex_extract(pe, barriers, o.index)
    } elif (e is ExprMakeTuple) {
        var o = e as ExprMakeTuple
        for (vi in range(length(o.values))) {
            o.values[vi] = pex_extract(pe, barriers, o.values[vi])
        }
    } elif (e is ExprMakeStruct) {
        var ms = e as ExprMakeStruct
        for (si in range(length(ms.structs))) {
            for (fld in *(ms.structs[si])) {
                fld.value = pex_extract(pe, barriers, fld.value)
            }
        }
    }
    return e
}



def private extract_preshader(var func : FunctionPtr; var blk : ExprBlock?; barriers : table<string>; var counter : int&; no_fast_math : bool) : bool {
    var pe = PEX(counter = counter, noFastMath = no_fast_math)
    for (a in func.arguments) {
        pe.paramNames |> insert("{a.name}")
    }
    pe.mutableVars <- collect_mutable(blk)
    
    var oldPrefix = 0
    for (s in blk.list) {
        if (s is ExprLet && length((s as ExprLet).variables) == 1 &&
                (s as ExprLet).variables[0].name |> starts_with("_preshader_")) {
            let lv = (s as ExprLet).variables[0]
            if (lv.init != null) {
                pe.dedup["{describe(lv.init)}"] = "{lv.name}"
            }
            pe.localColor["{lv.name}"] = true
            
            let cnum = name_counter_suffix(lv.name, "_preshader_")
            if (cnum >= pe.counter) {
                pe.counter = cnum + 1
            }
            oldPrefix ++
        } else {
            break
        }
    }
    var body : array<ExpressionPtr>
    for (s0 in blk.list) {
        var s = s0
        if (!empty(pe.rename) && reads_any(s, pe.rename)) {
            s = subst_consts(s, pe.rename)
        }
        if (s is ExprLet && length((s as ExprLet).variables) == 1 &&
                (s as ExprLet).variables[0].name |> starts_with("_preshader_")) {
            body |> push(s)
            continue
        }
        if (s is ExprLet && length((s as ExprLet).variables) == 1 && !psh_reserved((s as ExprLet).variables[0].name)) {
            var lc = s as ExprLet
            let vname = "{lc.variables[0].name}"
            var init = lc.variables[0].init
            if (init != null && pex_eligible(pe, barriers, init)) {
                if (psh_has_compute(init)) {
                    
                    let nm = pex_hoist_name(pe, init)
                    pe.rename[vname] = new ExprVar(at = init.at, name := nm)
                    pe.changed = true
                } else {
                    
                    pe.rename[vname] = clone_expression(init)
                    pe.changed = true
                }
                continue
            }
        }
        
        if (s is ExprLet) {
            var lc = s as ExprLet
            for (lv in lc.variables) {
                if (lv.init != null) {
                    lv.init = pex_extract(pe, barriers, lv.init)
                }
                pe.localColor["{lv.name}"] = false
            }
        } elif (s is ExprCopy) {
            var cp = s as ExprCopy
            cp.right = pex_extract(pe, barriers, cp.right)
        } elif (s is ExprReturn) {
            var rt = s as ExprReturn
            rt.subexpr = pex_extract(pe, barriers, rt.subexpr)
        }
        body |> push(s)
    }
    if (pe.changed) {
        
        while (!empty(blk.list)) {
            blk.list |> erase(length(blk.list) - 1)
        }
        for (i in range(oldPrefix)) {
            blk.list |> emplace(body[i])
        }
        for (t in pe.top) {
            blk.list |> emplace(t)
        }
        for (i in range(oldPrefix, length(body))) {
            blk.list |> emplace(body[i])
        }
    }
    let result = pe.changed
    counter = pe.counter
    delete pe.paramNames
    delete pe.localColor
    delete pe.mutableVars
    delete pe.dedup
    unsafe {
        delete pe.rename
        delete pe.top
        delete body
    }
    return result
}







def private store_base(e : Expression const?) : ExpressionPtr {
    if (e == null) return null
    if (e is ExprAt) return store_base((e as ExprAt).subexpr)
    if (e is ExprField) return store_base((e as ExprField).value)
    if (e is ExprSwizzle) return store_base((e as ExprSwizzle).value)
    if (e is ExprPtr2Ref) return store_base((e as ExprPtr2Ref).subexpr)
    if (e is ExprRef2Value) return store_base((e as ExprRef2Value).subexpr)
    return e is ExprVar ? unsafe(reinterpret<Expression? -const>(e)) : null
}




class private MutCollect : AstVisitor {
    names : table<string>
    def override preVisitExprCopy(expr : ExprCopy?) : void {
        let base = store_base(expr.left)
        if (base != null) {
            names |> insert("{(base as ExprVar).name}")
        }
    }
}

def private collect_mutable(blk : ExprBlock?) : table<string> {
    var mc = new MutCollect()
    make_visitor(*mc) $(a) {
        visit(blk, a)
    }
    var r : table<string>
    for (n in keys(mc.names)) {
        r |> insert(n)
    }
    unsafe {
        delete mc
    }
    return <- r
}




def private reads_mutable(e : ExpressionPtr; mutableVars : table<string>) : bool {
    if (e == null || empty(mutableVars) || e |> is_expr_const()) return false
    if (e is ExprVar) return key_exists(mutableVars, "{(e as ExprVar).name}")
    if (e is ExprRef2Value) return reads_mutable((e as ExprRef2Value).subexpr, mutableVars)
    if (e is ExprField) return reads_mutable((e as ExprField).value, mutableVars)
    if (e is ExprSwizzle) return reads_mutable((e as ExprSwizzle).value, mutableVars)
    if (e is ExprCast) return reads_mutable((e as ExprCast).subexpr, mutableVars)
    if (e is ExprPtr2Ref) return reads_mutable((e as ExprPtr2Ref).subexpr, mutableVars)
    if (e is ExprOp1) return reads_mutable((e as ExprOp1).subexpr, mutableVars)
    if (e is ExprOp2) {
        let o = e as ExprOp2
        return reads_mutable(o.left, mutableVars) || reads_mutable(o.right, mutableVars)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        return reads_mutable(o.subexpr, mutableVars) || reads_mutable(o.left, mutableVars) || reads_mutable(o.right, mutableVars)
    }
    if (e is ExprAt) {
        let o = e as ExprAt
        return reads_mutable(o.subexpr, mutableVars) || reads_mutable(o.index, mutableVars)
    }
    if (e is ExprCall) {
        for (a in (e as ExprCall).arguments) {
            if (reads_mutable(a, mutableVars)) return true
        }
        return false
    }
    if (e is ExprMakeTuple) {
        for (v in (e as ExprMakeTuple).values) {
            if (reads_mutable(v, mutableVars)) return true
        }
        return false
    }
    if (e is ExprMakeStruct) {
        var ms = e as ExprMakeStruct
        for (si in range(length(ms.structs))) {
            for (fld in *(ms.structs[si])) {
                if (reads_mutable(fld.value, mutableVars)) return true
            }
        }
        return false
    }
    return true
}

class private CseTally : AstVisitor {
    collectSample : bool        
    counts : table<string; int>
    sample : table<string; ExpressionPtr>
    mutableVars : table<string>
    def override preVisitExpression(expr : ExpressionPtr) : void {
        
        
        
        if (expr is ExprRef2Value) {
            return
        }
        if (psh_has_compute(expr) && !reads_mutable(expr, mutableVars)) {
            let k = "{describe(expr)}"
            counts[k] = (counts?[k] ?? 0) + 1
            if (collectSample && !key_exists(sample, k)) {
                sample[k] = clone_expression(expr)
            }
        }
    }
}



def private cse_replace_expr(var e : ExpressionPtr; key, refName : string) : ExpressionPtr {
    if (e == null) return null
    if (psh_has_compute(e) && "{describe(e)}" == key) {
        return new ExprVar(at = e.at, name := refName)
    }
    if (e is ExprOp1) {
        var o = e as ExprOp1
        o.subexpr = cse_replace_expr(o.subexpr, key, refName)
    } elif (e is ExprOp2) {
        var o = e as ExprOp2
        o.left = cse_replace_expr(o.left, key, refName)
        o.right = cse_replace_expr(o.right, key, refName)
    } elif (e is ExprOp3) {
        var o = e as ExprOp3
        o.subexpr = cse_replace_expr(o.subexpr, key, refName)
        o.left = cse_replace_expr(o.left, key, refName)
        o.right = cse_replace_expr(o.right, key, refName)
    } elif (e is ExprCall) {
        var c = e as ExprCall
        for (i in range(length(c.arguments))) {
            c.arguments[i] = cse_replace_expr(c.arguments[i], key, refName)
        }
    } elif (e is ExprField) {
        var o = e as ExprField
        o.value = cse_replace_expr(o.value, key, refName)
    } elif (e is ExprSwizzle) {
        var o = e as ExprSwizzle
        o.value = cse_replace_expr(o.value, key, refName)
    } elif (e is ExprRef2Value) {
        var o = e as ExprRef2Value
        o.subexpr = cse_replace_expr(o.subexpr, key, refName)
    } elif (e is ExprCast) {
        var o = e as ExprCast
        o.subexpr = cse_replace_expr(o.subexpr, key, refName)
    } elif (e is ExprPtr2Ref) {
        var o = e as ExprPtr2Ref
        o.subexpr = cse_replace_expr(o.subexpr, key, refName)
    } elif (e is ExprAt) {
        var o = e as ExprAt
        o.subexpr = cse_replace_expr(o.subexpr, key, refName)
        o.index = cse_replace_expr(o.index, key, refName)
    } elif (e is ExprMakeTuple) {
        var o = e as ExprMakeTuple
        for (vi in range(length(o.values))) {
            o.values[vi] = cse_replace_expr(o.values[vi], key, refName)
        }
    } elif (e is ExprMakeStruct) {
        var ms = e as ExprMakeStruct
        for (si in range(length(ms.structs))) {
            for (fld in *(ms.structs[si])) {
                fld.value = cse_replace_expr(fld.value, key, refName)
            }
        }
    }
    return e
}

def private cse_replace_stmt(var s : ExpressionPtr; key, refName : string) {
    if (s is ExprLet) {
        var lc = s as ExprLet
        for (lv in lc.variables) {
            if (lv.init != null) {
                lv.init = cse_replace_expr(lv.init, key, refName)
            }
        }
    } elif (s is ExprCopy) {
        var cp = s as ExprCopy
        cp.right = cse_replace_expr(cp.right, key, refName)
    } elif (s is ExprReturn) {
        var rt = s as ExprReturn
        rt.subexpr = cse_replace_expr(rt.subexpr, key, refName)
    }
}




def private cse_tally_stmt(s : ExpressionPtr; a) {
    if (s is ExprLet) {
        for (lv in (s as ExprLet).variables) {
            if (lv.init != null) {
                visit(lv.init, a)
            }
        }
    } elif (s is ExprCopy) {
        visit((s as ExprCopy).right, a)
    } elif (s is ExprReturn) {
        let rt = s as ExprReturn
        if (rt.subexpr != null) {
            visit(rt.subexpr, a)
        }
    }
}




def private preshader_prefix_len(blk : ExprBlock?) : int {
    var k = 0
    for (s in blk.list) {
        if (s is ExprLet && length((s as ExprLet).variables) == 1 &&
                (s as ExprLet).variables[0].name |> starts_with("_preshader_")) {
            k ++
        } else {
            break
        }
    }
    return k
}



def private cse_body(var blk : ExprBlock?; var counter : int&) : bool {
    var anyChange = false
    var guard = 0
    
    for (s in blk.list) {
        if (s is ExprLet && length((s as ExprLet).variables) == 1) {
            var cnum = name_counter_suffix((s as ExprLet).variables[0].name, "_preshader_cse_")
            if (cnum < 0) {
                cnum = name_counter_suffix((s as ExprLet).variables[0].name, "_cse_")
            }
            if (cnum >= counter) {
                counter = cnum + 1
            }
        }
    }
    
    var mutableVars <- collect_mutable(blk)
    while (guard < 4096) {
        guard ++
        
        var counts : table<string; int>
        var sample : table<string; ExpressionPtr>
        var firstStmt : table<string; int>
        for (i in range(length(blk.list))) {
            var ct = new CseTally()
            ct.collectSample = true
            ct.mutableVars := mutableVars
            make_visitor(*ct) $(a) {
                cse_tally_stmt(blk.list[i], a)
            }
            for (k in keys(ct.counts)) {
                counts[k] = (counts?[k] ?? 0) + (ct.counts?[k] ?? 0)
                if (!key_exists(firstStmt, k)) {
                    firstStmt[k] = i
                    sample[k] = ct.sample?[k] ?? null
                }
            }
            unsafe {
                delete ct
            }
        }
        
        var bestKey = ""
        var bestLen = 0
        for (k in keys(counts)) {
            if ((counts?[k] ?? 0) >= 2 && length(k) > bestLen) {
                bestKey = k
                bestLen = length(k)
            }
        }
        if (bestKey == "") {
            delete counts
            delete firstStmt
            unsafe {
                delete sample
            }
            break
        }
        let fi = firstStmt?[bestKey] ?? 0
        let uniform = fi < preshader_prefix_len(blk)
        let nm = uniform ? "_preshader_cse_{counter}" : "_cse_{counter}"
        counter ++
        
        var src = sample?[bestKey] ?? null
        for (s in blk.list) {
            cse_replace_stmt(s, bestKey, nm)
        }
        var theLet = qmacro_expr(${ let $i(nm) = $e(src); })
        var newlist : array<ExpressionPtr>
        newlist |> reserve(length(blk.list) + 1)
        for (i in range(length(blk.list))) {
            if (i == fi) {
                newlist |> push(theLet)
            }
            newlist |> push(blk.list[i])
        }
        while (!empty(blk.list)) {
            blk.list |> erase(length(blk.list) - 1)
        }
        for (m in newlist) {
            blk.list |> emplace(m)
        }
        delete counts
        delete firstStmt
        unsafe {
            delete sample
            delete newlist
        }
        anyChange = true
    }
    delete mutableVars
    return anyChange
}





def private cm_key(l, r : ExpressionPtr) : string {
    return "{describe(l)}\t-\t{describe(r)}"
}

class private CmTally : AstVisitor {
    counts : table<string; int>
    mutableVars : table<string>
    def override preVisitExprOp2(var expr : ExprOp2?) : void {
        if (expr.op == "-" && is_all_const(expr.left) && !is_all_const(expr.right) &&
                !reads_mutable(expr.right, mutableVars)) {
            let k = cm_key(expr.left, expr.right)
            counts[k] = (counts?[k] ?? 0) + 1
        }
    }
}



def private chain_has_grouped(e : ExpressionPtr; key : string) : bool {
    if (e == null) return false
    if (e is ExprOp2) {
        let o = e as ExprOp2
        if (o.op == "+" || o.op == "-") {
            if (o.op == "-" && is_all_const(o.left) && !is_all_const(o.right) && cm_key(o.left, o.right) == key) {
                return true
            }
            return chain_has_grouped(o.left, key) || chain_has_grouped(o.right, key)
        }
    } elif (e is ExprOp1) {
        let o = e as ExprOp1
        if (o.op == "-") return chain_has_grouped(o.subexpr, key)
    }
    return false
}




def private regroup_candidate(var that : ExprOp2?; cm : table<string; int>; mutableVars : table<string>;
                              no_fast_math : bool; var terms : array<ReTerm>; var ci : int&; var xi : int&) : bool {
    if (that == null || !(that.op == "+" || that.op == "-") || (no_fast_math && is_float_valued(that))) {
        return false
    }
    collect_add(that, false, terms)
    ci = -1
    for (i in range(length(terms))) {
        if (is_all_const(terms[i].e)) {
            if (ci >= 0) return false
            ci = i
        }
    }
    if (ci < 0 || terms[ci].neg) return false
    for (i in range(length(terms))) {
        if (i == ci || !terms[i].neg || reads_mutable(terms[i].e, mutableVars)) {
            continue
        }
        let k = cm_key(terms[ci].e, terms[i].e)
        if ((cm?[k] ?? 0) >= 1 && !chain_has_grouped(that, k)) {
            xi = i
            return true
        }
    }
    return false
}

class private RegroupShareVisitor : AstVisitor {
    changed : bool
    noFastMath : bool
    cm : table<string; int>
    mutableVars : table<string>
    def override visitExprOp2(var that : ExprOp2?) : ExpressionPtr {
        var terms : array<ReTerm>
        var ci = -1
        var xi = -1
        if (!regroup_candidate(that, cm, mutableVars, noFastMath, terms, ci, xi)) {
            unsafe {
                delete terms
            }
            return that
        }
        var newTerms : array<ReTerm>
        newTerms |> push(ReTerm(neg = false,
            e = new ExprOp2(at = that.at, op := "-", left = terms[ci].e, right = terms[xi].e)))
        for (i in range(length(terms))) {
            if (i != ci && i != xi) {
                newTerms |> push(terms[i])
            }
        }
        changed = true
        var r = build_chain(newTerms, that.at, "+", "-")
        unsafe {
            delete terms
            delete newTerms
        }
        return r
    }
}

class private RegroupResidualVisitor : AstVisitor {
    found : bool
    noFastMath : bool
    cm : table<string; int>
    mutableVars : table<string>
    def override preVisitExprOp2(var expr : ExprOp2?) : void {
        var terms : array<ReTerm>
        var ci = -1
        var xi = -1
        if (regroup_candidate(expr, cm, mutableVars, noFastMath, terms, ci, xi)) {
            found = true
        }
        unsafe {
            delete terms
        }
    }
}

def private regroup_to_share(var blk : ExprBlock?; no_fast_math : bool) : bool {
    var mutableVars <- collect_mutable(blk)
    var ct = new CmTally()
    ct.mutableVars := mutableVars
    make_visitor(*ct) $(a) {
        visit(blk, a)
    }
    var ch = false
    if (!empty(ct.counts)) {
        var rv = new RegroupShareVisitor(noFastMath = no_fast_math)
        rv.cm := ct.counts
        rv.mutableVars := mutableVars
        make_visitor(*rv) $(a) {
            visit(blk, a)
        }
        ch = rv.changed
        unsafe {
            delete rv
        }
    }
    unsafe {
        delete ct
    }
    delete mutableVars
    return ch
}






def private alias_source(e : Expression const?) : ExpressionPtr {
    if (e == null) return null
    if (e is ExprRef2Value) return alias_source((e as ExprRef2Value).subexpr)
    return e is ExprVar ? unsafe(reinterpret<Expression? -const>(e)) : null
}

def private eliminate_aliases(var blk : ExprBlock?) : bool {
    var mutableVars <- collect_mutable(blk)
    var rename : table<string; ExpressionPtr>
    var body : array<ExpressionPtr>
    var changed = false
    for (s0 in blk.list) {
        
        var s = !empty(rename) && reads_any(s0, rename) ? subst_consts(s0, rename) : s0
        if (s is ExprLet && length((s as ExprLet).variables) == 1) {
            let lvName = "{(s as ExprLet).variables[0].name}"
            let src = alias_source((s as ExprLet).variables[0].init)
            
            if (src != null && !key_exists(mutableVars, lvName) &&
                    !key_exists(mutableVars, "{(src as ExprVar).name}")) {
                rename[lvName] = clone_expression(src)
                changed = true
                continue
            }
        }
        body |> push(s)
    }
    if (changed) {
        while (!empty(blk.list)) {
            blk.list |> erase(length(blk.list) - 1)
        }
        for (b in body) {
            blk.list |> emplace(b)
        }
    }
    delete mutableVars
    unsafe {
        delete rename
        delete body
    }
    return changed
}






def private pex_residual_expr(pe : PEX; barriers : table<string>; e : ExpressionPtr) : bool {
    if (e == null) return false
    if (psh_has_compute(e) && pex_eligible(pe, barriers, e)) return true
    if (e is ExprOp1) return pex_residual_expr(pe, barriers, (e as ExprOp1).subexpr)
    if (e is ExprOp2) {
        let o = e as ExprOp2
        return pex_residual_expr(pe, barriers, o.left) || pex_residual_expr(pe, barriers, o.right)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        return pex_residual_expr(pe, barriers, o.subexpr) || pex_residual_expr(pe, barriers, o.left) || pex_residual_expr(pe, barriers, o.right)
    }
    if (e is ExprCall) {
        for (a in (e as ExprCall).arguments) {
            if (pex_residual_expr(pe, barriers, a)) return true
        }
        return false
    }
    if (e is ExprField) return pex_residual_expr(pe, barriers, (e as ExprField).value)
    if (e is ExprSwizzle) return pex_residual_expr(pe, barriers, (e as ExprSwizzle).value)
    if (e is ExprRef2Value) return pex_residual_expr(pe, barriers, (e as ExprRef2Value).subexpr)
    if (e is ExprCast) return pex_residual_expr(pe, barriers, (e as ExprCast).subexpr)
    if (e is ExprPtr2Ref) return pex_residual_expr(pe, barriers, (e as ExprPtr2Ref).subexpr)
    if (e is ExprAt) {
        let o = e as ExprAt
        return pex_residual_expr(pe, barriers, o.subexpr) || pex_residual_expr(pe, barriers, o.index)
    }
    if (e is ExprMakeTuple) {
        for (v in (e as ExprMakeTuple).values) {
            if (pex_residual_expr(pe, barriers, v)) return true
        }
        return false
    }
    if (e is ExprMakeStruct) {
        var ms = e as ExprMakeStruct
        for (si in range(length(ms.structs))) {
            for (fld in *(ms.structs[si])) {
                if (pex_residual_expr(pe, barriers, fld.value)) return true
            }
        }
    }
    return false
}



def private rcp_residual_expr(pe : PEX; barriers : table<string>; e : ExpressionPtr) : bool {
    if (e == null) return false
    if (e is ExprOp1) return rcp_residual_expr(pe, barriers, (e as ExprOp1).subexpr)
    if (e is ExprOp2) {
        let o = e as ExprOp2
        if (is_rcp_candidate(pe, barriers, o)) return true
        return rcp_residual_expr(pe, barriers, o.left) || rcp_residual_expr(pe, barriers, o.right)
    }
    if (e is ExprOp3) {
        let o = e as ExprOp3
        return rcp_residual_expr(pe, barriers, o.subexpr) || rcp_residual_expr(pe, barriers, o.left) || rcp_residual_expr(pe, barriers, o.right)
    }
    if (e is ExprCall) {
        for (a in (e as ExprCall).arguments) {
            if (rcp_residual_expr(pe, barriers, a)) return true
        }
        return false
    }
    if (e is ExprField) return rcp_residual_expr(pe, barriers, (e as ExprField).value)
    if (e is ExprSwizzle) return rcp_residual_expr(pe, barriers, (e as ExprSwizzle).value)
    if (e is ExprRef2Value) return rcp_residual_expr(pe, barriers, (e as ExprRef2Value).subexpr)
    if (e is ExprCast) return rcp_residual_expr(pe, barriers, (e as ExprCast).subexpr)
    if (e is ExprPtr2Ref) return rcp_residual_expr(pe, barriers, (e as ExprPtr2Ref).subexpr)
    if (e is ExprAt) {
        let o = e as ExprAt
        return rcp_residual_expr(pe, barriers, o.subexpr) || rcp_residual_expr(pe, barriers, o.index)
    }
    if (e is ExprMakeTuple) {
        for (v in (e as ExprMakeTuple).values) {
            if (rcp_residual_expr(pe, barriers, v)) return true
        }
        return false
    }
    if (e is ExprMakeStruct) {
        var ms = e as ExprMakeStruct
        for (si in range(length(ms.structs))) {
            for (fld in *(ms.structs[si])) {
                if (rcp_residual_expr(pe, barriers, fld.value)) return true
            }
        }
    }
    return false
}

def public opt_residuals(var func : FunctionPtr; barriers : table<string>; no_fast_math : bool = false) : array<string> {
    var res : array<string>
    if (func == null || func.body == null || !(func.body is ExprBlock)) return <- res
    var blk = func.body as ExprBlock
    
    var pe : PEX
    for (a in func.arguments) {
        pe.paramNames |> insert("{a.name}")
    }
    pe.mutableVars <- collect_mutable(blk)
    for (s in blk.list) {
        if (s is ExprLet) {
            for (lv in (s as ExprLet).variables) {
                pe.localColor["{lv.name}"] = lv.name |> starts_with("_preshader_")
            }
        }
    }
    
    let prefix = preshader_prefix_len(blk)
    for (i in range(length(blk.list))) {
        if (i < prefix) {
            continue
        }
        let s = blk.list[i]
        var hit = false
        if (s is ExprLet) {
            for (lv in (s as ExprLet).variables) {
                if (lv.init != null && pex_residual_expr(pe, barriers, lv.init)) {
                    hit = true
                }
            }
        } elif (s is ExprCopy) {
            hit = pex_residual_expr(pe, barriers, (s as ExprCopy).right)
        } elif (s is ExprReturn) {
            hit = pex_residual_expr(pe, barriers, (s as ExprReturn).subexpr)
        }
        if (hit) {
            res |> push("an un-extracted uniform subtree (preshader miss)")
            break
        }
    }
    
    if (!no_fast_math) {
        for (i in range(length(blk.list))) {
            if (i < prefix) {
                continue
            }
            let s = blk.list[i]
            var hit = false
            if (s is ExprLet) {
                for (lv in (s as ExprLet).variables) {
                    if (lv.init != null && rcp_residual_expr(pe, barriers, lv.init)) {
                        hit = true
                    }
                }
            } elif (s is ExprCopy) {
                hit = rcp_residual_expr(pe, barriers, (s as ExprCopy).right)
            } elif (s is ExprReturn) {
                hit = rcp_residual_expr(pe, barriers, (s as ExprReturn).subexpr)
            }
            if (hit) {
                res |> push("an un-rewritten division by a uniform ('x / U' should be 'x * _preshader(1/U)')")
                break
            }
        }
    }
    
    
    var counts : table<string; int>
    for (i in range(length(blk.list))) {
        var ct = new CseTally()
        ct.mutableVars := pe.mutableVars
        make_visitor(*ct) $(a) {
            cse_tally_stmt(blk.list[i], a)
        }
        for (k in keys(ct.counts)) {
            counts[k] = (counts?[k] ?? 0) + (ct.counts?[k] ?? 0)
        }
        unsafe {
            delete ct
        }
    }
    for (k in keys(counts)) {
        if ((counts?[k] ?? 0) >= 2) {
            res |> push("a repeated subtree '{k}' (>=2x) not CSE'd")
            break
        }
    }
    
    
    var cmt = new CmTally()
    cmt.mutableVars := pe.mutableVars
    make_visitor(*cmt) $(a) {
        visit(blk, a)
    }
    if (!empty(cmt.counts)) {
        var rr = new RegroupResidualVisitor(noFastMath = no_fast_math)
        rr.cm := cmt.counts
        rr.mutableVars := pe.mutableVars
        make_visitor(*rr) $(a) {
            visit(blk, a)
        }
        if (rr.found) {
            res |> push("a sum splitting a 'C - x' apart from its grouped twin (regroup-to-share miss)")
        }
        unsafe {
            delete rr
        }
    }
    unsafe {
        delete cmt
    }
    
    
    for (s in blk.list) {
        if (s is ExprLet && length((s as ExprLet).variables) == 1) {
            let lvName = "{(s as ExprLet).variables[0].name}"
            let src = alias_source((s as ExprLet).variables[0].init)
            if (src != null && !key_exists(pe.mutableVars, lvName) &&
                    !key_exists(pe.mutableVars, "{(src as ExprVar).name}")) {
                res |> push("a pure alias let '{lvName}' = '{(src as ExprVar).name}'")
                break
            }
        }
    }
    
    
    
    let cm = fuse_callable(func._module, "mad")
    var fr = new FuseResidualVisitor(checkMad = cm, checkLerp = cm && fuse_callable(func._module, "lerp"),
        checkDot = !no_fast_math && fuse_callable(func._module, "dot", 2), noFastMath = no_fast_math)
    make_visitor(*fr) $(a) {
        visit(func.body, a)
    }
    if (fr.foundMad) {
        res |> push("an un-fused mul-add ('a*b ± c' should be mad)")
    }
    if (fr.foundLerp) {
        res |> push("an un-refused lerp shape (mad(b-a,t,a))")
    }
    if (fr.foundNegAdd) {
        res |> push("an un-packed neg-add ('-a + b' should be 'b - a')")
    }
    if (fr.foundCtor) {
        res |> push("an un-packed ctor lane pattern (should re-vectorize / extract the shared factor)")
    }
    if (fr.foundDot) {
        res |> push("an un-fused lane sum ('v.x + v.y + …' should be dot(v, mask))")
    }
    unsafe {
        delete fr
    }
    delete pe.paramNames
    delete pe.localColor
    delete pe.mutableVars
    delete counts
    return <- res
}



def private log_cse_cache(func : FunctionPtr; var blk : ExprBlock?) {
    var mutableVars <- collect_mutable(blk)
    var counts : table<string; int>
    for (i in range(length(blk.list))) {
        var ct = new CseTally()
        ct.mutableVars := mutableVars
        make_visitor(*ct) $(a) {
            cse_tally_stmt(blk.list[i], a)
        }
        for (k in keys(ct.counts)) {
            counts[k] = (counts?[k] ?? 0) + (ct.counts?[k] ?? 0)
        }
        unsafe {
            delete ct
        }
    }
    var cm = new CmTally()
    cm.mutableVars := mutableVars
    make_visitor(*cm) $(a) {
        visit(blk, a)
    }
    var ks <- [for (k in keys(counts)); k]
    sort(ks) $(a, b : string) : bool {
        let ca = counts?[a] ?? 0
        let cb = counts?[b] ?? 0
        if (ca != cb) {
            return ca > cb
        }
        return a < b
    }
    to_log(LOG_INFO, "flatten cse cache [{func.name}]: {length(ks)} pure subtrees\n")
    for (k in ks) {
        to_log(LOG_INFO, "    {counts?[k] ?? 0}x  {k}\n")
    }
    var cks <- [for (k in keys(cm.counts)); k]
    sort(cks)
    to_log(LOG_INFO, "  const-minus shapes: {length(cks)}\n")
    for (k in cks) {
        to_log(LOG_INFO, "    {cm.counts?[k] ?? 0}x  {k}\n")
    }
    unsafe {
        delete cm
    }
    delete counts
    delete ks
    delete cks
    delete mutableVars
}

def public flatten_preshade_cse(var func : FunctionPtr; barriers : table<string>; no_fast_math : bool = false; log_cse : bool = false) : bool {
    
    
    
    if (!(func.body is ExprBlock)) return false
    var blk = func.body as ExprBlock
    
    
    
    var changed = false
    var guard = 0
    var cseCounter = 0
    var preCounter = 0
    while (guard < 16) {
        guard ++
        var round = false
        if (extract_preshader(func, blk, barriers, preCounter, no_fast_math)) {
            round = true
        }
        if (regroup_to_share(blk, no_fast_math)) {
            round = true
        }
        if (cse_body(blk, cseCounter)) {
            round = true
        }
        if (eliminate_aliases(blk)) {
            round = true
        }
        if (!round) {
            break
        }
        changed = true
    }
    if (guard >= 16) {
        to_log(LOG_WARNING, "flatten: cse/alias loop guard exhausted in {func.name} (oscillation?)\n")
    }
    if (log_cse) {
        log_cse_cache(func, blk)
    }
    return changed
}







def private recip_const(e : ExpressionPtr) : ExpressionPtr {
    if (e == null) return null
    if (e is ExprConstFloat) {
        let v = (e as ExprConstFloat).value
        if (v == 0.0) return null
        return new ExprConstFloat(at = e.at, value = 1.0 / v)
    }
    if (e is ExprConstDouble) {
        let v = (e as ExprConstDouble).value
        if (v == 0.0lf) return null
        return new ExprConstDouble(at = e.at, value = 1.0lf / v)
    }
    if (e is ExprConstFloat2) {
        let v = (e as ExprConstFloat2).value
        if (v.x == 0.0 || v.y == 0.0) return null
        return new ExprConstFloat2(at = e.at, value = float2(1.0 / v.x, 1.0 / v.y))
    }
    if (e is ExprConstFloat3) {
        let v = (e as ExprConstFloat3).value
        if (v.x == 0.0 || v.y == 0.0 || v.z == 0.0) return null
        return new ExprConstFloat3(at = e.at, value = float3(1.0 / v.x, 1.0 / v.y, 1.0 / v.z))
    }
    if (e is ExprConstFloat4) {
        let v = (e as ExprConstFloat4).value
        if (v.x == 0.0 || v.y == 0.0 || v.z == 0.0 || v.w == 0.0) return null
        return new ExprConstFloat4(at = e.at, value = float4(1.0 / v.x, 1.0 / v.y, 1.0 / v.z, 1.0 / v.w))
    }
    return null
}


def public is_unrcp_const_div(e : ExprOp2?) : bool {
    if (e == null || e.op != "/" || !is_float_valued(e)) return false
    return recip_const(e.right) != null
}



def private negate_const(e : ExpressionPtr) : ExpressionPtr {
    if (e == null) return null
    if (e is ExprConstFloat) return new ExprConstFloat(at = e.at, value = -(e as ExprConstFloat).value)
    if (e is ExprConstDouble) return new ExprConstDouble(at = e.at, value = -(e as ExprConstDouble).value)
    if (e is ExprConstInt) return new ExprConstInt(at = e.at, value = -(e as ExprConstInt).value)
    if (e is ExprConstFloat2) return new ExprConstFloat2(at = e.at, value = -(e as ExprConstFloat2).value)
    if (e is ExprConstFloat3) return new ExprConstFloat3(at = e.at, value = -(e as ExprConstFloat3).value)
    if (e is ExprConstFloat4) return new ExprConstFloat4(at = e.at, value = -(e as ExprConstFloat4).value)
    if (e is ExprConstInt2) return new ExprConstInt2(at = e.at, value = -(e as ExprConstInt2).value)
    if (e is ExprConstInt3) return new ExprConstInt3(at = e.at, value = -(e as ExprConstInt3).value)
    if (e is ExprConstInt4) return new ExprConstInt4(at = e.at, value = -(e as ExprConstInt4).value)
    return null
}

def private has_arity_named(mod : Module?; fname : string; argc : int) : bool {
    var found = false
    for_each_function(mod, fname) $(fn) {
        if (length(fn.arguments) == argc) {
            found = true
        }
    }
    for_each_generic(mod, fname) $(fn) {
        if (length(fn.arguments) == argc) {
            found = true
        }
    }
    return found
}

def private fuse_callable(mod : Module?; fname : string; argc : int = 3) : bool {
    if (mod == null) return false
    if (has_arity_named(mod, fname, argc)) return true
    var found = false
    module_for_each_dependency(mod) $(dep, _isPub) {
        if (!found && has_arity_named(dep, fname, argc)) {
            found = true
        }
    }
    return found
}




def private match_mad(var that : ExprOp2?; var ma, mb, mc : ExpressionPtr&) : bool {
    if (that == null) return false
    var fa, fb, other : ExpressionPtr
    var negOther = false        
    var negFactor = false       
    if (qmatch(that, $e(fa) * $e(fb) + $e(other)).matched) {
        pass
    } elif (qmatch(that, $e(other) + $e(fa) * $e(fb)).matched) {
        pass
    } elif (qmatch(that, $e(fa) * $e(fb) - $e(other)).matched) {
        negOther = true
    } elif (qmatch(that, $e(other) - $e(fa) * $e(fb)).matched) {
        negFactor = true
    } else {
        return false
    }
    
    var bta = expr_bt(fa)
    var btb = expr_bt(fb)
    let btc = expr_bt(other)
    if (negFactor) {
        var nf = negate_const(fa)
        if (nf != null) {
            fa = nf
        } else {
            nf = negate_const(fb)
            if (nf == null) return false
            fb = nf
        }
    }
    if (negOther) {
        other = negate_const(other)
        if (other == null) return false
    }
    
    if (vec_elem_bt(btb) != Type.none && bta == vec_elem_bt(btb)) {
        var tmp = fa
        fa = fb
        fb = tmp
        let tmpbt = bta
        bta = btb
        btb = tmpbt
    }
    if (!mad_shape(bta, btb, btc)) return false
    ma = fa
    mb = fb
    mc = other
    return true
}




def private match_neg_add(var that : ExprOp2?; var pos, neg : ExpressionPtr&) : bool {
    if (that == null || !is_mad_elem(expr_bt(that))) return false
    return (qmatch(that, -$e(neg) + $e(pos)).matched ||    
        qmatch(that, $e(pos) + -$e(neg)).matched)           
}




def private match_lerp(var cll : ExprCall?; var la, lb, lt : ExpressionPtr&) : bool {
    if (cll == null) return false
    var da, db, aa, tt : ExpressionPtr
    if (!qmatch(cll, mad($e(db) - $e(da), $e(tt), $e(aa))).matched &&     
        !qmatch(cll, mad(-$e(da) + $e(db), $e(tt), $e(aa))).matched &&    
        !qmatch(cll, mad($e(db) + -$e(da), $e(tt), $e(aa))).matched) return false  
    if (describe(da) != describe(aa) ||
        !lerp_shape(expr_bt(da), expr_bt(db), expr_bt(tt))) return false
    la = aa
    lb = db
    lt = tt
    return true
}



def private make_float_ctor(d : int; at : LineInfo; var lanes : array<ExpressionPtr>) : ExpressionPtr {
    var c0 = 0.0
    var c1 = 0.0
    var c2 = 0.0
    var c3 = 0.0
    
    if (length(lanes) == d && scalar_float_const(lanes[0], c0) && scalar_float_const(lanes[1], c1) &&
            (d < 3 || scalar_float_const(lanes[2], c2)) && (d < 4 || scalar_float_const(lanes[3], c3))) {
        if (d == 2) return new ExprConstFloat2(at = at, value = float2(c0, c1))
        if (d == 3) return new ExprConstFloat3(at = at, value = float3(c0, c1, c2))
        return new ExprConstFloat4(at = at, value = float4(c0, c1, c2, c3))
    }
    let nm = d == 2 ? "float2" : (d == 3 ? "float3" : "float4")
    var c = new ExprCall(at = at, name := nm)
    for (l in lanes) {
        emplace(c.arguments, l)
    }
    return c
}



def private component_read_of(var e : ExpressionPtr; var baseKey : string&; var base : ExpressionPtr&; var comp : string&) : bool {
    if (e == null) return false
    if (e is ExprRef2Value) return component_read_of((e as ExprRef2Value).subexpr, baseKey, base, comp)
    var v : ExpressionPtr
    var nm = ""
    match (e) {
        if (ExprSwizzle(mask = $v(swMask), value = $v(swValue))) {
            nm = "{swMask}"
            v = swValue
        }
        if (ExprField(name = $v(flName), value = $v(flValue))) {
            nm = "{flName}"
            v = flValue
        }
    }
    if (v == null ||
        (nm != "x" && nm != "y" && nm != "z" && nm != "w") ||
        !is_float_vec(expr_bt(v)) || expr_bt(e) != Type.tFloat) return false
    base = v
    baseKey = describe(v)
    comp = nm
    return true
}

let private SIDE_NONE = 0
let private SIDE_EQUAL = 1       
let private SIDE_COMPONENT = 2   
let private SIDE_GATHER = 3      




def private vectorize_side(var that : ExprCall?; d : int; takeLeft : bool; var node : ExpressionPtr&) : int {
    var sides : array<ExpressionPtr>
    sides |> reserve(d)
    for (i in range(d)) {
        var li = that.arguments[i] as ExprOp2
        sides |> push(takeLeft ? li.left : li.right)
    }
    
    if (expr_bt(sides[0]) == Type.tFloat) {
        let key0 = describe(sides[0])
        var eq = true
        for (i in range(1, d)) {
            if (describe(sides[i]) != key0) {
                eq = false
                break
            }
        }
        if (eq) {
            node = clone_expression(sides[0])
            unsafe {
                delete sides
            }
            return SIDE_EQUAL
        }
    }
    
    var baseKey = ""
    var base : ExpressionPtr
    var mask = ""
    var isComp = true
    for (i in range(d)) {
        var bk = ""
        var b : ExpressionPtr
        var c = ""
        if (!component_read_of(sides[i], bk, b, c) || (i > 0 && bk != baseKey)) {
            isComp = false
            break
        }
        baseKey = bk
        base = b
        mask += c 
    }
    if (isComp) {
        let dim = expr_bt(base) == Type.tFloat2 ? 2 : (expr_bt(base) == Type.tFloat3 ? 3 : 4)
        if (dim == d && mask == slice("xyzw", 0, d)) {
            node = clone_expression(base)
        } else {
            node = new ExprField(at = that.at, value = clone_expression(base), name := mask)
        }
        unsafe {
            delete sides
        }
        return SIDE_COMPONENT
    }
    
    var lanes <- [for (sd in sides); clone_expression(sd)]
    node = make_float_ctor(d, that.at, lanes)
    unsafe {
        delete lanes
        delete sides
    }
    return SIDE_GATHER
}

def private scalar_float_const(e : ExpressionPtr; var v : float&) : bool {
    if (e == null || !(e is ExprConstFloat)) return false
    v = (e as ExprConstFloat).value
    return true
}




def private make_float_splat(d : int; at : LineInfo; var sc : ExpressionPtr) : ExpressionPtr {
    let nm = d == 2 ? "float2" : (d == 3 ? "float3" : "float4")
    var c = new ExprCall(at = at, name := nm)
    emplace(c.arguments, sc)
    return c
}

def private ctor_fuse_rewrite(var that : ExprCall?; no_fast_math : bool) : ExpressionPtr {
    let d = ctor_dim_by_name(that)
    if (d < 2 || !is_float_vec(expr_bt(that))) return null
    
    var sameOp = ""
    if (that.arguments[0] is ExprOp2) {
        let op0 = "{(that.arguments[0] as ExprOp2).op}"
        if (op0 == "+" || op0 == "-" || op0 == "*" || op0 == "/") {
            sameOp = op0
            for (i in range(1, d)) {
                if (!(that.arguments[i] is ExprOp2) || "{(that.arguments[i] as ExprOp2).op}" != op0) {
                    sameOp = ""
                    break
                }
            }
        }
    }
    if (sameOp != "") {
        var aN : ExpressionPtr
        var bN : ExpressionPtr
        let ka = vectorize_side(that, d, true, aN)
        let kb = vectorize_side(that, d, false, bN)
        
        if (ka == SIDE_COMPONENT || kb == SIDE_COMPONENT) {
            
            if (ka == SIDE_EQUAL && (sameOp == "+" || sameOp == "-")) {
                aN = make_float_splat(d, that.at, aN)
            }
            if (kb == SIDE_EQUAL && (sameOp == "+" || sameOp == "-")) {
                bN = make_float_splat(d, that.at, bN)
            }
            return new ExprOp2(at = that.at, op := sameOp, left = aN, right = bN)
        }
    }
    
    if (that.arguments[0] is ExprOp2) {
        var l0 = that.arguments[0] as ExprOp2
        if (l0.op == "*" || l0.op == "/") {
            for (ci in range(l0.op == "*" ? 2 : 1)) {
                var cand = (l0.op == "/" || ci == 1) ? l0.right : l0.left
                if (expr_bt(cand) != Type.tFloat) {
                    continue
                }
                let key = describe(cand)
                var rests : array<ExpressionPtr>
                var allMatch = true
                for (i in range(d)) {
                    var ok = false
                    if (that.arguments[i] is ExprOp2) {
                        var li = that.arguments[i] as ExprOp2
                        if (li.op == l0.op) {
                            if (li.op == "*" && describe(li.left) == key && expr_bt(li.left) == Type.tFloat) {
                                rests |> push(clone_expression(li.right))
                                ok = true
                            } elif (describe(li.right) == key && expr_bt(li.right) == Type.tFloat) {
                                rests |> push(clone_expression(li.left))
                                ok = true
                            }
                        }
                    }
                    if (!ok) {
                        allMatch = false
                        break
                    }
                }
                if (allMatch) {
                    var nc = make_float_ctor(d, that.at, rests)
                    var sc = clone_expression(cand)
                    unsafe {
                        delete rests
                    }
                    return new ExprOp2(at = that.at, op := l0.op, left = nc, right = sc)
                }
                unsafe {
                    delete rests
                }
            }
        }
    }
    
    if (no_fast_math) return null
    var laneC : array<float>
    var laneV : array<float>
    var laneE : array<ExpressionPtr>
    for (i in range(d)) {
        var cv = 0.0
        if (scalar_float_const(that.arguments[i], cv)) {
            laneC |> push(0.0)
            laneV |> push(cv)
            laneE |> push(null)
            continue
        }
        var ci = 1.0
        var ei = that.arguments[i]
        if (that.arguments[i] is ExprOp2) {
            var li = that.arguments[i] as ExprOp2
            if (li.op == "*") {
                if (scalar_float_const(li.right, cv) && !(li.left |> is_expr_const())) {
                    ci = cv
                    ei = li.left
                } elif (scalar_float_const(li.left, cv) && !(li.right |> is_expr_const())) {
                    ci = cv
                    ei = li.right
                }
            }
        }
        laneC |> push(ci)
        laneV |> push(0.0)
        laneE |> push(ei)
    }
    var bestC = 0.0
    var bestN = 0
    for (i in range(d)) {
        if (laneE[i] == null || laneC[i] == 1.0 || laneC[i] == 0.0) {
            continue
        }
        var n = 0
        for (j in range(d)) {
            if (laneE[j] != null && laneC[j] == laneC[i]) {
                n ++
            }
        }
        if (n > bestN) {
            bestN = n
            bestC = laneC[i]
        }
    }
    if (bestN < 2) {
        delete laneC
        delete laneV
        unsafe {
            delete laneE
        }
        return null
    }
    var before = 0
    var after = 1
    for (i in range(d)) {
        if (laneE[i] != null && laneC[i] != 1.0) {
            before ++
        }
        if (laneE[i] != null && laneC[i] != bestC) {
            after ++
        }
    }
    if (after >= before) {
        delete laneC
        delete laneV
        unsafe {
            delete laneE
        }
        return null
    }
    var lanes : array<ExpressionPtr>
    for (i in range(d)) {
        if (laneE[i] == null) {
            lanes |> push(new ExprConstFloat(at = that.at, value = laneV[i] / bestC))
        } elif (laneC[i] == bestC) {
            lanes |> push(clone_expression(laneE[i]))
        } else {
            var comp : ExpressionPtr = new ExprConstFloat(at = that.at, value = laneC[i] / bestC)
            lanes |> push(new ExprOp2(at = that.at, op := "*", left = clone_expression(laneE[i]), right = comp))
        }
    }
    var nc = make_float_ctor(d, that.at, lanes)
    delete laneC
    delete laneV
    unsafe {
        delete lanes
        delete laneE
    }
    return new ExprOp2(at = that.at, op := "*", left = nc, right = new ExprConstFloat(at = that.at, value = bestC))
}





def private float_vec_dim(bt : Type) : int {
    if (bt == Type.tFloat2) return 2
    if (bt == Type.tFloat3) return 3
    if (bt == Type.tFloat4) return 4
    return 0
}

def private lane_index(comp : string) : int {
    if (comp == "x") return 0
    if (comp == "y") return 1
    if (comp == "z") return 2
    return 3
}

struct private DotGroup {
    base : ExpressionPtr        
    dim : int
    weights : float4
    nterms : int
}


def private dot_term_lane(var e : ExpressionPtr; var baseKey : string&; var base : ExpressionPtr&;
                          var lane : int&; var w : float&) : bool {
    var comp = ""
    if (component_read_of(e, baseKey, base, comp)) {
        lane = lane_index(comp)
        w = 1.0
        return true
    }
    var l, r : ExpressionPtr
    if (!qmatch(e, $e(l) * $e(r)).matched) return false    
    var c = 0.0
    if (scalar_float_const(r, c) && component_read_of(l, baseKey, base, comp)) {
        lane = lane_index(comp)
        w = c
        return true
    }
    if (scalar_float_const(l, c) && component_read_of(r, baseKey, base, comp)) {
        lane = lane_index(comp)
        w = c
        return true
    }
    return false
}




def private dot_chain_groups(var terms : array<ReTerm>; var groups : table<string; DotGroup>;
                             var tKey : array<string>) : bool {
    tKey |> resize(length(terms))
    for (i in range(length(terms))) {
        var baseKey = ""
        var base : ExpressionPtr
        var lane = 0
        var w = 0.0
        if (!dot_term_lane(terms[i].e, baseKey, base, lane, w)) {
            continue
        }
        tKey[i] = baseKey
        if (terms[i].neg) {
            w = -w
        }
        if (!key_exists(groups, baseKey)) {
            groups[baseKey] = DotGroup(base = base, dim = float_vec_dim(expr_bt(base)))
        }
        groups[baseKey].weights[lane] += w
        groups[baseKey].nterms ++
    }
    var any = false
    for (g in values(groups)) {
        if (g.nterms >= 2) {
            any = true
        }
    }
    return any
}

def private has_unfused_lane_dot(var that : ExprOp2?) : bool {
    if (that == null || !(that.op == "+" || that.op == "-") || expr_bt(that) != Type.tFloat) return false
    var terms : array<ReTerm>
    collect_add(that, false, terms)
    var groups : table<string; DotGroup>
    var tKey : array<string>
    let any = dot_chain_groups(terms, groups, tKey)
    unsafe {
        delete terms
        delete groups
    }
    delete tKey
    return any
}




def private dot_fold_chain(var that : ExpressionPtr; var terms : array<ReTerm>) : ExpressionPtr {
    var groups : table<string; DotGroup>
    var tKey : array<string>
    if (!dot_chain_groups(terms, groups, tKey)) {
        unsafe {
            delete groups
        }
        delete tKey
        return null
    }
    var emitted : table<string>
    var newTerms : array<ReTerm>
    for (i in range(length(terms))) {
        let k = tKey[i]
        if (k == "") {
            newTerms |> push(terms[i])
            continue
        }
        var g = groups?[k] ?? default<DotGroup>
        if (g.nterms < 2) {
            newTerms |> push(terms[i])
            continue
        }
        if (key_exists(emitted, k)) {
            continue
        }
        emitted |> insert(k)
        var lanes : array<ExpressionPtr>
        lanes |> reserve(g.dim)
        for (li in range(g.dim)) {
            lanes |> push(new ExprConstFloat(at = that.at, value = g.weights[li]))
        }
        var cll = new ExprCall(at = that.at, name := "dot")
        emplace(cll.arguments, g.base)
        var mask = make_float_ctor(g.dim, that.at, lanes)
        emplace(cll.arguments, mask)
        newTerms |> push(ReTerm(neg = false, e = cll))
        unsafe {
            delete lanes
        }
    }
    var r = build_chain(newTerms, that.at, "+", "-")
    unsafe {
        delete groups
        delete newTerms
    }
    delete tKey
    delete emitted
    return r
}




def private dot_fold_expr(var e : ExpressionPtr; var changed : bool&) : ExpressionPtr {
    if (e == null) return null
    if (e is ExprOp2) {
        var o = e as ExprOp2
        if ((o.op == "+" || o.op == "-") && expr_bt(o) == Type.tFloat) {
            var terms : array<ReTerm>
            collect_add(e, false, terms)
            for (t in terms) {
                
                dot_fold_expr(t.e, changed)
            }
            var r = dot_fold_chain(e, terms)
            unsafe {
                delete terms
            }
            if (r != null) {
                changed = true
                return r
            }
            return e
        }
        o.left = dot_fold_expr(o.left, changed)
        o.right = dot_fold_expr(o.right, changed)
    } elif (e is ExprOp1) {
        var o = e as ExprOp1
        o.subexpr = dot_fold_expr(o.subexpr, changed)
    } elif (e is ExprOp3) {
        var o = e as ExprOp3
        o.subexpr = dot_fold_expr(o.subexpr, changed)
        o.left = dot_fold_expr(o.left, changed)
        o.right = dot_fold_expr(o.right, changed)
    } elif (e is ExprCall) {
        var c = e as ExprCall
        for (i in range(length(c.arguments))) {
            c.arguments[i] = dot_fold_expr(c.arguments[i], changed)
        }
    } elif (e is ExprField) {
        var o = e as ExprField
        o.value = dot_fold_expr(o.value, changed)
    } elif (e is ExprSwizzle) {
        var o = e as ExprSwizzle
        o.value = dot_fold_expr(o.value, changed)
    } elif (e is ExprRef2Value) {
        var o = e as ExprRef2Value
        o.subexpr = dot_fold_expr(o.subexpr, changed)
    } elif (e is ExprCast) {
        var o = e as ExprCast
        o.subexpr = dot_fold_expr(o.subexpr, changed)
    } elif (e is ExprPtr2Ref) {
        var o = e as ExprPtr2Ref
        o.subexpr = dot_fold_expr(o.subexpr, changed)
    } elif (e is ExprAt) {
        var o = e as ExprAt
        o.subexpr = dot_fold_expr(o.subexpr, changed)
        o.index = dot_fold_expr(o.index, changed)
    } elif (e is ExprMakeTuple) {
        var o = e as ExprMakeTuple
        for (vi in range(length(o.values))) {
            o.values[vi] = dot_fold_expr(o.values[vi], changed)
        }
    } elif (e is ExprMakeStruct) {
        var ms = e as ExprMakeStruct
        for (si in range(length(ms.structs))) {
            for (fld in *(ms.structs[si])) {
                fld.value = dot_fold_expr(fld.value, changed)
            }
        }
    }
    return e
}

def private dot_fold_stmt(var s : ExpressionPtr; var changed : bool&) {
    if (s is ExprLet) {
        var lc = s as ExprLet
        for (lv in lc.variables) {
            if (lv.init != null) {
                lv.init = dot_fold_expr(lv.init, changed)
            }
        }
    } elif (s is ExprCopy) {
        var cp = s as ExprCopy
        cp.right = dot_fold_expr(cp.right, changed)
    } elif (s is ExprReturn) {
        var rt = s as ExprReturn
        if (rt.subexpr != null) {
            rt.subexpr = dot_fold_expr(rt.subexpr, changed)
        }
    }
}

class private CtorFuseVisitor : AstVisitor {
    changed : bool
    noFastMath : bool
    def override visitExprCall(var that : ExprCall?) : ExpressionPtr {
        var r = ctor_fuse_rewrite(that, noFastMath)
        if (r != null) {
            changed = true
            return r
        }
        return that
    }
}

class private MadFuseVisitor : AstVisitor {
    changed : bool
    def override visitExprOp2(var that : ExprOp2?) : ExpressionPtr {
        var ma : ExpressionPtr
        var mb : ExpressionPtr
        var mc : ExpressionPtr
        if (match_mad(that, ma, mb, mc)) {
            changed = true
            var cll = new ExprCall(at = that.at, name := "mad")
            emplace(cll.arguments, ma)
            emplace(cll.arguments, mb)
            emplace(cll.arguments, mc)
            return cll
        }
        var pos : ExpressionPtr
        var neg : ExpressionPtr
        if (match_neg_add(that, pos, neg)) {
            changed = true
            return new ExprOp2(at = that.at, op := "-", left = pos, right = neg)
        }
        return that
    }
}

class private LerpFuseVisitor : AstVisitor {
    changed : bool
    def override visitExprCall(var that : ExprCall?) : ExpressionPtr {
        var la : ExpressionPtr
        var lb : ExpressionPtr
        var lt : ExpressionPtr
        if (match_lerp(that, la, lb, lt)) {
            changed = true
            var cll = new ExprCall(at = that.at, name := "lerp")
            emplace(cll.arguments, la)
            emplace(cll.arguments, lb)
            emplace(cll.arguments, lt)
            return cll
        }
        return that
    }
}



class private FuseResidualVisitor : AstVisitor {
    checkMad : bool
    checkLerp : bool
    checkDot : bool
    noFastMath : bool
    foundMad : bool
    foundLerp : bool
    foundNegAdd : bool
    foundCtor : bool
    foundDot : bool
    def override preVisitExprOp2(var expr : ExprOp2?) : void {
        if (checkDot && has_unfused_lane_dot(expr)) {
            foundDot = true
        }
        if (!checkMad) {
            return
        }
        var ma : ExpressionPtr
        var mb : ExpressionPtr
        var mc : ExpressionPtr
        if (match_mad(expr, ma, mb, mc)) {
            foundMad = true
        }
        var pos : ExpressionPtr
        var neg : ExpressionPtr
        if (match_neg_add(expr, pos, neg)) {
            foundNegAdd = true
        }
    }
    def override preVisitExprCall(var expr : ExprCall?) : void {
        if (checkLerp) {
            var la : ExpressionPtr
            var lb : ExpressionPtr
            var lt : ExpressionPtr
            if (match_lerp(expr, la, lb, lt)) {
                foundLerp = true
            }
        }
        if (ctor_fuse_rewrite(expr, noFastMath) != null) {
            foundCtor = true
        }
    }
}

def public fuse_body(var func : FunctionPtr; no_fast_math : bool = false) : bool {
    
    
    
    if (!(func.body is ExprBlock)) return false
    var changed = false
    
    if (!no_fast_math && fuse_callable(func._module, "dot", 2)) {
        var blk = func.body as ExprBlock
        var dchanged = false
        for (s in blk.list) {
            dot_fold_stmt(s, dchanged)
        }
        if (dchanged) {
            changed = true
        }
    }
    
    var cv = new CtorFuseVisitor()
    cv.noFastMath = no_fast_math
    make_visitor(*cv) $(adapter) {
        visit(func.body, adapter)
    }
    if (cv.changed) {
        changed = true
    }
    unsafe {
        delete cv
    }
    if (!fuse_callable(func._module, "mad")) return changed
    var v = new MadFuseVisitor()
    make_visitor(*v) $(adapter) {
        visit(func.body, adapter)
    }
    if (v.changed) {
        changed = true
    }
    unsafe {
        delete v
    }
    
    
    if (fuse_callable(func._module, "lerp")) {
        var lv = new LerpFuseVisitor()
        make_visitor(*lv) $(adapter) {
            visit(func.body, adapter)
        }
        if (lv.changed) {
            changed = true
        }
        unsafe {
            delete lv
        }
    }
    return changed
}
