from "%globalsDarg/darg_library.nut" import *
let { unitsMaxRank, unitsTreeOpenRank } = require("%rGui/unitsTree/unitsTreeState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { playerLevelInfo, myUnits } = require("%appGlobals/pServer/profile.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkPlatoonPlateFrame,
  mkUnitsTreePrice, bgPlatesTranslate, mkUnitBlueprintMark, mkUnitResearchPrice,
  mkUnitSelectedGlow, mkUnitEquippedIcon, mkPlateText, plateTextsSmallPad, unitPlateTiny
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
let { selectedLineHor, selLineSize } = require("%rGui/components/selectedLine.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { justBoughtUnits, deleteJustBoughtUnit } = require("%rGui/unit/justUnlockedUnits.nut")
let { revealAnimation, raisePlatesAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { ceil } = require("math")
let { scrollToUnit, nodeToScroll } = require("unitsTreeScroll.nut")
let { unitsResearchStatus, filteredNodes } = require("unitsTreeNodesState.nut")
let { mkPlateExpBar, plateBarHeight } = require("unitResearchBar.nut")


let framesGapMul = 0.7
let scrollBlocks = ceil((saSize[0] - saBorders[0] - flagsWidth) / blockSize[0] / 2)
let selLineGap = hdpx(10)
let lockIconSize = hdpxi(34)

function mkPlatoonPlates(unit) {
  let { platoonUnits = [] } = unit
  let platoonSize = platoonUnits.len()
  let isLocked = Computed(@() (unit.name not in myUnits.get()) && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.get())
  let justBoughtDelay = Computed(@() justBoughtUnits.get()?[unit.name] != null ? 0.5 : null)

  return @() {
    watch = [isSelected, isLocked, justBoughtDelay]
    size = flex()
    children = platoonUnits?.map(@(_, idx) {
      size = flex()
      transform = {
        translate = bgPlatesTranslate(platoonSize, idx, isSelected.get() || (justBoughtDelay.get() != null), framesGapMul)
      }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      animations = raisePlatesAnimation(justBoughtDelay.get(),
        bgPlatesTranslate(platoonSize, idx, isSelected.get() || (justBoughtDelay.get() != null), framesGapMul), idx,
          platoonSize, @() deleteJustBoughtUnit(unit.name))
      children = [
        mkUnitBg(unit, isLocked.get())
        mkPlatoonPlateFrame(unit, isEquipped, isSelected)
        !justBoughtDelay.get() ? null : mkPlateText(loc(getUnitPresentation(platoonUnits?[platoonSize - idx - 1]).locId),
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
  let isLocked = Computed(@() (unit.name not in myUnits.get()) && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.get())
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let canBuyForLvlUp = Computed(@() playerLevelInfo.get().isReadyForLevelUp && (unit?.name in buyUnitsData.get().canBuyOnLvlUp))
  let price = Computed(@() canPurchase.get() ? getUnitAnyPrice(unit, canBuyForLvlUp.get(), unitDiscounts.get()) : null)
  let discount = Computed(@() unitDiscounts?.get()[unit.name])
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
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    xmbNode
    sound = { click  = "choose" }
    children = [
      mkPlatoonPlates(unit)
      mkUnitBg(unit, isLocked.get(), justUnlockedDelay.get())
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)), justUnlockedDelay.get())
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitBlueprintMark(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
      mkUnitLock(unit, isLocked.get(), justUnlockedDelay.get())
      mkPriorityUnseenMarkWatch(needShowUnseenMark)
      @() {
        watch = [price, discount]
        flow = FLOW_HORIZONTAL
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_BOTTOM
        children = [
          discount.get() != null ? discountTagUnit(discount.get().discount) : null
          price.get() != null && price.get().price > 0
              ? mkUnitsTreePrice(price.get(), justUnlockedDelay.get())
            : null
        ]
      }
      mkPlatoonPlateFrame(unit, isEquipped, isSelected, justUnlockedDelay.get())
      mkUnitEquippedIcon(unit, isEquipped, justUnlockedDelay.get())
      {
        size = flex()
        valign = ALIGN_BOTTOM
        pos = [0, selLineGap + selLineSize]
        children = selectedLineHor(isSelected, isPremium, isHidden)
      }
    ]
  }.__update(ovr)
}

function mkTreeNodesUnitPlate(unit, xmbNode, ovr = {}) {
  if (unit == null)
    return null

  let stateFlags = Watched(0)
  let researchStatus = Computed(@() unitsResearchStatus.get()?[unit.name])
  let isLocked = Computed(@() (unit.name not in myUnits.get()) && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let price = Computed(@() canPurchase.get() || (researchStatus.get()?.isResearched && unit.name not in myUnits.get())
      ? getUnitAnyPrice(unit, false, unitDiscounts.get())
    : null)
  let discount = Computed(@() unitDiscounts?.get()[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isHidden = unit?.isHidden
  let needShowPrice = Computed(@() isPremium || researchStatus.get()?.canBuy || researchStatus.get()?.isResearched)
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
  let needShowExpBar = Computed(@() !researchStatus.get()?.isResearched
    && (researchStatus.get()?.isCurrent || (researchStatus.get()?.exp ?? 0) > 0)
    && researchStatus.get().reqExp > 0)

  return @() {
    watch = [isSelected, isLocked, canPurchase, researchStatus, filteredNodes, needShowExpBar]
    size = unitPlateTiny
    behavior = Behaviors.Button
    function onClick() {
      curSelectedUnit.set(unit.name)
      scrollToUnit(unit.name, xmbNode)
      markUnitSeen(unit)
    }
    onAttach = unitsTreeOpenRank.get() != null
      && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
          ? nodeToScroll.set(xmbNode)
        : null
    onElemState = @(s) stateFlags(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    xmbNode
    sound = { click  = "choose" }
    children = [
      mkUnitBg(unit, isLocked.get(), null, filteredNodes.get()?[unit.name].isAvailable ?? true)
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitBlueprintMark(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
      researchStatus.get()?.canBuy || !researchStatus.get()?.isResearched ? mkUnitLock(unit, false) : {
        size = [lockIconSize, lockIconSize]
        margin = hdpx(10)
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        rendObj = ROBJ_IMAGE
        keepAspect = true
        image = Picture($"ui/gameuiskin#lock_icon.svg:{lockIconSize}:{lockIconSize}:P")
      }
      mkUnitResearchPrice(researchStatus.get())
      mkPriorityUnseenMarkWatch(needShowUnseenMark)
      @() {
        watch = [price, discount, needShowPrice]
        flow = FLOW_HORIZONTAL
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_BOTTOM
        children = !needShowPrice.get() ? null : [
          discount.get() != null ? discountTagUnit(discount.get().discount) : null
          price.get() != null && price.get().price > 0
              ? mkUnitsTreePrice(price.get())
            : null
        ]
      }
      !needShowExpBar.get() ? null : mkPlateExpBar(researchStatus.get())
      {
        size = flex()
        valign = ALIGN_BOTTOM
        pos = [0, selLineGap + selLineSize + (needShowExpBar.get() ? plateBarHeight : 0)]
        children = selectedLineHor(isSelected, isPremium, isHidden)
      }
    ]
  }.__update(ovr)
}

return {
  mkUnitPlate
  mkTreeNodesUnitPlate
  framesGapMul
}
