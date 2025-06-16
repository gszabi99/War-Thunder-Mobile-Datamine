from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")


let defaultArrowSize = evenPx(30)
let defaultExpandAnimationDuration = 0.3

function mkArrowImageComp(isExpanded, duration, lengthPx, ovr) {
  let h = round(lengthPx).tointeger()
  let w = round(h / 2.0 / 24 * 40).tointeger() * 2
  return @() {
    watch = isExpanded,
    size = [w, h]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#scroll_arrow.svg:{w}:{h}:P")
    color = 0xFFFFFFFF
    transform = {rotate = !isExpanded.get()? 0 : 180}
    transitions = [{
      prop = AnimProp.rotate
      from = 0
      to = 180
      duration
    }]
  }.__update(ovr)
}

let expandArrow = @(isExpanded, duration = defaultExpandAnimationDuration, size = defaultArrowSize, ovr = {})
  mkArrowImageComp(isExpanded, duration, size, ovr)


return {
  expandArrow

  defaultExpandAnimationDuration
}
