from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "sound_wt" import startSound, stopSound
from "%sqstd/math.nut" import lerpClamped
from "%appGlobals/config/currencyPresentation.nut" import currencyIconsColor
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/unit/components/unitPlateComp.nut" import mkIcon, plateTextsSmallPad
from "%rGui/unitsTree/animState.nut" import needShowPriceUnit, animUnitAfterResearch


let activeCounters = Watched({})

let isCounterActive = keepref(Computed(@() activeCounters.get().len() > 0))
isCounterActive.subscribe(@(v) v ? startSound("coin_counter") : stopSound("coin_counter"))

const progressbarAnimDuration = 1
const progressbarAnimDurationShort = 0.5

const counterAnimDelay = 0.3
const counterAnimDuration = 800

const scaleUnitAnimDuration = 0.7
const scaleUnitAnimDelay = progressbarAnimDuration

const priceAnimDuration = 0.5

const sumTimeAnim = progressbarAnimDuration + scaleUnitAnimDuration + priceAnimDuration


let animUnitSlot  = @(unit) [
  {
    prop = AnimProp.scale, from = [1, 1] to = [1.15, 1.15], duration = scaleUnitAnimDuration, delay = scaleUnitAnimDelay,
    trigger = $"anim_{unit}", easing = CosineFull, play = true,
    function onFinish() {
      needShowPriceUnit.set(true)
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

function mkAnimatedCountText(needStart, startV, endV, key, ovr = {}) {
  if(!needStart)
    return animCountBaseComp.__merge({ text = startV }, ovr)

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
    size = [calc_comp_size({rendObj = ROBJ_TEXT, text = endV}.__update(fontVeryTiny))[0], FLEX]
    rendObj = ROBJ_TEXT
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
  }, ovr)
}

function mkUnitResearchPriceAnim(researchStatus, ovr = {}) {
  let { exp = 0, reqExp = 0, isResearched = false } = researchStatus
  return @() {
    watch = animUnitAfterResearch
    padding = plateTextsSmallPad
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = [
      mkIcon("ui/gameuiskin#experience_icon.svg", [hdpxi(28), hdpxi(28)],
        { margin = const [0, hdpx(10), 0, 0], color = currencyIconsColor["researchUnitExp"] })
      mkAnimatedCountText(animUnitAfterResearch.get(), isResearched ? reqExp : exp, reqExp, isResearched ? reqExp : exp)
      {
        rendObj = ROBJ_TEXT
        text = $"/{reqExp}"
        color = 0xFFFF9D47
      }.__update(fontVeryTiny)
    ]
  }.__update(ovr)
}

let mkBlueprintUnitResearchPriceAnim = @(unit, researchStatus, ovr = {}) function() {
  let { exp = 0, reqExp = 0, isResearched = false } = researchStatus
  let count = servProfile.get()?.blueprints?[unit.name] ?? 0
  let tgtCount = serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 0
  return count < tgtCount || unit.name in campMyUnits.get()
    ? { watch = [servProfile, serverConfigs, campMyUnits, animUnitAfterResearch] }
    : {
        watch = animUnitAfterResearch
        padding = plateTextsSmallPad
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(5)
        children = [
          mkIcon("ui/unitskin#blueprint_default_small.avif", [hdpxi(28), hdpxi(28)],
            { margin = const [0, hdpx(10), 0, 0], transform = { rotate = -10 } })
          mkAnimatedCountText(animUnitAfterResearch.get(), isResearched ? reqExp : exp, reqExp, isResearched ? reqExp : exp,
            { color = 0xFFFFFFFF })
          {
            rendObj = ROBJ_TEXT
            color = 0xFFFFFFFF
            text = $"/{reqExp}"
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
  mkBlueprintUnitResearchPriceAnim
}