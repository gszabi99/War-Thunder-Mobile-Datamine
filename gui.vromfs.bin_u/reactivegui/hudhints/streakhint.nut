from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/currenciesState.nut" import WP
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/currencyStyles.nut" import CS_SMALL
from "%rGui/hudHints/hintCtors.nut" import registerHintCreator, mkGradientBlock, defBgColor
from "%rGui/unlocks/streakPkg.nut" import mkStreakIcon, getMultiStageUnlockId, getUnlockLocText


const HINT_TYPE = "streak"

registerHintCreator(HINT_TYPE, function(data, _) {
  let { unlockId = "", wp = 0, stage = 1, sound = "streak" } = data
  let id = getMultiStageUnlockId(unlockId, stage)
  let content = {
    key = HINT_TYPE
    size = const [FLEX, hdpx(50)]
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
