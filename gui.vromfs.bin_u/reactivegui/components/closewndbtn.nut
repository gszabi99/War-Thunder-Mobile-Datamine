from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale

let closeWndBtnSize = evenPx(40)
let margin = closeWndBtnSize / 2
let lineWidth = evenPx(6)
let l = 50.0 * lineWidth / closeWndBtnSize
let r = 100.0 - l
let btnBase = {
  size = closeWndBtnSize
  margin
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth
  commands = [
    [VECTOR_LINE, l, l, r, r],
    [VECTOR_LINE, l, r, r, l],
  ]
  behavior = Behaviors.Button
  sound = { click  = "click" }
}

function closeWndBtn(onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() btnBase.__merge({
    watch = stateFlags
    color = stateFlags.get() & S_HOVER ? 0xFFFFFFFF : 0xFF808080
    onElemState = @(sf) stateFlags.set(sf)
    onClick,
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
    ...override
  })
}

return {
  closeWndBtn
  closeWndBtnSize
}