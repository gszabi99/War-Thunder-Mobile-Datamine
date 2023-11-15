
from "%globalsDarg/darg_library.nut" import *
let { mkCustomButton, paddingX, mergeStyles } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkPlayerLevel } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkUnitLevel } = require("%rGui/unit/components/unitLevelComp.nut")

let textBtnComp = @(text){
  size = [defButtonMinWidth - 2 * paddingX, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text
}.__update(fontTinyAccented)

let mkPlayerLevelUpTextComp = @(text, level, starLevel) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    textBtnComp(text)
    mkPlayerLevel(level, starLevel)
  ]
}

let mkVehicleLevelUpTextComp = @(text, level) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    textBtnComp(text)
    mkUnitLevel(level)
  ]
}

return {
  textButtonPlayerLevelUp = @(text, level, starLevel, onClick, styleOvr = null)
    mkCustomButton(mkPlayerLevelUpTextComp(text, level, starLevel), onClick, mergeStyles(PURCHASE, styleOvr)) // Gold with player level square
  textButtonVehicleLevelUp = @(text, level, onClick, styleOvr = null)
    mkCustomButton(mkVehicleLevelUpTextComp(text, level), onClick, mergeStyles(PURCHASE, styleOvr)) // Gold with unit level square
}
