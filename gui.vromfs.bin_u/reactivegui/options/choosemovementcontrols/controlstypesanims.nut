from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let mkStickWidgetComps = require("mkStickWidgetComps.nut")
let mkArrowsWidgetComps = require("mkArrowsWidgetComps.nut")

let animSize = evenPx(380)
let canvasHalfSize = 0.5 * animSize
let stickSize = round(0.87 * animSize)
let arrowsSize = round(0.87 * animSize)

let fingerW = round(hdpx(0.87 * animSize))
let fingerH = round(fingerW * 0.92)
let fingerX = round(fingerW * -0.38)
let fingerY = round(fingerH * 0.19)
let fingerOpacity = 0.25

let { stickBgComp, stickHeadComp } = mkStickWidgetComps(stickSize)
let { arrowsWidgetComp, arrowsWidgetParts } = mkArrowsWidgetComps(arrowsSize)

enum GESTURE {
  TAP
  HOLD
  SLIDE
}

let timePause = 1.0
let timeAppear = 0.5
let timeDisappear = timeAppear
let timeSlide = 0.25
let timeLongTap = 1.5
let timeHoldByGeature = {
  [GESTURE.TAP] = 0,
  [GESTURE.HOLD] = timeLongTap,
  [GESTURE.SLIDE] = timeLongTap - timeSlide,
}

let animCompBase = {
  size = [animSize, animSize]
  rendObj = ROBJ_BOX
  clipChildren = true
}

let mkFingerComp = @() {
  size = [fingerW, fingerH]
  pos = [fingerX, fingerY]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = Picture($"ui/images/finger.svg:{fingerW}:{fingerH}:P")
  color = 0xFFFFFFFF
  rendObj = ROBJ_IMAGE
}

let function buildAnimSteps(name, comps, buildAnimStepFunc, steps) {
  let metaCfg = comps.map(@(_) {})
  let restartTrigger = $"trigger{name}"
  foreach (comp in comps)
    comp.__update({
      transform = { pivot = [0.5, 0.5] }
      animations = []
    })
  foreach (data in steps)
    buildAnimStepFunc(comps, restartTrigger, data, metaCfg)
  foreach (comp in comps)
    if (comp.animations.len() != 0) {
      let last = comp.animations.top()
      last.__update({ onExit = last?.trigger })
    }
}

let function mkAnimSequence(prop, trigger, meta, partialAnims) {
  let res = []

  if (prop not in meta)
    meta[prop] <- { timeFinish = 0, lastVal = null }

  foreach (pa in partialAnims) {
    let { timeFinish, lastVal } = meta[prop]
    let a = {
      prop
      from = lastVal
      to = pa?.from ?? lastVal
      delay = timeFinish
      easing = Linear
      play = true
      trigger
    }.__update(pa)

    res.append(a)
    meta[prop].timeFinish = a.delay + a.duration
    meta[prop].lastVal = a.to
  }
  return res
}

let mkPos = @(x, y) [x * canvasHalfSize, y * canvasHalfSize]

let function buildStickAnimStep(comps, trigger, data, metaCfg) {
  let { t, x, y, x2 = 0, y2 = 0 } = data
  let posInit = [0, 0]
  let pos = mkPos(x, y)
  let posTo = mkPos(x2, y2)
  let timeHold = timeHoldByGeature[t]

  foreach (id, comp in comps) {
    let meta = metaCfg[id]

    if (t == GESTURE.HOLD) {
      if (id == "finger")
        comp.animations.extend(mkAnimSequence(AnimProp.translate, trigger, meta, [
            { from = pos, duration = timePause + timeAppear + timeHold + timeDisappear }
          ]))
      else if (id == "head")
        comp.animations.extend(mkAnimSequence(AnimProp.translate, trigger, meta, [
            { from = posInit, duration = timePause + 0.5 * timeAppear }
            { to = pos, duration = 0.5 * timeAppear, easing = InOutQuad }
            { duration = timeHold + timeDisappear }
          ]))
      else if (id == "bg")
        comp.animations.extend(mkAnimSequence(AnimProp.translate, trigger, meta, [
            { from = posInit, duration = timePause + 0.5 * timeAppear }
            { from = pos, duration = 0.5 * timeAppear + timeHold + timeDisappear }
          ]))
    }
    else if (t == GESTURE.SLIDE) {
      if (id == "finger")
        comp.animations.extend(mkAnimSequence(AnimProp.translate, trigger, meta, [
            { from = pos, duration = timePause + timeAppear }
            { to = posTo, duration = timeSlide, easing = InOutQuad }
            { duration = timeHold + timeDisappear }
          ]))
      else if (id == "head")
        comp.animations.extend(
          mkAnimSequence(AnimProp.translate, trigger, meta, [
            { from = posInit, duration = timePause + 0.5 * timeAppear }
            { from = pos, duration = 0.5 * timeAppear }
            { to = posTo, duration = timeSlide, easing = InOutQuad }
            { duration = timeHold + 0.5 * timeDisappear }
            { from = posInit, duration = 0.5 * timeDisappear }
          ]),
          mkAnimSequence(AnimProp.opacity, trigger, meta, [
            { from = 1, duration = timePause }
            { to = 0, duration = 0.5 * timeAppear }
            { to = 1, duration = 0.5 * timeAppear }
            { duration = timeSlide + timeHold }
            { to = 0, duration = 0.5 * timeDisappear }
            { to = 1, duration = 0.5 * timeDisappear }
          ])
        )
      else if (id == "bg")
        comp.animations.extend(
          mkAnimSequence(AnimProp.translate, trigger, meta, [
            { from = posInit, duration = timePause + 0.5 * timeAppear }
            { from = pos, duration = 0.5 * timeAppear }
            { duration = timeSlide + timeHold + 0.5 * timeDisappear }
            { from = posInit, duration = 0.5 * timeDisappear }
          ]),
          mkAnimSequence(AnimProp.opacity, trigger, meta, [
            { from = 1, duration = timePause }
            { to = 0, duration = 0.5 * timeAppear }
            { to = 1, duration = 0.5 * timeAppear }
            { duration = timeSlide + timeHold }
            { to = 0, duration = 0.5 * timeDisappear }
            { to = 1, duration = 0.5 * timeDisappear }
          ])
        )
    }
  }

  comps.finger.animations.extend(
    mkAnimSequence(AnimProp.opacity, trigger, metaCfg.finger, [
      { from = 0, duration = timePause }
      { to = fingerOpacity, duration = timeAppear, easing = OutQuad }
      { duration = timeHold }
      { to = 0, duration = timeDisappear, easing = InQuad }
    ])
  )
}

