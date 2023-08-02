from "%globalsDarg/darg_library.nut" import *
from "hudTuningConsts.nut" import *
let { dfAnimBottomCenter, dfAnimBottomLeft, dfAnimBottomRight
} = require("%rGui/style/unitDelayAnims.nut")
let { unitType, isUnitDelayed } = require("%rGui/hudState.nut")
let cfgByUnitType = require("cfgByUnitType.nut")
let { transformsByUnitType } = require("hudTuningState.nut")

let anims = {
  [ALIGN_RB] = dfAnimBottomRight,
  [ALIGN_LB] = dfAnimBottomLeft,
}

let function mkHudTuningElem(cfg, id, transform) {
  let { ctor, defTransform = {}, hideForDelayed = true, isVisibleInBattle = null } = cfg
  let { align = 0, pos = null } = transform ?? defTransform
  let children = isVisibleInBattle == null ? ctor()
    : @() {
        watch = isVisibleInBattle
        children = isVisibleInBattle.value ? ctor() : null
      }
  let res = {
    size = [0, 0]
    pos
    children
  }.__update(alignToDargPlace(align))
  if (!hideForDelayed)
    return res

  let emptyRes = {
    watch = isUnitDelayed
    key = id
    transform = {}
    animations = hideForDelayed ? (anims?[align] ?? dfAnimBottomCenter) : null
  }
  res.__update(emptyRes)

  return @() isUnitDelayed.value ? emptyRes : res
}

let hudTuningElems = @() {
  watch = [unitType, transformsByUnitType]
  key = "hudTuningElems"
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = cfgByUnitType?[unitType.value]
    .map(@(cfg, id) mkHudTuningElem(cfg, id, transformsByUnitType.value?[unitType.value][id]))
    .values()
}

return hudTuningElems