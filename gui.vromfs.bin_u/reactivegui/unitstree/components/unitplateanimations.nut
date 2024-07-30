from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { lerpClamped } = require("%sqstd/math.nut")
let { startSound, stopSound } = require("sound_wt")
let { mkIcon, plateTextsSmallPad } = require("%rGui/unit/components/unitPlateComp.nut")
let { needShowPriceUnit, animUnitAfterResearch }= require("%rGui/unitsTree/animState.nut")

let activeCounters = Watched({})

let isCounterActive = keepref(Computed(@() activeCounters.get().len() > 0))
isCounterActive.subscribe(@(v) v ? startSound("coin_counter") : stopSound("coin_counter"))

let progressbarAnimDuration = 1
let progressbarAnimDurationShort = 0.5

let counterAnimDelay = 0.3
let counterAnimDuration = 800

let scaleUnitAnimDuration = 0.7
let scaleUnitAnimDelay = progressbarAnimDuration

let priceAnimDuration = 0.5

let sumTimeAnim = progressbarAnimDuration + scaleUnitAnimDuration + priceAnimDuration


let animUnitSlot  = @(unit) [
  {
    prop = AnimProp.scale, from = [1, 1] to = [1.15, 1.15], duration = scaleUnitAnimDuration, delay = scaleUnitAnimDelay,
    trigger = $"anim_{unit}", easing = CosineFull, play = true,
    function onFinish() {
      needShowPriceUnit(true)
      anim_start("startWpAnim")
    }
  }
]

let animCountBaseComp = {
  rendObj = ROBJ_TEXT
  halign = ALIGN_LEFT
  color = 0xFFFF9D47
}.__update(fontVeryTiny)

function setCounterActive(uid, isActive) {
  if (isActive != (uid in activeCounters.get()))
    activeCounters.mutate(function(v) {
      if (isActive)
        v[uid] <- true
      else
        v.$rawdelete(uid)
    })
}

function mkAnimatedCountText(needStart, startV, endV, key) {
  if(!needStart)
    return animCountBaseComp.__merge({text = startV})

  let finalText = endV
  local needReset = false
  local startTimeMs = 0
  local endTimeMs = 0
  function reinitTime(nowMs) {
    startTimeMs = nowMs + (1000 * counterAnimDelay).tointeger()
    endTimeMs = startTimeMs + counterAnimDuration
  }
  reinitTime(get_time_msec())

  return animCountBaseComp.__merge({
    key
    text = startV
    behavior = Behaviors.RtPropUpdate
    function onAttach() {
      let curTime = get_time_msec()
      if (curTime >= endTimeMs) {
        reinitTime(curTime)
        needReset = true
      }
    }
    onDetach = @() setCounterActive(key, false)
    function update() {
      let curTime = get_time_msec()
      if (curTime < startTimeMs) {
        if (!needReset)
          return null
        needReset = false
        return { text = startV }
      }
      let text = curTime >= endTimeMs ? finalText
        : lerpClamped(startTimeMs, endTimeMs, 0, endV, curTime).tointeger()
      setCounterActive(key, text != finalText)
      return { text }
    }
  })
}

let function mkUnitResearchPriceAnim(researchStatus, ovr = {}) {
  let { exp = 0, reqExp = 0 } = researchStatus
  return @() {
    watch = animUnitAfterResearch
    padding = plateTextsSmallPad
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = [
      mkIcon("ui/gameuiskin#unit_exp_icon.svg", [hdpxi(28), hdpxi(28)], {margin = [0, hdpx(10), 0, 0]})
      mkAnimatedCountText(animUnitAfterResearch.get(), exp, reqExp, exp)
      {
        rendObj = ROBJ_TEXT
        text = $"/{reqExp}"
        color = 0xFFFF9D47
      }.__update(fontVeryTiny)
    ]
  }.__update(ovr)
}


return {
  progressbarAnimDuration
  progressbarAnimDurationShort
  counterAnimDuration
  scaleUnitAnimDuration
  scaleUnitAnimDelay
  priceAnimDuration
  sumTimeAnim

  animUnitSlot
  mkAnimatedCountText
  mkUnitResearchPriceAnim
}