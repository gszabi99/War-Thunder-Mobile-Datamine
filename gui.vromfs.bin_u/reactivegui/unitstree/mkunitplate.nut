from "%globalsDarg/darg_library.nut" import *
let { unitsMaxRank, unitsTreeOpenRank } = require("%rGui/unitsTree/unitsTreeState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { playerLevelInfo, myUnits } = require("%appGlobals/pServer/profile.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkPlatoonPlateFrame,
  mkUnitsTreePrice, bgPlatesTranslate, mkUnitBlueprintMark, mkUnitResearchPrice,
  mkUnitSelectedGlow, mkUnitEquippedIcon, mkPlateText, plateTextsSmallPad, unitPlateTiny
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
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
let { selectedLineHorUnits, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { justBoughtUnits, deleteJustBoughtUnit } = require("%rGui/unit/justUnlockedUnits.nut")
let { revealAnimation, raisePlatesAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { ceil } = require("math")
let { scrollToUnit, nodeToScroll } = require("unitsTreeScroll.nut")
let { unitsResearchStatus, filteredNodes } = require("unitsTreeNodesState.nut")
let { mkPlateExpBar, mkPlateBlueprintBar } = require("unitResearchBar.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let framesGapMul = 0.7
let scrollBlocks = ceil((saSize[0] - saBorders[0] - flagsWidth) / blockSize[0] / 2)

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
  let isCollectible = unit?.isCollectible
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
      unit.platoonUnits.len() == 0 ?{
        size = flex()
        valign = ALIGN_TOP
        pos = [0, -selLineSize]
        children = selectedLineHorUnits(isSelected, isPremium, isCollectible)
      } : null
    ]
  }.__update(ovr)
}

let treeNodeUnitPlateKey = @(name) name == null ? null : $"treeNodeUnitPlate:{name}"

function mkTreeNodesUnitPlate(unit, xmbNode, ovr = {}) {
  if (unit == null)
    return null

  let stateFlags = Watched(0)
  let researchStatus = Computed(@() unitsResearchStatus.get()?[unit.name])
  let isOwned = Computed(@() unit.name in myUnits.get())
  let isLocked = Computed(@() !isOwned.get() && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let price = Computed(@() canPurchase.get() || (researchStatus.get()?.isResearched && unit.name not in myUnits.get())
      ? getUnitAnyPrice(unit, false, unitDiscounts.get())
    : null)
  let discount = Computed(@() unitDiscounts?.get()[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isCollectible = unit?.isCollectible
  let needShowPrice = Computed(@() isPremium || researchStatus.get()?.canBuy || researchStatus.get()?.isResearched)
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
  let needShowBlueprintBar = Computed(@() unit.name in serverConfigs.get()?.allBlueprints && unit.name not in myUnits.get())

  return @() {
    watch = [isSelected, isOwned, isLocked, canPurchase, researchStatus, filteredNodes,
      needShowBlueprintBar]
    size = unitPlateTiny
    behavior = Behaviors.Button
    function onClick() {
      curSelectedUnit.set(unit.name)
      scrollToUnit(unit.name, xmbNode)
      markUnitSeen(unit)
    }
    key = treeNodeUnitPlateKey(unit.name)
    onAttach = unitsTreeOpenRank.get() != null
      && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
          ? nodeToScroll.set(xmbNode)
        : null
    onElemState = @(s) stateFlags(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    xmbNode
    sound = { click  = "choose" }
    children = [
      mkUnitBg(unit, isLocked.get(), null, isOwned.get() || (filteredNodes.get()?[unit.name].isAvailable ?? true))
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
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
      {
        size = flex()
        valign = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        children = [
          {
            size = [flex(), hdpx(40)]
            padding = plateTextsSmallPad
            valign = ALIGN_BOTTOM
            flow = FLOW_HORIZONTAL
            children = [
              needShowBlueprintBar.get()
                  ? mkUnitBlueprintMark(unit)
                : !researchStatus.get()?.isResearched
                  ? mkUnitResearchPrice(researchStatus.get(), { padding = 0 })
                : null
              { size = flex() }
              mkGradRank(unit.mRank, { pos = [0, hdpx(7)] })
            ]
          }
          needShowBlueprintBar.get()
              ? mkPlateBlueprintBar(unit)
            : !researchStatus.get()?.isResearched
              ? mkPlateExpBar(researchStatus.get())
            : null
        ]
      }
      {
        size = flex()
        valign = ALIGN_TOP
        pos = [0, -selLineSize]
        children = selectedLineHorUnits(isSelected, isPremium, isCollectible)
      }
    ]
  }.__update(ovr)
}

return {
  mkUnitPlate
  mkTreeNodesUnitPlate
  framesGapMul
  treeNodeUnitPlateKey
}
