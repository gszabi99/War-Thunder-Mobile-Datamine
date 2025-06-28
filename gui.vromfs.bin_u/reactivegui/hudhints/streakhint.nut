from "%globalsDarg/darg_library.nut" import *
let { registerHintCreator, mkGradientBlock, defBgColor } = require("%rGui/hudHints/hintCtors.nut")
let { mkStreakIcon, getMultiStageUnlockId, getUnlockLocText } = require("%rGui/unlocks/streakPkg.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { WP } = require("%appGlobals/currenciesState.nut")
let { CS_SMALL } = require("%rGui/components/currencyStyles.nut")

let HINT_TYPE = "streak"

registerHintCreator(HINT_TYPE, function(data, _) {
  let { unlockId = "", wp = 0, stage = 1, sound = "streak" } = data
  let id = getMultiStageUnlockId(unlockId, stage)
  let content = {
    key = HINT_TYPE
    size = const [flex(), hdpx(50)]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      mkCurrencyComp(wp, WP, CS_SMALL)
      mkStreakIcon(id, hdpx(85), stage)
      {
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        text = getUnlockLocText(id, stage)
      }.__update(fontSmallShaded)
    ]
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.7,
        easing = DoubleBlink, play = true }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true }
    ]
    sound = { attach = sound }
  }
  return mkGradientBlock(defBgColor, content, hdpx(800), hdpx(2))
})
