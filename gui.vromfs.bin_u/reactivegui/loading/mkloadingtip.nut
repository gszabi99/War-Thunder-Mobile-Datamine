from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/unitPresentation.nut" import unitTypeFontIcons, unitTypeColors
from "%globalsDarg/loading/loadingTips.nut" import curTipInfo, enableTipsUpdate, disableTipsUpdate,
  GLOBAL_LOADING_TIP_BIT
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset


let unitTypeWeightsByCampaign = {
  ships = { [BIT_SHIP] = 0.7, [BIT_AIR] = 0.2, [GLOBAL_LOADING_TIP_BIT] = 0.1 }
  tanks = { [BIT_TANK] = 0.7, [BIT_AIR] = 0.2, [GLOBAL_LOADING_TIP_BIT] = 0.1 }
  air   = { [BIT_AIR] = 0.9, [GLOBAL_LOADING_TIP_BIT] = 0.1 }
}

const iconColorDefault = 0xFF808080
const textColor = 0xFFE0E0E0

let key = {}
let mkLoadingTip = @(ovr = {}) function() {
  let { locId, unitType } = curTipInfo.get()
  let iconColor = unitTypeColors?[unitType] ?? iconColorDefault
  let icon = colorize(iconColor, unitTypeFontIcons?[unitType] ?? "")
  let text = loc(locId)
  return {
    watch = curTipInfo
    key
    size = FLEX_H
    color = textColor
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = " ".concat(icon, text)
    halign = ALIGN_CENTER
    onAttach = @() enableTipsUpdate(unitTypeWeightsByCampaign?[curCampaign.get()])
    onDetach = disableTipsUpdate
  }.__update(fontSmall, ovr)
}

let gradientLoadingTip = {
  size = const [hdpx(1200), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  pos = const [0, sh(-10)]
  padding = const [hdpx(20), hdpx(100)]
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