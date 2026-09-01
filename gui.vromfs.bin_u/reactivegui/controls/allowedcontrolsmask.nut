from "%globalScripts/sharedEnums.nut" import CtrlsInGui
from "controlsMask" import setAllowedControlsMask
from "%globalsDarg/darg_library.nut" import *

let masksList = Watched({})

let addControlsMask = @(id, mask) masksList.mutate(@(v) v[id] <- mask)

function removeControlsMask(id) {
  if (id in masksList.get())
    masksList.mutate(@(v) v.rawdelete(id))
}

let reduceMask = @(res, mask) (res & mask) | (CtrlsInGui.CTRL_WINDOWS_ALL & (res | mask))
let allowedControlsMask = keepref(Computed(@() masksList.get().reduce(reduceMask, CtrlsInGui.CTRL_ALLOW_FULL)))

setAllowedControlsMask(allowedControlsMask.get())
allowedControlsMask.subscribe(setAllowedControlsMask)

return {
  addControlsMask
  removeControlsMask
}
