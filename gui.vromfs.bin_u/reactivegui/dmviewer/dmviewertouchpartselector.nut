from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/activeControls.nut" import needCursorForActiveInputDevice
from "%rGui/dmViewer/dmViewerState.nut" import needDmViewerPointerControl, pointerScreenX, pointerScreenY

let DEV_ID_MOUSE = 2
let DEV_ID_GAMEPAD = 3

let defProcessorState = {
  devId = null
  btnId = null
  pointerId = null
  x = 0
  y = 0
}

function dmViewerTouchPartSelector() {
  let res = {
    watch = needDmViewerPointerControl
  }
  if (!needDmViewerPointerControl.get())
    return res

  let processorState = Watched(clone defProcessorState)

  function onPointerPress(evt) {
    if (needCursorForActiveInputDevice.get())
      return 0
    if (evt.accumRes & R_PROCESSED)
      return 0
    if (!evt.hit)
      return 0
    if (processorState.get().devId != null)
      return 0
    let { x, y, devId, btnId, pointerId } = evt
    processorState.set(defProcessorState.__merge({
      devId
      btnId
      pointerId
      x
      y
    }))
    return 0 
  }

  function onPointerRelease(evt) {
    if (needCursorForActiveInputDevice.get())
      return 0
    let { x, y, devId, btnId, pointerId } = processorState.get()
    if (evt.devId != devId || evt.btnId != btnId || evt.pointerId != pointerId)
      return 0
    pointerScreenX.set(x)
    pointerScreenY.set(y)
    processorState.set(clone defProcessorState)
    return 0 
  }

  function onPointerMove(evt) {
    let { devId, btnId, pointerId } = processorState.get()
    let { x, y } = evt
    if (evt.devId == DEV_ID_GAMEPAD || evt.devId == DEV_ID_MOUSE) {
      pointerScreenX.set(x)
      pointerScreenY.set(y)
      return
    }
    if (evt.devId != devId || evt.btnId != btnId || evt.pointerId != pointerId)
      return
    processorState.mutate(function(v) {
      v.x = x
      v.y = y
    })
  }

  function reset() {
    processorState.set(clone defProcessorState)
    pointerScreenX.set(0)
    pointerScreenY.set(0)
  }

  processorState.subscribe(function(v) {
    if (v.devId == null)
      return
    pointerScreenX.set(v.x)
    pointerScreenY.set(v.y)
  })

  return res.__update({
    key = {}
    size = flex()
    behavior = Behaviors.ProcessPointingInput
    onPointerPress
    onPointerRelease
    onPointerMove
    onAttach = reset
    onDetach = reset
  })
}

return dmViewerTouchPartSelector