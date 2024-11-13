from "%globalsDarg/darg_library.nut" import *
let logO = log_with_prefix("[DbgOverlay] ")

let WND_PARAMS = {
  key = null //generate automatically when not set
  size = flex()
  stopMouse = true
  stopHotkeys = true
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  children = null
}

let dbgOverlayWindows = []
let genIdx = Watched(0)

function removeDbgOverlay(key) {
  let idx = dbgOverlayWindows.findindex(@(w) w.key == key)
  if (idx == null)
    return false
  dbgOverlayWindows.remove(idx)
  genIdx.set(genIdx.get() + 1)
  logO("Remove window ", key)
  return true
}

local lastOverlayIdx = 0
function addDbgOverlay(wnd = {}) {
  wnd = WND_PARAMS.__merge(wnd)
  if (wnd.key != null)
    removeDbgOverlay(wnd.key)
  else {
    lastOverlayIdx++
    wnd.key = $"overlay_wnd_{lastOverlayIdx}"
  }
  logO("Open window ", wnd.key)
  dbgOverlayWindows.append(wnd)
  genIdx.set(genIdx.get() + 1)
}

let dbgOverlayComponent = @() {
  watch = genIdx
  size = flex()
  children = dbgOverlayWindows
}

return {
  addDbgOverlay
  removeDbgOverlay
  dbgOverlayComponent
}
