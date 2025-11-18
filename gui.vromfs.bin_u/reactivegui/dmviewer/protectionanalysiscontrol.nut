from "%globalsDarg/darg_library.nut" import *
from "math" import abs, clamp, pow, sqrt
from "dagor.time" import get_time_msec
from "wt.behaviors" import HangarCameraControl
from "%appGlobals/activeControls.nut" import needCursorForActiveInputDevice
from "%rGui/cursor.nut" import needShowCursor
from "%rGui/dmViewer/protectionAnalysisState.nut" import targetScreenX, targetScreenY, doFire

let DEV_ID_MOUSE = 2
let DEV_ID_GAMEPAD = 3
let DEV_ID_MOUSE_KEY = 4
let MOUSE_DRAG_THRESHOLD_PX = hdpx(2)
let TAP_THRESHOLD_PX = hdpx(64)
let SHORT_TAP_MSEC = 300

let halfScreenW = sw(50)

let defProcessorState = {
  devId = null
  pointerId = null
  btnId = null
  canDrag = true
  pressTime = 0
  maxMoveDist = 0
  tx = 0
  ty = 0
  x0 = 0
  y0 = 0
  x = 0
  y = 0
}

function mkTargetingControlLayer() {
  let processorState = Watched(clone defProcessorState)

  function onPointerPress(evt) {
    if (evt.accumRes & R_PROCESSED)
      return 0
    if (!evt.hit)
      return 0
    if (processorState.get().devId != null)
      return 0
    let { x, y } = evt
    processorState.set(defProcessorState.__merge({
      devId = evt.devId
      pointerId = evt.pointerId
      btnId = evt.btnId
      canDrag = needCursorForActiveInputDevice.get() || x >= halfScreenW
      pressTime = get_time_msec()
      tx = targetScreenX.get()
      ty = targetScreenY.get()
      x0 = x
      y0 = y
      x
      y
    }))
    return 0 
  }

  function onPointerRelease(evt) {
    let { devId, pointerId, btnId, pressTime, maxMoveDist } = processorState.get()
    if (evt.devId != devId || evt.pointerId != pointerId || evt.btnId != btnId)
      return 0
    processorState.set(clone defProcessorState)
    if (!needCursorForActiveInputDevice.get()
        && get_time_msec() - pressTime <= SHORT_TAP_MSEC && maxMoveDist <= TAP_THRESHOLD_PX) {
      targetScreenX.set(evt.x)
      targetScreenY.set(evt.y)
    }
    else if (evt.devId == DEV_ID_MOUSE_KEY && maxMoveDist <= MOUSE_DRAG_THRESHOLD_PX)
      doFire()
    return 0 
  }

  function onPointerMove(evt) {
    let { devId, pointerId, btnId } = processorState.get()
    let { x, y } = evt
    if (evt.devId == DEV_ID_GAMEPAD || evt.devId == DEV_ID_MOUSE) {
      targetScreenX.set(x)
      targetScreenY.set(y)
      return
    }

    if (evt.devId != devId || evt.pointerId != pointerId || evt.btnId != btnId)
      return
    processorState.mutate(function(v) {
      v.x = x
      v.y = y
      v.maxMoveDist = max(v.maxMoveDist, sqrt(pow(abs(v.x - v.x0), 2) + pow(abs(v.y - v.y0), 2)))
    })
  }

  processorState.subscribe(function(v) {
    if (v.devId != null && v.canDrag) {
      targetScreenX.set(clamp(v.tx - v.x0 + v.x, 0, sw(100) - 1))
      targetScreenY.set(clamp(v.ty - v.y0 + v.y, 0, sh(100) - 1))
    }
  })

  return {
    size = flex()
    hplace = ALIGN_RIGHT
    behavior = Behaviors.ProcessPointingInput
    onPointerPress
    onPointerRelease
    onPointerMove
    onDetach = @() processorState.set(clone defProcessorState)
  }
}

let invisibleCursor = Cursor({})
let cursorHidingLayer = @() {
  watch = needShowCursor
  size = flex()
  cursor = needShowCursor.get() ? invisibleCursor : null
}

let cameraControlLayer = @() {
  watch = needCursorForActiveInputDevice
  size = needCursorForActiveInputDevice.get() ? flex() : [sw(50), flex()]
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
}

return {
  size = flex()
  children = [
    cursorHidingLayer
    cameraControlLayer
    mkTargetingControlLayer()
  ]
}
