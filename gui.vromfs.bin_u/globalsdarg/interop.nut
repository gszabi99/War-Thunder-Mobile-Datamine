from "reactiveInterop" import set_interop_table
from "types" import String




let interop = {}
set_interop_table(interop)

function registerInteropFunc(name, obj){
  assert(name instanceof String)
  assert(name not in interop)
  interop[name] <- obj
}

return {
  registerInteropFunc
}
