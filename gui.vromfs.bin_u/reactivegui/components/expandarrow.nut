from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")


let defaultExpandAnimationDuration = 0.3

let defArrowH = evenPx(30)
let defArrowW = round(defArrowH / 2.0 / 24 * 40).tointeger() * 2
let defaultArrowSize = [defArrowW, defArrowH]

function mkArrowImageComp(isExpanded, duration, size, ovr) {
  return @() {
    watch = isExpanded,
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#scroll_arrow.svg:{size[0]}:{size[1]}:P")
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
