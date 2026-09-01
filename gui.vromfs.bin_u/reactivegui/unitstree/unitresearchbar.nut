from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/unit/components/unitPlateComp.nut" import unitPlateTiny
from "%rGui/unitsTree/components/unitPlateAnimations.nut" import progressbarAnimDuration, progressbarAnimDurationShort


const plateBarHeight = hdpx(10)
const bgColor = 0x80000000
const expColor = 0xFFE86C00
const blueprintBarColor = 0xFF3384C4

let mkAnimatedBar = @(completion, color, isShaded = false, duration = 0.5, durationShort = 0.2) [
  {
    rendObj = ROBJ_SOLID
    size = FLEX
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
    size = FLEX
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
    size = const [pw(100), plateBarHeight]
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
      size = const [pw(100), plateBarHeight]
      vplace = ALIGN_BOTTOM
      pos = const [0, plateBarHeight]
      color = bgColor
      children = mkAnimatedBar(max(0.01, curBluebrintsCount.get().tofloat() / reqBluebrintsCount.get()), blueprintBarColor, false)
    }.__update(ovr)
}

function mkPlateExpBarAnimSlot(animExpPart, isBlueprintUnit, ovr = {}) {
  return {
    rendObj = ROBJ_SOLID
    size = [unitPlateTiny[0], plateBarHeight]
    valign = ALIGN_BOTTOM
    color = bgColor
    children = mkAnimatedBar(max(0.01, animExpPart), isBlueprintUnit ? blueprintBarColor : expColor,
      false, progressbarAnimDuration, progressbarAnimDurationShort)
  }.__update(ovr)
}

return {
  mkAnimatedBar

  mkPlateExpBar
  mkPlateBlueprintBar
  mkPlateExpBarAnimSlot
  plateBarHeight
}
