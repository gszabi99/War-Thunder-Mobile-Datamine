from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { unitPlateTiny } = require("%rGui/unit/components/unitPlateComp.nut")
let { progressbarAnimDuration,  progressbarAnimDurationShort } = require("%rGui/unitsTree/components/unitPlateAnimations.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")

let plateBarHeight = hdpx(10)
let bgColor = 0x80000000
let expColor = 0xFFE86C00
let blueprintBarColor = 0xFF3384C4

let mkAnimatedBar = @(completion, color, isShaded = false, duration = 0.5, durationShort = 0.2) [
  {
    rendObj = ROBJ_SOLID
    size = flex()
    color
    brightness = isShaded ? 0.4 : 2.0
    transform = {
      scale = [completion, 1.0]
      pivot = [0, 0]
    }
    transitions = [{ prop = AnimProp.scale, duration = durationShort , easing = InOutQuad }]
  }
  {
    rendObj = ROBJ_SOLID
    size = flex()
    color
    brightness = isShaded ? 0.4 : 1.0
    transform = {
      scale = [completion, 1.0]
      pivot = [0, 0]
    }
    transitions = [{ prop = AnimProp.scale, duration, easing = InOutQuad }]
  }
]

function mkPlateExpBar(researchStatus, ovr = {}) {
  let { exp = 0, reqExp = 0, isCurrent = false, canResearch = false } = researchStatus
  if (!canResearch || reqExp <= 0 || exp >= reqExp)
    return null
  return {
    rendObj = ROBJ_SOLID
    size = [pw(100), plateBarHeight]
    vplace = ALIGN_BOTTOM
    color = bgColor
    children = mkAnimatedBar(max(0.01, exp.tofloat() / reqExp), expColor, !isCurrent)
  }.__update(ovr)
}

function mkPlateBlueprintBar(unit, ovr = {}) {
  let curBluebrintsCount = Computed(@() servProfile.get()?.blueprints?[unit.name] ?? 0)
  let reqBluebrintsCount = Computed(@() serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1)
  return @() unit.name not in serverConfigs.get()?.allBlueprints || unit.name in campMyUnits.get()
    ? { watch = [serverConfigs campMyUnits] }
    : {
      watch = [curBluebrintsCount, reqBluebrintsCount, serverConfigs, campMyUnits]
      rendObj = ROBJ_SOLID
      size = [pw(100), plateBarHeight]
      vplace = ALIGN_BOTTOM
      pos = [0, plateBarHeight]
      color = bgColor
      children = mkAnimatedBar(max(0.01, curBluebrintsCount.get().tofloat() / reqBluebrintsCount.get()),blueprintBarColor, false)
    }.__update(ovr)
}

function mkPlateExpBarAnimSlot(animExpPart,  ovr = {}) {
  return {
    rendObj = ROBJ_SOLID
    size = [unitPlateTiny[0], plateBarHeight]
    valign = ALIGN_BOTTOM
    color = bgColor
    children = mkAnimatedBar(max(0.01, animExpPart), expColor, false, progressbarAnimDuration, progressbarAnimDurationShort)
  }.__update(ovr)
}

return {
  mkAnimatedBar

  mkPlateExpBar
  mkPlateBlueprintBar
  mkPlateExpBarAnimSlot
  plateBarHeight
}
