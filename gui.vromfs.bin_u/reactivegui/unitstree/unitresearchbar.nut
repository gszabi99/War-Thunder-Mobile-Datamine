from "%globalsDarg/darg_library.nut" import *
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { unitsResearchStatus } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { hasUnitInSlot } = require("%rGui/slotBar/slotBarState.nut")


let plateBarHeight = hdpx(15)
let barHeight = hdpx(30)
let bgColor = 0x80000000
let borderWidth = hdpx(2)
let expColor = 0xFFE86C00

let mkAnimatedBar = @(completion, isShaded = false) [
  {
    rendObj = ROBJ_SOLID
    size = flex()
    color = expColor
    brightness = isShaded ? 0.4 : 2.0
    transform = {
      scale = [completion, 1.0]
      pivot = [0, 0]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
  {
    rendObj = ROBJ_SOLID
    size = flex()
    color = expColor
    brightness = isShaded ? 0.4 : 1.0
    transform = {
      scale = [completion, 1.0]
      pivot = [0, 0]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.5, easing = InOutQuad }]
  }
]

let function mkPlateExpBar(researchStatus) {
  let { exp = 0, reqExp = 0, isCurrent = false } = researchStatus
  return {
    rendObj = ROBJ_SOLID
    size = [pw(100), plateBarHeight]
    vplace = ALIGN_BOTTOM
    pos = [0, plateBarHeight]
    color = bgColor
    children = mkAnimatedBar(max(0.01, exp.tofloat() / reqExp), !isCurrent)
  }
}

let function mkExpBar(unitResearch) {
  let { exp = 0, reqExp = 1, isCurrent = false, isAvailable = false, isResearched = false } = unitResearch
  if (!isCurrent && !(isAvailable && !isResearched))
    return null
  return {
    rendObj = ROBJ_BOX
    size = [statsWidth, barHeight]
    fillColor = bgColor
    borderWidth
    borderColor = 0xFFFFFFFF
    children = mkAnimatedBar(exp.tofloat() / reqExp).append({
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      padding = [0, 0, 0, hdpx(10)]
      text = $"{exp} / {reqExp}"
    }.__update(fontVeryTinyShaded))
  }
}

let function mkResearchHint(unitResearch, hasInSlot) {
  let { isCurrent = false, isAvailable = false, isResearched = false } = unitResearch
  return {
    size = [statsWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = loc(isCurrent ? "unitsTree/currentResearch"
      : isAvailable && !isResearched ? "unitsTree/availableForResearch"
      : isResearched ? "unitsTree/buyHint"
      : hasInSlot ? "slotbar/installedUnit"
      : "unitsTree/researchHint")
  }.__update(fontTinyAccented)
}

let function unitResearchBar() {
  let unitsResearch = Computed(@() unitsResearchStatus.get()?[curSelectedUnit.get()])
  if (!unitsResearch.get() || unitsResearch.get()?.canBuy
      || (curSelectedUnit.get() in myUnits.get() && !hasUnitInSlot(curSelectedUnit.get())))
    return null
  return @() {
    watch = [curSelectedUnit, unitsResearch, myUnits]
    size = [flex(), SIZE_TO_CONTENT]
    pos = [- hdpx(45), - defButtonHeight - hdpx(60)]
    halign = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      mkResearchHint(unitsResearch.get(), hasUnitInSlot(curSelectedUnit.get()))
      mkExpBar(unitsResearch.get())
    ]
  }
}

return {
  unitResearchBar
  mkPlateExpBar
  plateBarHeight
}
