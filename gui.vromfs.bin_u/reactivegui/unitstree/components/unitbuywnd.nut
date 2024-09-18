
from "%globalsDarg/darg_library.nut" import *
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { mkTreeNodesUnitPlateBuy } = require("%rGui/unitsTree/components/unitPlateNodeComp.nut")
let { AIR } = require("%appGlobals/unitConst.nut")

function purchUnitContent(unitId){
  let unit = allUnitsCfg.value?[unitId]
  return{
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      mkTreeNodesUnitPlateBuy(unit)
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_CENTER
        text = loc(unit?.unitType != AIR ? "shop/buyUnitWnd" : "shop/buyUnitWnd_air",
        { item = colorize(userlogTextColor, loc(getUnitPresentation(unit).locId)) })
      }.__update(fontSmall)
    ]
  }
}

return purchUnitContent