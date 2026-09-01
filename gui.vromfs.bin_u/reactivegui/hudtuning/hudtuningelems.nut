from "%rGui/hudTuning/hudTuningConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudState.nut" import isUnitDelayed
from "%rGui/hudStateExt.nut" import hudUnitType
from "%rGui/hudTuning/cfg/cfgOptions.nut" import optScale, getElemVisible
from "%rGui/hudTuning/cfgByUnitType.nut" import cfgByUnitTypeOrdered
from "%rGui/hudTuning/hudTuningBattleState.nut" import curUnitHudTuning
from "%rGui/style/unitDelayAnims.nut" import dfAnimBottomCenter, dfAnimBottomLeft, dfAnimBottomRight


let anims = {
  [ALIGN_RB] = dfAnimBottomRight,
  [ALIGN_LB] = dfAnimBottomLeft,
}

function mkHudTuningElem(cfg, transform, options) {
  if (!(cfg?.isVisible(options) ?? true))
    return null
  if ((cfg?.canHide ?? false) && !getElemVisible(options, cfg.id))
    return null

  let { id, ctor, defTransform = {}, hideForDelayed = true, isVisibleInBattle = null, hasScale, needId } = cfg
  let { align = 0, pos = null } = transform ?? defTransform
  let ctorFinal = needId ? @() ctor(optScale.getValue(options, id), id)
    : hasScale ? @() ctor(optScale.getValue(options, id))
    : ctor
  let children = isVisibleInBattle == null ? ctorFinal()
    : @() {
        watch = isVisibleInBattle
        children = isVisibleInBattle.get() ? ctorFinal() : null
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