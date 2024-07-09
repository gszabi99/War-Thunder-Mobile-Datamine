from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")


let plateBarHeight = hdpx(10)
let bgColor = 0x80000000
let expColor = 0xFFE86C00
let blueprintBarColor = 0xFF3384C4

let mkAnimatedBar = @(completion, color, isShaded = false) [
  {
    rendObj = ROBJ_SOLID
    size = flex()
    color
    brightness = isShaded ? 0.4 : 2.0
    transform = {
      scale = [completion, 1.0]
      pivot = [0, 0]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
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
    transitions = [{ prop = AnimProp.scale, duration = 0.5, easing = InOutQuad }]
  }
]

function mkPlateExpBar(researchStatus, ovr = {}) {
  let { exp = 0, reqExp = 0, isCurrent = false, isAvailable = false } = researchStatus
  if (!isAvailable || reqExp <= 0 || exp >= reqExp)
    return null
  return {
    rendObj = ROBJ_SOLID
    size = [pw(100), plateBarHeight]
    vplace = ALIGN_BOTTOM
    color = bgColor
    children = mkAnimatedBar(max(0.01, exp.tofloat() / reqExp), expColor, !isCurrent)
  }.__update(ovr)
}

function mkPlateBlueprintBar(unit) {
  let curBluebrintsCount = Computed(@() servProfile.get()?.blueprints?[unit.name] ?? 0)
  let reqBluebrintsCount = Computed(@() serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1)
  return @() {
    watch = [curBluebrintsCount, reqBluebrintsCount]
    rendObj = ROBJ_SOLID
    size = [pw(100), plateBarHeight]
    vplace = ALIGN_BOTTOM
    pos = [0, plateBarHeight]
    color = bgColor
    children = mkAnimatedBar(max(0.01, curBluebrintsCount.get().tofloat() / reqBluebrintsCount.get()),blueprintBarColor, false)
  }
}

return {
  mkPlateExpBar
  mkPlateBlueprintBar
  plateBarHeight
}
