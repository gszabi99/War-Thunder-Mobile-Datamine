from "%globalsDarg/darg_library.nut" import *
let { hoverColor, textColor } = require("%rGui/style/stdColors.nut")

let mkIconBtn = @(path, size, stateFlags, color = textColor) @() {
  watch = stateFlags
  size = array(2, size)
  rendObj = ROBJ_IMAGE
  image = Picture($"{path}:{size}:{size}:P")
  color = stateFlags.get() & S_HOVER ? hoverColor : color
  transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
  transitions = [{ prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }]
}

return mkIconBtn
