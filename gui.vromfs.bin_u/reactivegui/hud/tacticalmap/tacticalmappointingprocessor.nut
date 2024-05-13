from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")

const SHORT_TAP_MSEC = 300
const DEV_GAMEPAD = 3

let defProcessorState = {
  pressTime = -1
  devId = null
  pointerId = null
  btnId = null
  targetW = null
  targetH = null
  mc = null
  x0 = 0
  y0 = 0
  x = 0
  y = 0
}

function mkTacticalMapPointingInputProcessor(mapCoords) {
  let processorState = Watched(clone defProcessorState)

  function onPointerPress(evt) {
    if (evt.accumRes & R_PROCESSED)
      return 0
    if (!evt.hit)
      return 0
    if (processorState.get().devId != null)
      return 0
    let x = evt.x - evt.target.getScreenPosX()
    let y = evt.y - evt.target.getScreenPosY()
    processorState.set(defProcessorState.__merge({
      pressTime = get_time_msec()
      devId = evt.devId
      pointerId = evt.pointerId
      btnId = evt.btnId
      targetW = evt.target.getWidth()
      targetH = evt.target.getHeight()
      mc = mapCoords.get()
      x0 = x
      y0 = y
      x
      y
    }))
    return R_PROCESSED
  }

  function onPointerRelease(evt) {
    let { devId, pointerId, btnId, pressTime, x, y, targetW, targetH } = processorState.get()
    if (evt.devId != devId || evt.pointerId != pointerId || evt.btnId != btnId)
      return 0
    if (get_time_msec() - pressTime <= SHORT_TAP_MSEC)
      mapCoords.set([
        clamp(x.tofloat() / targetW, 0.0, 1.0),
        clamp(y.tofloat() / targetH, 0.0, 1.0),
      ])
    processorState.set(clone defProcessorState)
    return R_PROCESSED
  }

  function onPointerMove(evt) {
    let { devId, pointerId, btnId } = processorState.get()
    let { target, x, y } = evt
    if (evt.devId == DEV_GAMEPAD) {
      let xs = x - target.getScreenPosX()
      let ys = y - target.getScreenPosY()
      mapCoords.set([
        clamp(xs.tofloat() / target.getWidth(), 0.0, 1.0),
        clamp(ys.tofloat() / target.getHeight(), 0.0, 1.0),
      ])
      return
    }

    if (evt.devId != devId || evt.pointerId != pointerId || evt.btnId != btnId)
      return
    processorState.mutate(function(v) {
      v.x = x - target.getScreenPosX()
      v.y = y - target.getScreenPosY()
    })
  }

  processorState.subscribe(function(v) {
    if (v.devId != null)
      mapCoords.set([
        clamp(v.mc[0] + 1.0 * (v.x - v.x0) / v.targetW, 0.0, 1.0),
        clamp(v.mc[1] + 1.0 * (v.y - v.y0) / v.targetH, 0.0, 1.0),
      ])
  })

  return {
    key = {}
    size = flex()
    behavior = Behaviors.ProcessPointingInput
    onPointerPress
    onPointerRelease
    onPointerMove
    onDetach = @() processorState.set(clone defProcessorState)
  }
}

return mkTacticalMapPointingInputProcessor
