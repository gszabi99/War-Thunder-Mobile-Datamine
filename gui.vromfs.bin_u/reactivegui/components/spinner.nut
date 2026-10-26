from "%globalsDarg/darg_library.nut" import *


const defSpinnerSize = hdpxi(50)

let spinnerOpacityAnim = { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, easing = InQuad, play = true }
let spinnerAnimations = freeze([
  spinnerOpacityAnim
  { prop = AnimProp.rotate, from = 0, to = 360, duration = 3.0, play = true, loop = true }
])

let defSpinnerKey = {}

function mkSpinner(size = defSpinnerSize, ovr = {}) {
  let sizeInt = size.tointeger()

  return {
    key = defSpinnerKey
    size = sizeInt
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#throbber.svg:{sizeInt}")
    color = 0xFFFFFFFF
    transform = {}
    animations = spinnerAnimations
  }.__update(ovr)
}

function mkSpinnerHideBlock(watch, content, blockOvr = {}, spinner = null) {
  let spinnerComp = spinner ?? mkSpinner()
  return @() {
    watch
    children = watch.get() ? spinnerComp : content
  }.__update(blockOvr)
}

let dimmingAppearAnimations = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.5, easing = InQuad, play = true }
]

let mkDimmingSpinner = @(spinnerSize = defSpinnerSize, ovr = {}) {
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = 0x80000000
      animations = dimmingAppearAnimations
    }
    mkSpinner(spinnerSize)
  ]
}.__update(ovr)

let mkWaitDimmingSpinner = @(watch, spinnerSize = hdpxi(100), ovr = {}) @() watch.get()
  ? mkDimmingSpinner(spinnerSize, { watch }.__update(ovr))
  : { watch }

let waitDimmingSpinner = mkDimmingSpinner()

return {
  spinner = mkSpinner()
  mkSpinner
  mkSpinnerHideBlock
  mkWaitDimmingSpinner
  waitDimmingSpinner
  spinnerOpacityAnim
}
