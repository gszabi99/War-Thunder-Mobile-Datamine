from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curTipInfo, enableTipsUpdate, disableTipsUpdate, GLOBAL_LOADING_TIP_BIT
} = require("%globalsDarg/loading/loadingTips.nut")
let { unitTypeFontIcons, unitTypeColors } = require("%appGlobals/unitPresentation.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")

let unitTypeWeightsByCampaign = {
  ships = { [BIT_SHIP] = 0.7, [BIT_AIR] = 0.2, [GLOBAL_LOADING_TIP_BIT] = 0.1 }
  tanks = { [BIT_TANK] = 0.7, [BIT_AIR] = 0.2, [GLOBAL_LOADING_TIP_BIT] = 0.1 }
}

let iconColorDefault = 0xFF808080
let textColor = 0xFFE0E0E0

let key = {}
let mkLoadingTip = @(ovr = {}) function() {
  let { locId, unitType } = curTipInfo.value
  let iconColor = unitTypeColors?[unitType] ?? iconColorDefault
  let icon = colorize(iconColor, unitTypeFontIcons?[unitType] ?? "")
  let text = loc(locId)
  return {
    watch = curTipInfo
    key
    size = [flex(), SIZE_TO_CONTENT]
    color = textColor
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = " ".concat(icon, text)
    halign = ALIGN_CENTER
    onAttach = @() enableTipsUpdate(unitTypeWeightsByCampaign?[curCampaign.value])
    onDetach = disableTipsUpdate
  }.__update(fontSmall, ovr)
}

let gradientLoadingTip = {
  size = [hdpx(1200), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  pos = [0, sh(-10)]
  padding = [hdpx(20), hdpx(100)]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0xA0000000
  children = mkLoadingTip()
}

return {
  mkLoadingTip
  gradientLoadingTip
}