from "%globalsDarg/darg_library.nut" import *
let { ctfFlagPreset } = require("%appGlobals/clientState/missionState.nut")
let { getCtfFlagPresentation } = require("%appGlobals/config/hudCustomRulesPresentation.nut")
let { teamRedColor } = require("%rGui/style/teamColors.nut")
let { mkGradientBlock, defBgColor } = require("%rGui/hudHints/hintCtors.nut")
let { isFlagStolen } = require("%rGui/hud/missionScoreState.nut")


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
