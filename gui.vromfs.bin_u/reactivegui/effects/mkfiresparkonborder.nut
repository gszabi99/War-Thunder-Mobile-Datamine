from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { fabs, PI, atan2, sqrt } = require("%sqstd/math.nut")
let rand = require("%sqstd/rand.nut")()
let { gradRadial } = require("%rGui/style/gradients.nut")

let maxSize = hdpx(10)
let scaleBySpeed = 1.0 / hdpx(200)
let maxStartSpeed = hdpx(500)
let viscosity = 0.01
let windAcc = [-hdpx(400), 0]
let screenBorderAcc = hdpx(400)
let maxRndAcc = hdpx(1500)
let accMaxTime = 0.5
let maxInitDelay = 1.0

let function fillNewForce(state, time) {
  state.accChangeTime <- time + (accMaxTime * rand.rfloat(100, 1000)).tointeger()
  state.acc <- windAcc.map(@(v) v + rand.rfloat(-maxRndAcc, maxRndAcc))
  state.acc[1] += (state.pos[1] > 0 ? 1.0 : -1.0) * screenBorderAcc
}

let getRndPosWithCorner = @(maxVal, isInCorner)
  rand.rfloat(isInCorner ? 0.6 * maxVal : -maxVal, maxVal)

let function initSparkState(state, halfSize, time) {
  state.lastTime <- time
  if ("startTime" not in state) {
    state.startTime <- time + (1000 * rand.rfloat(0.0, maxInitDelay)).tointeger()
    state.lastTime <- state.startTime
  }

  state.isActive <- true
  state.scale <- rand.rfloat(0.3, 1.0)

  let sign = rand.rfloat(0.0, 1.0) > 0.3 ? 1 : -1
  let isInCorner = sign < 0 ? false : rand.rfloat(0.0, 1.0) > 0.5
  if (rand.rfloat(0, halfSize[0] + halfSize[1]) <= halfSize[0]) {
    state.pos <- [getRndPosWithCorner(halfSize[0], isInCorner), (halfSize[1] + 0.5 * maxSize) * sign]
    state.speed <- [0, rand.rfloat(0.5 * maxStartSpeed, maxStartSpeed) * -sign]
  }
  else {
    state.pos <- [(halfSize[0] + 0.5 * maxSize) * sign, getRndPosWithCorner(halfSize[1], isInCorner)]
    state.speed <- [rand.rfloat(0.5 * maxStartSpeed, maxStartSpeed) * -sign, 0]
  }

  fillNewForce(state, time)
}

let function updateSparkState(state, time) {
  let { pos, speed, acc, lastTime, accChangeTime } = state
  let dt = 0.001 * (time - lastTime)
  state.pos = pos.map(@(v, i) v + speed[i] * dt)
  state.speed = speed.map(@(v, i) v + (acc[i] - v * viscosity) * dt)
  state.lastTime = time
  if (accChangeTime >= time)
    fillNewForce(state, time)
}

let length = @(arr) sqrt(arr[0] * arr[0] + arr[1] * arr[1])
let mkFireSparkOnBorder = @(state, effectHalfSize) {
  size = [maxSize, maxSize]
  rendObj = ROBJ_IMAGE
  image = gradRadial
  opacity = 0.0

  animations = [
    { prop = AnimProp.color, from = 0x80F95927, to = 0x80F37247, easing = CosineFull,
      duration = rand.rfloat(3.0, 10.0), play = true, loop = true },
  ]

  behavior = Behaviors.RtPropUpdate
  transform = {}
  function update() {
    let { isActive = false, startTime = -1 } = state
    let time = get_time_msec()
    if (startTime >= time)
      return null

    if (!isActive) {
      if (!state?.shouldFinish)
        initSparkState(state, effectHalfSize, time)
      return { opacity = 0.0 }
    }
    else
      updateSparkState(state, time)

    let { pos, speed, scale } = state
    let moveScale = scale + scaleBySpeed * length(speed)
    let maxOfs = max(moveScale, 2.0) * maxSize
    if (fabs(pos[0]) > effectHalfSize[0] + maxOfs
        || fabs(pos[1]) > effectHalfSize[1] + maxOfs) {
      state.isActive <- false
      return { opacity = 0.0 }
    }

    return {
      opacity = 1.0
      transform = {
        translate = pos
        rotate = -180.0 / PI * atan2(speed[0], speed[1])
        scale = [scale, moveScale]
      }
    }
  }
}

return mkFireSparkOnBorder