from "%globalsDarg/darg_library.nut" import *
let { needDmViewerPointerControl, pointerScreenX, pointerScreenY } = require("%rGui/dmViewer/dmViewerState.nut")

let DEV_GAMEPAD = 3

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
    if ((evt.devId != devId || evt.btnId != btnId || evt.pointerId != pointerId)
      && evt.devId != DEV_GAMEPAD)
      return
    processorState.mutate(function(v) {
      v.x = evt.x
      v.y = evt.y
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