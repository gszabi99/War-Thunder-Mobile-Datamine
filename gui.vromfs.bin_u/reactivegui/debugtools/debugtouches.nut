from "%globalsDarg/darg_library.nut" import *
let { OPT_SHOW_TOUCHES_ENABLED, getOptValue } = require("%rGui/options/guiOptions.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

let isDebugTouchesActive = hardPersistWatched("isDebugTouchesActive",
  getOptValue(OPT_SHOW_TOUCHES_ENABLED) ?? false)
let activePointers = Watched({})
let pointerPos = {}

let pointerView = {
  size = [hdpx(50), hdpx(50)]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(4)
  color = 0x80000000
  fillColor = 0x80405380
  commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  animations = [
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.5, easing = OutQuad, playFadeOut = true }
  ]
}

let mkPointer = @(id) {
  size = [0, 0]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = pointerView
  behavior = Behaviors.RtPropUpdate
  transform = { translate = pointerPos?[id] }
  update = @() { transform = { translate = pointerPos?[id] } }
}

let debugTouchesView = @() {
  watch = activePointers
  children = activePointers.value.keys()
    .map(mkPointer)
}

let debugTouchesHandlerComp = {
  key = {}
  size = flex()
  behavior = Behaviors.ProcessPointingInput
  touchMarginPriority = TOUCH_BACKGROUND
  function onPointerPress(evt) {
    let { pointerId, x, y } = evt
    pointerPos[pointerId] <- [x, y]
    activePointers.mutate(@(v) v[pointerId] <- true)
    return 0
  }
  function onPointerRelease(evt) {
    let { pointerId } = evt
    if (pointerId in activePointers.value)
      activePointers.mutate(@(v) v.$rawdelete(pointerId))
    return 0
  }
  function onPointerMove(evt) {
    let { pointerId, x, y } = evt
    pointerPos[pointerId] <- [x, y]
    return 0
  }
  onDetach = @() activePointers({})
}

let debugTouchesUi = {
  key = {}
  size = flex()
  waitForChildrenFadeOut = true
  children = debugTouchesView
}

return {
  isDebugTouchesActive
  debugTouchesHandlerComp
  debugTouchesUi
}