from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import campUnitsCfg
from "%appGlobals/unitConst.nut" import AIR
from "%appGlobals/unitPresentation.nut" import getUnitPresentation
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/unitsTree/components/unitPlateNodeComp.nut" import mkTreeNodesUnitPlateBuy


function purchUnitContent(unitId){
  let unit = campUnitsCfg.get()?[unitId]
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