
from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCustomButton, paddingX, mergeStyles } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkPlayerLevel } = require("%rGui/unit/components/unitPlateComp.nut")
let { mkUnitLevel } = require("%rGui/unit/components/unitLevelComp.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")

let textBtnComp = @(text, ovr){
  maxWidth = defButtonMinWidth - (2 * paddingX + CS_COMMON.iconSize)
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text
}.__update(fontVeryTinyAccentedShaded, ovr)

function mkCostComp(cost) {
  let { price = 0, currencyId = "" } = cost
  return price > 0 && currencyId != ""
   ? mkCurrencyComp(price, currencyId, CS_COMMON)
   : null
}

let mkPlayerLevelUpTextComp = @(text, level, starLevel, cost, textOvr) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    textBtnComp(utf8ToUpper(text), textOvr)
    mkPlayerLevel(level, starLevel)
    mkCostComp(cost)
  ]
}

let mkVehicleLevelUpTextComp = @(text, level, textOvr) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    textBtnComp(utf8ToUpper(text), textOvr)
    mkUnitLevel(level)
  ]
}

return {
  textButtonPlayerLevelUp = @(text, level, starLevel, onClick, styleOvr = null, cost = null)
    mkCustomButton(mkPlayerLevelUpTextComp(text, level, starLevel, cost, styleOvr?.textOvr ?? {}), onClick, mergeStyles(PURCHASE, styleOvr)) 
  textButtonVehicleLevelUp = @(text, level, onClick, styleOvr = null)
    mkCustomButton(mkVehicleLevelUpTextComp(text, level, styleOvr?.textOvr ?? {}), onClick, mergeStyles(PURCHASE, styleOvr)) 
}
