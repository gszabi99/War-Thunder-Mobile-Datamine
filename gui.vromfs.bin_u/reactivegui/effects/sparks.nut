from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { fabs, sin, cos, PI, acos, lerp } = require("%sqstd/math.nut")
let rand = require("%sqstd/rand.nut")()
let { mkRingGradientLazy } = require("%rGui/style/gradients.nut")

let sparkImage = mkRingGradientLazy(30, 5, 50000)
let sparkMaxSize = [hdpx(5), hdpx(20)]
let sparkMinSpeed = hdpx(20)
let sparkMaxSpeed = hdpx(60)

function roundZoneInitPos(halfSize) {
  let x = rand.rfloat(-halfSize[0], halfSize[0])
  let y = halfSize[1] * sin(acos(x / halfSize[0]))
  return [ x, rand.rfloat(-y, y) ]
}

function roundZoneStartPos(halfSize) {
  let angle = rand.rfloat(0.0, PI)
  let radius = rand.rfloat(0.8, 1.0)
  return [ radius * halfSize[0] * cos(angle), radius * halfSize[1] * sin(angle) ]
}

let roundZoneMaxEndPosY = @(startPos, halfSize) - halfSize[1] * sin(acos(startPos[0] / halfSize[0]))

function fillRoundZoneSparkState(state, effectHalfSize, showTime = 100) {
  let minY = roundZoneMaxEndPosY(state.startPos, effectHalfSize)
  let distance = effectHalfSize[1] * rand.rfloat(0.2, 3)
  state.endPos <- [state.startPos[0], max(state.startPos[1] - distance, minY)]
  let speed = rand.rfloat(sparkMinSpeed, sparkMaxSpeed)
  state.endTime <- state.startTime + (1000 * fabs(state.startPos[1] - state.endPos[1]) / speed).tointeger()
  state.showTime <- state.startTime + showTime
  state.hideTime <- state.endTime - 100
  state.scale <- array(2, rand.rfloat(0.3, 1.0))
}

let mkRoundZoneSpark = @(state, effectHalfSize) {
  size = sparkMaxSize
  rendObj = ROBJ_IMAGE
  image = sparkImage()
  color = 0xFFFDFFAC
  opacity = 0.0
  behavior = Behaviors.RtPropUpdate
  transform = {}
  function update() {
    let time = get_time_msec()
    if ("startTime" not in state) {  
      let { initDelay = 0.0 } = state
      state.startTime <- time + (1000 * initDelay).tointeger()
      state.startPos <- roundZoneInitPos(effectHalfSize)
      fillRoundZoneSparkState(state, effectHalfSize, initDelay == 0 ? 100 : 1000)
    }
    if (state.endTime <= time) { 
      state.startTime <- time
      state.startPos <- roundZoneStartPos(effectHalfSize)
      fillRoundZoneSparkState(state, effectHalfSize)
    }
    if (state.startTime >= time)
      return { opacity = 0.0, transform = { scale = state.scale } }
    let { startPos, endPos, startTime, endTime, showTime, hideTime } = state
    return {
      opacity = time < showTime ? lerp(startTime, showTime, 0.0, 1.0, time)
        : time > hideTime ? lerp(hideTime, endTime, 1.0, 0.0, time)
        : 1.0
      transform = {
        translate = [startPos[0], lerp(startTime, endTime, startPos[1], endPos[1], time)]
      }
    }
  }
}

let mkSparks = kwarg(function(size, delay = 0.0, count = 50, sparkCtor = mkRoundZoneSpark) {
  let halfSize = size.map(@(v) 0.5 * v)
  local list = array(count).map(@(_) { initDelay = delay })
  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    function onAttach() {
      foreach (state in list) {
        state.clear()
        state.initDelay <- delay
      }
    }
    children = list.map(@(state) sparkCtor(state, halfSize))
  }
})

return {
  mkSparks
}