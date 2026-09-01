from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/missionState.nut" import ctfFlagPreset
from "%appGlobals/config/hudCustomRulesPresentation.nut" import getCtfFlagPresentation
from "%rGui/hud/missionScoreState.nut" import isFlagStolen
from "%rGui/hudHints/hintCtors.nut" import mkGradientBlock, defBgColor
from "%rGui/style/teamColors.nut" import teamRedColor


let msgBlock = @() @() {
  watch = [isFlagStolen, ctfFlagPreset]
  children = !isFlagStolen.get() ? null : mkGradientBlock(defBgColor,
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(getCtfFlagPresentation(ctfFlagPreset.get()).flagCapturedLocId)
      color = teamRedColor
    }.__update(fontTinyAccentedShaded),
    hdpx(600)
  )}

let msgBlockEditView = {
  children = mkGradientBlock(defBgColor,
    @() {
      watch = ctfFlagPreset
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(getCtfFlagPresentation(ctfFlagPreset.get()).flagCapturedLocId)
      color = teamRedColor
    }.__update(fontTinyAccentedShaded),
    hdpx(600)
  )}

return { msgBlock, msgBlockEditView }