let function buildArrowsAnimStep(comps, trigger, data, metaCfg) {
  let { t, x, y, btnId } = data
  let pos = mkPos(x, y)
  let timeHold = timeHoldByGeature[t]

  let prevDriving = metaCfg?.isDriving ?? false
  let curDriving = btnId == "up" ? true
    : btnId == "stop" ? false
    : prevDriving
  metaCfg.isDriving <- curDriving

  foreach (id, comp in comps) {
    let meta = metaCfg[id]

    if (id == "finger")
      comp.animations.extend(mkAnimSequence(AnimProp.opacity, trigger, meta, [
          { from = 0, duration = timePause }
          { to = fingerOpacity, duration = timeAppear, easing = OutQuad }
          { duration = timeHold }
          { to = 0, duration = timeDisappear, easing = InQuad }
        ]))
    else if ([ "down", "stop" ].contains(id)) {
      let val = prevDriving == (id == "stop") ? 1 : 0
      comp.animations.extend(mkAnimSequence(AnimProp.opacity, trigger, meta, [
          { from = val, duration = timePause + timeAppear + timeHold + timeDisappear }
        ]))
    }
    else if ([ "upH", "stopH", "leftH" ].contains(id)) {
      let isCurrent = id.slice(0, -1) == btnId
      let isArrowUp = id == "upH"
      let pauseVal = prevDriving && isArrowUp ? 1 : 0
      let holdVal = isCurrent || (curDriving && isArrowUp) ? 1 : 0
      comp.animations.extend(mkAnimSequence(AnimProp.opacity, trigger, meta, [
          { from = pauseVal, duration = timePause }
          { from = holdVal, duration = timeAppear + timeHold + timeDisappear }
        ]))
    }
  }

  comps.finger.animations.extend(mkAnimSequence(AnimProp.translate, trigger, metaCfg.finger, [
      { from = pos, duration = timePause + timeAppear + timeHold + timeDisappear }
    ]))
}

let mkStickAnimComp = @(stickBg, stickHead, finger) animCompBase.__merge({
  children = [
    stickBg
    {
      size = flex()
      children = [
        stickHead
        finger
      ]
    }
  ]
})

let function mkStaticStickAnim() {
  let staticStickComps = {
    finger = mkFingerComp()
    head = clone stickHeadComp
  }
  buildAnimSteps("StaticStick", staticStickComps, buildStickAnimStep, [
    { t = GESTURE.HOLD, x = 0.0, y = -0.36 }
    { t = GESTURE.HOLD, x = 0.36, y = 0.0 }
    { t = GESTURE.HOLD, x = -0.26, y = 0.26 }
  ])
  return mkStickAnimComp(stickBgComp, staticStickComps.head, staticStickComps.finger)
}

let function mkDynamicStickAnim() {
  let dynamicStickComps = {
    finger = mkFingerComp()
    head = clone stickHeadComp
    bg = clone stickBgComp
  }
  buildAnimSteps("DynamicStick", dynamicStickComps, buildStickAnimStep, [
    { t = GESTURE.SLIDE, x = 0.20, y = 0.20, x2 = 0.20, y2 = -0.16 }
    { t = GESTURE.SLIDE, x = -0.20, y = -0.20, x2 = 0.16, y2 = -0.20 }
    { t = GESTURE.SLIDE, x = 0.20, y = -0.20, x2 = -0.06, y2 = 0.06 }
  ])
  return mkStickAnimComp(dynamicStickComps.bg, dynamicStickComps.head, dynamicStickComps.finger)
}

let function mkArrowsAnim() {
  let arrowsComps = {
    finger = mkFingerComp()
    down = arrowsWidgetParts.arrowDown
    stop = arrowsWidgetParts.arrowStop
    upH = arrowsWidgetParts.arrowUpH
    stopH = arrowsWidgetParts.arrowStopH
    leftH = arrowsWidgetParts.arrowLeftH
  }
  buildAnimSteps("Arrows", arrowsComps, buildArrowsAnimStep, [
    { t = GESTURE.TAP, x = 0.0, y = -0.28, btnId = "up" }
    { t = GESTURE.HOLD, x = -0.52, y = 0.0, btnId = "left" }
    { t = GESTURE.TAP, x = 0.0, y = 0.24, btnId = "stop" }
  ])
  return animCompBase.__merge({
    children = [
      arrowsWidgetComp // arrowsWidgetParts comps are inside
      arrowsComps.finger
    ]
  })
}

return { // keys are control type IDs
  stick = mkDynamicStickAnim
  stick_static = mkStaticStickAnim
  arrows = mkArrowsAnim
}
