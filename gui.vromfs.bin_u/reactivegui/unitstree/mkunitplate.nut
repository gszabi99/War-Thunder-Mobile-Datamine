from "%globalsDarg/darg_library.nut" import *
let { unitsMaxRank, unitsTreeOpenRank } = require("%rGui/unitsTree/unitsTreeState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { playerLevelInfo, myUnits } = require("%appGlobals/pServer/profile.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkPlatoonPlateFrame,
  mkUnitsTreePrice, bgPlatesTranslate, mkUnitBlueprintMark,
  mkUnitSelectedGlow, mkUnitEquippedIcon, mkPlateText, plateTextsSmallPad
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId, getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { canBuyUnits, buyUnitsData } = require("%appGlobals/unitsState.nut")
let { flagsWidth, unitPlateSize, blockSize } = require("unitsTreeComps.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { discountTagUnit } = require("%rGui/components/discountTag.nut")
let { curSelectedUnit, curUnitName } = require("%rGui/unit/unitsWndState.nut")
let { unseenUnits, markUnitSeen } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { hasDataForLevelWnd, isSeen, isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { selectedLineHor } = require("%rGui/components/selectedLine.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { justBoughtUnits, deleteJustBoughtUnit } = require("%rGui/unit/justUnlockedUnits.nut")
let { revealAnimation, raisePlatesAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { ceil } = require("math")
let { scrollToUnit, nodeToScroll } = require("unitsTreeScroll.nut")


let framesGapMul = 0.7
let scrollBlocks = ceil((saSize[0] - saBorders[0] - flagsWidth) / blockSize[0] / 2)
let selLineGap = hdpx(10)

function mkPlatoonPlates(unit) {
  let { platoonUnits = [] } = unit
  let platoonSize = platoonUnits.len()
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let justBoughtDelay = Computed(@() justBoughtUnits.value?[unit.name] != null ? 0.5 : null)

  return @() {
    watch = [isSelected, isLocked, justBoughtDelay]
    size = flex()
    children = platoonUnits?.map(@(_, idx) {
      size = flex()
      transform = {
        translate = bgPlatesTranslate(platoonSize, idx, isSelected.value || (justBoughtDelay.get() != null), framesGapMul)
      }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      animations = raisePlatesAnimation(justBoughtDelay.value,
        bgPlatesTranslate(platoonSize, idx, isSelected.value || (justBoughtDelay.get() != null), framesGapMul), idx,
          platoonSize, @() deleteJustBoughtUnit(unit.name))
      children = [
        mkUnitBg(unit, isLocked.get())
        mkPlatoonPlateFrame(unit, isEquipped, isSelected)
        !justBoughtDelay.value ? null : mkPlateText(loc(getUnitPresentation(platoonUnits?[platoonSize - idx - 1]).locId),
          {
            vplace = ALIGN_TOP
            hplace = ALIGN_RIGHT
            padding = plateTextsSmallPad
            animations = revealAnimation()
            maxWidth = unitPlateSize[0]
          })
      ]
    })
  }
}

function mkUnitPlate(unit, xmbNode, ovr = {}) {
  if (unit == null)
    return null

  let stateFlags = Watched(0)
  let isLocked = Computed(@() (unit.name not in myUnits.value) && (unit.name not in canBuyUnits.value))
  let isSelected = Computed(@() curSelectedUnit.value == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.value)
  let canPurchase = Computed(@() unit.name in canBuyUnits.value)
  let canBuyForLvlUp = Computed(@() playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp))
  let price = Computed(@() canPurchase.value ? getUnitAnyPrice(unit, canBuyForLvlUp.value, unitDiscounts.value) : null)
  let discount = Computed(@() unitDiscounts?.value[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isHidden = unit?.isHidden
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
  let justUnlockedDelay = Computed(@() hasModalWindows.get() && canBuyForLvlUp.get()
      ? 1000000.0
    : canBuyForLvlUp.get()
        && hasDataForLevelWnd.get()
        && !hasModalWindows.get()
        && !isSeen.get()
      ? 1.0
    : null)

  return @() {
    watch = [isSelected, isLocked, canPurchase, justUnlockedDelay]
    size = unitPlateSize
    behavior = Behaviors.Button
    function onClick() {
      if (isLvlUpAnimated.get())
        return
      curSelectedUnit.set(unit.name)
      scrollToUnit(unit.name, xmbNode)
      markUnitSeen(unit)
    }
    onAttach = unitsTreeOpenRank.get() != null
      && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
          ? nodeToScroll.set(xmbNode)
        : null
    onElemState = @(s) stateFlags(s)
    clickableInfo = isSelected.value ? { skipDescription = true } : loc("mainmenu/btnSelect")
    xmbNode
    sound = { click  = "choose" }
    children = [
      mkPlatoonPlates(unit)
      mkUnitBg(unit, isLocked.get(), justUnlockedDelay.get())
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.value & S_HOVER)), justUnlockedDelay.get())
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitBlueprintMark(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
      mkUnitLock(unit, isLocked.value, justUnlockedDelay.get())
      mkPriorityUnseenMarkWatch(needShowUnseenMark)
      @() {
        watch = [price, discount, justUnlockedDelay]
        flow = FLOW_HORIZONTAL
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_BOTTOM
        children = [
          discount.value != null ? discountTagUnit(discount.value.discount) : null
          price.get() != null && price.get().price > 0 ? mkUnitsTreePrice(price.get(), justUnlockedDelay.get()) : null
        ]
      }
      mkPlatoonPlateFrame(unit, isEquipped, isSelected, justUnlockedDelay.get())
      mkUnitEquippedIcon(unit, isEquipped, justUnlockedDelay.get())
      {
        size = flex()
        pos = [0, unitPlateSize[1] + selLineGap]
        children = selectedLineHor(isSelected, isPremium, isHidden)
      }
    ]
  }.__update(ovr)
}

return {
  mkUnitPlate
  framesGapMul
}
