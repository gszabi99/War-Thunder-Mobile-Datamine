from "%globalsDarg/darg_library.nut" import *

let defHeight = hdpx(50)
let spinnerOpacityAnim = { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, easing = InQuad, play = true }
let animations = freeze([
  spinnerOpacityAnim
  { prop = AnimProp.rotate, from = 0, to = 360, duration = 3.0, play = true, loop = true }
])

let defSpinnerKey = {}
let function mkSpinner(height = defHeight, override = {}) {
  let htInt = height.tointeger()
  return {
    key = defSpinnerKey
    size = [htInt, htInt]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#throbber.svg:{htInt}:{htInt}")
    color = 0xFFFFFFFF
    transform = {}
    animations
  }.__update(override)
}

let function mkSpinnerHideBlock(watch, content, blockOvr = {}, spinner = null) {
  if (spinner == null)
    spinner = mkSpinner()
  return @() {
    watch
    children = watch.value ? spinner : content
  }.__update(blockOvr)
}

return {
  spinner = mkSpinner()
  mkSpinner
  mkSpinnerHideBlock
  spinnerOpacityAnim
}