from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { fabs, sin, cos, PI, atan2, lerp } = require("%sqstd/math.nut")
let rand = require("%sqstd/rand.nut")()
let { gradRadial } = require("%rGui/style/gradients.nut")

let sparkMaxSize = hdpx(10)
let sparkMinSpeed = hdpx(20)
let sparkMaxSpeed = hdpx(60)
let glareMaxSize = hdpx(35)
let glareTime = 1.3
let sparkMinLifeTime = 2.0
let sparkMaxLifeTime = 10.0
let maxAngleDiff = 30.0 / 180.0 * PI

let getNextGlareTime = @(count) rand.rfloat(0.2, 0.5) * (count + 1) * (count + 1)
  + (count > 0 ? glareTime : 0)

let function zoneStartPos(halfSize) {
  local pos = null
  let minRadius = 0.9 * min(halfSize[1], halfSize[0] * 9 / 16)
  let minRadiusSq = minRadius * minRadius
  for (local i = 0; i < 5; i++) {
    pos = halfSize.map(@(v) v * rand.rfloat(-0.9, 0.9))
    if (0.6 * pos[0] * pos[0] + pos[1] * pos[1] >= minRadiusSq)
      return pos
  }
  return pos
}

let function getVisiblePart(startPos, moveDir, effectHalfSize) {
  local res = 1.0
  foreach (i, dir in moveDir) {
    if (dir == 0)
      continue
    let final = startPos[i] + dir
    if (fabs(final) <= effectHalfSize[i])
      continue
    res = min(res,
      dir > 0 ? (effectHalfSize[i] - startPos[i]) / dir
        : (startPos[i] + effectHalfSize[i]) / -dir)
  }
  return res
}

let function fillSparkState(state, effectHalfSize, showTime = 300) {
  let startPos = zoneStartPos(effectHalfSize)
  state.startPos <- startPos
  let angle = atan2(startPos[0], startPos[1]) + rand.rfloat(-maxAngleDiff, maxAngleDiff)
  let lifeTime = rand.rfloat(sparkMinLifeTime, sparkMaxLifeTime)
  let speed = rand.rfloat(sparkMinSpeed, sparkMaxSpeed)
  let dist = lifeTime * speed
  let moveDir = [dist * sin(angle), dist * cos(angle)]
  let movePart = getVisiblePart(startPos, moveDir, effectHalfSize)

  state.isActive <- true
  state.endPos <- startPos.map(@(v, i) v + moveDir[i] * movePart)
  state.endTime <- state.startTime + (movePart * lifeTime * 1000).tointeger()
  state.showTime <- state.startTime + showTime
  state.hideTime <- state.endTime - 300
  state.scale <- array(2, rand.rfloat(0.3, 1.0))
  state.glareCount <- 0
  state.nextGlareTime <- state.startTime + (1000 * getNextGlareTime(state.glareCount)).tointeger()
}

let mkSparkStarMoveOut = @(color) @(state, effectHalfSize) {
  size = [sparkMaxSize, sparkMaxSize]
  rendObj = ROBJ_IMAGE
  image = gradRadial
  color
  opacity = 0.0

  children = {
    key = state
    size = array(2, (glareMaxSize * rand.rfloat(0.5, 1.0)).tointeger())
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture("ui/images/effects/glare_star_a_tex_d.avif:0:P")
    color
    transform = { scale = [0.0, 0.0] }
    animations = [
      { prop = AnimProp.scale, from = [0.0, 0.0], to = [1.0, 1.0], easing = CosineFull,
        duration = glareTime, trigger = state },
    ]
  }

  behavior = Behaviors.RtPropUpdate
  transform = {}
  function update() {
    let time = get_time_msec()
    if ("startTime" not in state) {  //not inited
      let { initDelay = 0.0 } = state
      state.startTime <- time + (1000 * initDelay).tointeger()
      fillSparkState(state, effectHalfSize, initDelay == 0 ? 300 : 1000)
    }
    if (state.endTime <= time) { //gen new spark
      if (state?.shouldFinish) {
        state.isActive <- false
        return { opacity = 0.0 }
      }
      state.startTime <- time
      fillSparkState(state, effectHalfSize)
    }
    if (state.startTime >= time)
      return { opacity = 0.0, transform = { scale = state.scale } }

    let { startPos, endPos, startTime, endTime, showTime, hideTime, nextGlareTime } = state
    if (nextGlareTime <= time) {
      anim_start(state)
      state.glareCount++
      state.nextGlareTime <- state.startTime + (1000 * getNextGlareTime(state.glareCount)).tointeger()
    }
    return {
      opacity = time > hideTime ? lerp(hideTime, endTime, 1.0, 0.0, time)
        : time < showTime ? lerp(startTime, showTime, 0.0, 1.0, time)
        : 1.0
      transform = {
        translate = [
          lerp(startTime, endTime, startPos[0], endPos[0], time),
          lerp(startTime, endTime, startPos[1], endPos[1], time)
        ]
      }
    }
  }
}

return mkSparkStarMoveOut