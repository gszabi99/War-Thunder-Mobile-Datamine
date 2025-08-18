from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudTuning/hudTuningConsts.nut" import *
let { dfAnimBottomCenter, dfAnimBottomLeft, dfAnimBottomRight
} = require("%rGui/style/unitDelayAnims.nut")
let { hudUnitType, isUnitDelayed } = require("%rGui/hudState.nut")
let { cfgByUnitTypeOrdered } = require("%rGui/hudTuning/cfgByUnitType.nut")
let { curUnitHudTuning } = require("%rGui/hudTuning/hudTuningBattleState.nut")
let { optScale } = require("%rGui/hudTuning/cfg/cfgOptions.nut")


let anims = {
  [ALIGN_RB] = dfAnimBottomRight,
  [ALIGN_LB] = dfAnimBottomLeft,
}

function mkHudTuningElem(cfg, transform, options) {
  if (!(cfg?.isVisible(options) ?? true))
    return null

  let { id, ctor, defTransform = {}, hideForDelayed = true, isVisibleInBattle = null, hasScale, needId } = cfg
  let { align = 0, pos = null } = transform ?? defTransform
  let ctorFinal = needId ? @() ctor(optScale.getValue(options, id), id)
    : hasScale ? @() ctor(optScale.getValue(options, id))
    : ctor
  let children = isVisibleInBattle == null ? ctorFinal()
    : @() {
        watch = isVisibleInBattle
        children = isVisibleInBattle.value ? ctorFinal() : null
      }
  let res = {
    size = 0
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

  return @() isUnitDelayed.get() ? emptyRes : res
}

let hudTuningElems = @() {
  watch = [hudUnitType, curUnitHudTuning]
  key = "hudTuningElems"
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = cfgByUnitTypeOrdered?[hudUnitType.get()]
    .map(@(cfg) mkHudTuningElem(cfg,
      curUnitHudTuning.get()?.transforms[cfg.id],
      curUnitHudTuning.get()?.options))
}

return hudTuningElems