from "%globalsDarg/darg_library.nut" import *
let { speed, portSideMachine, sideboardSideMachine } = require("%rGui/hud/shipState.nut")

const IS_STOPPED_STEP = 3

let machineSpeedLoc = [
  loc("HUD/ENGINE_REV_FULL_SHORT")
  loc("HUD/ENGINE_REV_TWO_THIRDS_SHORT")
  loc("HUD/ENGINE_REV_ONE_THIRD_SHORT")
  loc("HUD/ENGINE_REV_STOP_SHORT")
  loc("HUD/ENGINE_REV_ONE_THIRD_SHORT")
  loc("HUD/ENGINE_REV_TWO_THIRDS_SHORT")
  loc("HUD/ENGINE_REV_STANDARD_SHORT")
  loc("HUD/ENGINE_REV_FULL_SHORT")
  loc("HUD/ENGINE_REV_FLANK_SHORT")
  "1"
  "2"
  "R"
]

let machineSpeedDirection = [
  "back"
  "back"
  "back"
  "stop"
  "forward"
  "forward"
  "forward"
  "forward"
  "forward"
  "forward"
  "forward2"
  "back"
]

let defFont = fontVeryTiny

let speedValue = @(ovr = {}) @() {
  watch = speed
  rendObj = ROBJ_TEXT
  text = speed.value.tostring()
  margin = [0, 0, 0, sh(1)]
}.__update(defFont, ovr)

let speedUnits = @(ovr = {}) @() {
  rendObj = ROBJ_TEXT
  text = loc("measureUnits/kmh")
  margin = [0, 0, hdpx(1.5), sh(0.5)]
}.__update(defFont, ovr)

let averageSpeed = Computed(@() clamp((portSideMachine.value + sideboardSideMachine.value) / 2, 0, machineSpeedLoc.len()))

let isStoppedSpeedStep = Computed(@() averageSpeed.value == IS_STOPPED_STEP)

return {
  speedValue
  speedUnits
  averageSpeed
  isStoppedSpeedStep
  machineSpeedLoc
  machineSpeedDirection
}
