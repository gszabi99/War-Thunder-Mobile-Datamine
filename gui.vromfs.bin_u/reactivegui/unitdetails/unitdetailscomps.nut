from "%globalsDarg/darg_library.nut" import *
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { scaleAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { justUnlockedPlatoonUnits } = require("%rGui/unit/justUnlockedPlatoonUnits.nut")
let { unitPlateWidth, unitPlateHeight, unitPlatesGap, mkUnitInfo
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine
} = require("%rGui/unit/components/unitPlateComp.nut")
let { selectedLineHorUnitsCustomSize, selLineSize } = require("%rGui/components/selectedLineUnits.nut")


let UNIT_DELAY = 1.5
let UNIT_SCALE = 1.2
function mkUnitPlate(unit, platoonUnit, unitToShow, onClick) {
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isPremium = !!(unit?.isPremium || unit?.isUpgraded)
  let isSelected = Computed(@() unitToShow.get()?.name == platoonUnit.name)
  let isLocked = Computed(@() !isPremium && platoonUnit.reqLevel > (campMyUnits.get()?[unit.name].level ?? 0))
  let justUnlockedDelay = Computed(@() justUnlockedPlatoonUnits.get().indexof(platoonUnit.name) != null ? UNIT_DELAY : null)
  let isCollectible = unit?.isCollectible
  return @() {
    watch = [isLocked, justUnlockedDelay]
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      {
        key = {}
        size = [ unitPlateWidth, unitPlateHeight ]
        transform = {}
        animations = scaleAnimation(justUnlockedDelay.get(), [UNIT_SCALE, UNIT_SCALE])
        children = [
          {
            size = flex()
            valign = ALIGN_TOP
            pos = [0, -2 * selLineSize]
            children = selectedLineHorUnitsCustomSize([flex(), 2*selLineSize], isSelected, isPremium, isCollectible)
          }
          mkUnitBg(unit, isLocked.get(), justUnlockedDelay.get())
          mkUnitSelectedGlow(unit, isSelected, justUnlockedDelay.get())
          mkUnitImage(platoonUnitFull, isLocked.get())
          mkUnitTexts(platoonUnitFull, loc(p.locId), isLocked.get())
          !isLocked.get() ? mkUnitInfo(unit, { pos = [-hdpx(30), 0] }) : null
          mkUnitSlotLockedLine(platoonUnit, isLocked.get(), justUnlockedDelay.get())
        ]
      }
    ]
  }
}

let mkPlatoonUnitsBlock = @(baseUnit, platoonUnitsList, unitToShow, onClick) function() {
  let res = { watch = [ baseUnit, platoonUnitsList ] }
  return platoonUnitsList.get().len() == 0
    ? res
    : res.__update({
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = platoonUnitsList.get()
          .map(@(pu) mkUnitPlate(baseUnit.get(), pu, unitToShow, @() onClick(pu.name)))
      })
}


return {
  mkPlatoonUnitsBlock
}