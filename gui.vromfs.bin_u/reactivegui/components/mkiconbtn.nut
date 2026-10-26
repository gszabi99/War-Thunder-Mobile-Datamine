from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/stdColors.nut" import hoverColor, textColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale


let mkIconBtn = @(path, size, stateFlags = Watched(0), color = textColor) @() {
  watch = stateFlags
  size = size
  rendObj = ROBJ_IMAGE
  image = Picture($"{path}:{size}:{size}:P")
  color = stateFlags.get() & S_HOVER ? hoverColor : color
  ...mkPressTransitionScale(stateFlags.get(), 0.9)
}

return mkIconBtn
