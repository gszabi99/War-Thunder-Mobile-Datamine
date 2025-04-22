
#allow-root-table
let { on_module_unload } = require("modules")

let interop = getroottable()["interop"]

function registerInteropFunc(name, obj){
  assert(type(name)=="string")
  assert(name not in interop)
  interop[name] <- obj
}

on_module_unload(@(_) interop.clear())

return {
  registerInteropFunc
}