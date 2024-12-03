from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { fabs, sqrt, PI, atan2 } = require("%sqstd/math.nut")
let rand = require("%sqstd/rand.nut")()
let { gradRadial } = require("%rGui/style/gradients.nut")

let maxStartSpeedXMul = 0.5
let chanceToBeColored = 0.3
let sparkColor = 0x80F95927
let upstreamAcc = hdpx(20)
let viscosity = 0.1
let maxScaleBySpeed = 10.0
let maxSpeed = hdpxi(10000)

function fillNewForce(state, time, speedY) {
  state.accChangeTime <- time + (speedY == 0 ? 200 : max(100, (hdpx(50) / speedY * rand.rfloat(100, 100)).tointeger()))
  let randomAcc = rand.rfloat(- speedY * speedY / hdpx(100), speedY * speedY / hdpx(100))
  state.acc <- [randomAcc, randomAcc + upstreamAcc]
}

function initSparkState(state, halfSize, time, speedY, fill = false) {
  state.lastTime <- time
  state.isActive <- true
  let startY = fill ? rand.rfloat( - halfSize[1], halfSize[1]) : halfSize[1]
  state.pos <- [rand.rfloat(- halfSize[0], halfSize[0]), startY]
  state.speed <- [rand.rfloat(- maxStartSpeedXMul * speedY, maxStartSpeedXMul * speedY), speedY]
  fillNewForce(state, time, speedY)
}

function updateSparkState(state, time) {
  let { pos, speed, lastTime, accChangeTime, acc } = state
  let dt = 0.001 * (time - lastTime)
  state.pos = pos.map(@(v, i) v - speed[i] * dt)
  state.speed = speed.map(@(v, i) clamp(v + (acc[i] - v * viscosity) * dt, -maxSpeed, maxSpeed))
  state.lastTime = time
  if (accChangeTime <= time)
    fillNewForce(state, time, speed[1])
}

let length = @(arr) sqrt(arr[0] * arr[0] + arr[1] * arr[1])

let mkGlow = @(size, color, opacity) {
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = gradRadial
  opacity = opacity * 0.7
  color
  transform = {
    scale = [2.5, 1.0]
  }
}

function updateParticles(state, halfSize, particleSize, speedY, scaleBySpeed, opacity) {
  let { isActive = false, startTime = -1 } = state
  let time = get_time_msec()

  if (startTime >= time)
    return null

  if (!isActive) {
    initSparkState(state, halfSize, time, speedY)
    return { opacity = 0.0 }
  }
  else
    updateSparkState(state, time)

  let { pos, speed } = state
  let moveScale = min(maxScaleBySpeed, 1 + scaleBySpeed / hdpx(200) * length(speed))
  let maxOfs = moveScale * particleSize
  let isOutsideTheFrame = fabs(pos[0]) > halfSize[0] + maxOfs || fabs(pos[1]) > halfSize[1] + maxOfs

  if (isOutsideTheFrame) {
    state.isActive <- false
    return { opacity = 0.0 }
  }

  return {
    opacity
    transform = {
      translate = pos
      rotate = -180.0 / PI * atan2(speed[0], speed[1])
      scale = [1, moveScale]
    }
  }
}

function mkSparks(state, halfSize) {
  let particleSize = rand.rfloat(hdpx(4), hdpx(5))
  let speedY = rand.rfloat(hdpx(300), hdpx(350))
  let opacity = rand.rfloat(0.5, 0.9)
  let scaleBySpeed = 2.5
  let color = sparkColor

  return {
    size = [particleSize, particleSize]
    rendObj = ROBJ_IMAGE
    image = gradRadial
    opacity = 0.0
    transform = {}
    color
    onAttach = @() initSparkState(state, halfSize, get_time_msec(), speedY, true)
    behavior = Behaviors.RtPropUpdate
    update = @() updateParticles(state, halfSize, particleSize, speedY, scaleBySpeed, opacity)
    children = mkGlow(particleSize, color, opacity)
  }
}

function mkAshes(state, halfSize) {
  let particleSize = rand.rfloat(hdpx(8), hdpx(12))
  let speedY = rand.rfloat(hdpx(60), hdpx(80))
  let opacity = rand.rfloat(0.1, 0.7)
  let scaleBySpeed = 0
  let color = sparkColor

  return {
    size = [particleSize, particleSize]
    rendObj = ROBJ_IMAGE
    image = gradRadial
    opacity = 0.0
    transform = {}
    color = rand.rfloat(0, 1) < chanceToBeColored ? color : null
    onAttach = @() initSparkState(state, halfSize, get_time_msec(), speedY, true)
    behavior = Behaviors.RtPropUpdate
    update = @() updateParticles(state, halfSize, particleSize, speedY, scaleBySpeed, opacity)
  }
}

function mkFireParticles(amount, effectSize, ctor) {
  let halfSize = effectSize.map(@(v) 0.5 * v)
  local list = array(amount)

  return {
    size = effectSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = true
    children = list.map(@(_)
      ctor({}, halfSize))
  }
}

return {
  mkFireParticles
  mkSparks
  mkAshes
}
