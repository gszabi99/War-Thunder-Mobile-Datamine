from "%globalsDarg/darg_library.nut" import *
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitsResearchStatus } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitResearchPrice,
  mkUnitSelectedGlow, unitPlateTiny, mkIcon
} = require("%rGui/unit/components/unitPlateComp.nut")
let { selectedLineHorUnits, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let { mkPlateExpBar } = require("%rGui/unitsTree/unitResearchBar.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")

let sectorSize = [hdpx(20), hdpx(10)]
let sectorColorLight = 0xFF6EFF95
let sectorColorDark = 0xFF77B480

let sectorProgBar = @(color){
  size = sectorSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#progress_bar_animated.svg")
  color
}

function progressBar(){
  let children = []
  for (local i = 0; i < 3 * unitPlateTiny[0] / sectorSize[0]; i++){
    children.append(sectorProgBar(i % 2 == 0 ? sectorColorLight : sectorColorDark))
  }
  return children
}

let animatedProgressBar = @(researchStatus){
  size = [unitPlateTiny[0], sectorSize[1]]
  clipChildren = true
  children = [
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      gap = hdpx(-10)
      children = progressBar()
      transform = {}
      animations = [
        { prop = AnimProp.translate, from = [-sectorSize[0], 0], to = [0, 0],
          duration = 1.0, play = true, loop = true, globalTimer = true }
      ]
    }
    mkPlateExpBar(researchStatus, { color = 0 })
  ]
}

let mkTreeNodesUnitPlateBuy = @(unit){
  size = unitPlateTiny
  padding = hdpx(7)
  children = [
    mkUnitBg(unit)
    mkUnitImage(unit)
    mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
    {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = mkGradRankSmall(unit?.mRank)
    }
  ]
}

function mkTreeNodesUnitPlateSimple(unit) {
  let researchStatus = unitsResearchStatus.get()?[unit.name]
  return @() {
    flow = FLOW_VERTICAL
    children = [
      {
        size = unitPlateTiny
        children = [
          mkUnitBg(unit)
          mkUnitSelectedGlow(unit, Watched(true))
          mkUnitImage(unit)
          mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
          {
            size = flex()
            valign = ALIGN_BOTTOM
            flow = FLOW_VERTICAL
            children = [
              {
                size = [flex(), SIZE_TO_CONTENT]
                flow = FLOW_HORIZONTAL
                padding = [0, hdpx(5), 0 , 0]
                children = [
                  mkUnitResearchPrice(researchStatus, Watched(false))
                  {size = flex()}
                  mkGradRankSmall(unit?.mRank)
                ]
              }
              animatedProgressBar(researchStatus)
            ]
          }
          {
            size = flex()
            valign = ALIGN_TOP
            pos = [0, -selLineSize]
            children = selectedLineHorUnits(Watched(true), unit?.isPremium, unit?.isCollectible)
          }
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_RIGHT
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(5)
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "+"
          }.__update(fontVeryTinyAccented)
          mkIcon("ui/gameuiskin#unit_exp_icon.svg", [hdpxi(28), hdpxi(28)])
          {
            rendObj = ROBJ_TEXT
            text = (researchStatus?.reqExp ?? 0)  - (researchStatus?.exp ?? 0)
          }.__update(fontVeryTinyAccented)
        ]
      }
    ]
  }
}

return {
  mkTreeNodesUnitPlateSimple
  mkTreeNodesUnitPlateBuy
}