from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/buttonStyles.nut" import PURCHASE, defButtonMinWidth
from "%rGui/components/currencyStyles.nut" import CS_COMMON
from "%rGui/components/levelBlockPkg.nut" import unitExpColor
from "%rGui/components/textButton.nut" import mkCustomButton, paddingX, mergeStyles
from "%rGui/unit/components/unitLevelComp.nut" import mkUnitLevel


let textBtnComp = @(text, ovr){
  maxWidth = defButtonMinWidth - (2 * paddingX + CS_COMMON.iconSize)
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text
}.__update(fontVeryTinyAccentedShaded, ovr)

let mkVehicleLevelUpTextComp = @(text, level, textOvr, color) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    textBtnComp(utf8ToUpper(text), textOvr)
    mkUnitLevel(level, 0, color)
  ]
}

return {
  textButtonVehicleLevelUp = @(text, level, onClick, styleOvr = null)
    mkCustomButton(mkVehicleLevelUpTextComp(text, level, styleOvr?.textOvr ?? {}, styleOvr?.color ?? unitExpColor), onClick, mergeStyles(PURCHASE, styleOvr)) 
}
