from "%globalsDarg/darg_library.nut" import *
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitsResearchStatus } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitResearchPrice,
  mkUnitSelectedGlow, unitPlateTiny, mkIcon
} = require("%rGui/unit/components/unitPlateComp.nut")
let { selectedLineHorUnits, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let { mkPlateExpBar, mkPlateBlueprintBar } = require("%rGui/unitsTree/unitResearchBar.nut")
let { mkGradRankSmall } = require("%rGui/components/gradTexts.nut")

let sectorSizeCommon = [hdpx(20), hdpx(10)]
let sectorColorLight = 0xFF6EFF95
let sectorColorDark = 0xFF77B480
let gapCommon = hdpx(-10)

let sectorProgBar = @(color, size = sectorSizeCommon){
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#progress_bar_animated.svg:{size[0]}:{size[1]}:P")
  color
}

function progressBar(width, sectorSize){
  let children = []
  for (local i = 0; i < 3 * width / sectorSize[0]; i++){
    children.append(sectorProgBar(i % 2 == 0 ? sectorColorLight : sectorColorDark, sectorSize))
  }
  return children
}

function animatedProgressBar(unit, style = {}, childOvr = {}){
  let { width = unitPlateTiny[0], height = sectorSizeCommon[1], gap = gapCommon, sectorSize = sectorSizeCommon } = style
  let researchStatus = unitsResearchStatus.get()?[unit.name]
  return {
    size = [width, height]
    clipChildren = true
    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        gap
        children = progressBar(width, sectorSize)
        transform = {}
        animations = [
          { prop = AnimProp.translate, from = [-sectorSize[0], 0], to = [0, 0],
            duration = 1.0, play = true, loop = true, globalTimer = true }
        ]
      }
      researchStatus
        ? mkPlateExpBar(researchStatus, { color = 0 })
        : mkPlateBlueprintBar(unit, { size = flex() pos = [0, 0] color = 0 })
    ].append(childOvr)
  }
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

function mkTreeNodesUnitPlateSimple(unit, unitSize = unitPlateTiny) {
  let researchStatus = unitsResearchStatus.get()?[unit.name]
  return @() {
    flow = FLOW_VERTICAL
    children = [
      {
        size = unitSize
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
                size = FLEX_H
                flow = FLOW_HORIZONTAL
                padding = const [0, hdpx(5), 0 , 0]
                children = [
                  mkUnitResearchPrice(researchStatus, Watched(false))
                  {size = flex()}
                  mkGradRankSmall(unit?.mRank)
                ]
              }
              animatedProgressBar(unit)
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
        size = FLEX_H
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
  animatedProgressBar
  mkTreeNodesUnitPlateSimple
  mkTreeNodesUnitPlateBuy
}