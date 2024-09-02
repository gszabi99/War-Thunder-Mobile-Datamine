from "%globalsDarg/darg_library.nut" import *
let { unitsMaxRank, unitsTreeOpenRank } = require("%rGui/unitsTree/unitsTreeState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { playerLevelInfo, myUnits } = require("%appGlobals/pServer/profile.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkPlatoonPlateFrame,
  mkUnitsTreePrice, bgPlatesTranslate, mkUnitBlueprintMark, mkUnitResearchPrice,
  mkUnitSelectedGlow, mkUnitEquippedIcon, mkPlateText, plateTextsSmallPad, unitPlateTiny,
  bgUnit, bgUnitNotAvailable, mkUnitBgPremium, unitBgImageBase
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
let { unitsResearchStatus, researchCountry, currentResearch } = require("unitsTreeNodesState.nut")
let { mkPlateExpBar, mkPlateBlueprintBar, mkPlateExpBarAnimSlot, plateBarHeight } = require("unitResearchBar.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { animUnitAfterResearch, needShowPriceUnit, animExpPart, animNewUnitsAfterResearch,
  animNewUnitsAfterResearchTrigger, hasAnimDarkScreen, unitsForExpAnim, isBuyUnitWndOpened } = require("animState.nut")
let { animUnitSlot, mkUnitResearchPriceAnim, priceAnimDuration } = require("%rGui/unitsTree/components/unitPlateAnimations.nut")
let { PURCH_SRC_UNITS, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let unitBuyWnd = require("%rGui/unitsTree/components/unitBuyWnd.nut")
let { aDelayPrice, aTimePriceScale, aTimePriceShake } = require("%rGui/unitsTree/treeAnimConsts.nut")

let framesGapMul = 0.7
let scrollBlocks = ceil((saSize[0] - saBorders[0] - flagsWidth) / blockSize[0] / 2)

let highlighCurrentResearch = mkColoredGradientY(0x20A0A0A0, 0)

let aTimeUnitFromRed = 0.25
let aTimeUnitToGrey = 0.25
let aTimeUnitScaleUp = 0.25
let aTimeUnitScaleDown = 0.25
let aTimeUnitAppearBar = 0.6
let aTimeUnitAppearPrice = 0.1
let aTimeUnitScalePrice = 0.5

let aDelayUnitToGrey = aTimeUnitFromRed
let aDelayUnitScaleUp = aDelayUnitToGrey + aTimeUnitToGrey
let aDelayUnitScaleDown = aDelayUnitScaleUp + aTimeUnitScaleUp
let aDelayUnitAppearBar = aDelayUnitScaleDown + aTimeUnitScaleDown
let aDelayUnitAppearPrice = aDelayUnitAppearBar
let aDelayUnitScalePrice = aDelayUnitAppearBar + aTimeUnitAppearPrice

let totalATime = aDelayUnitScalePrice + aTimeUnitScalePrice

function triggerAnim() {
  anim_start(animNewUnitsAfterResearchTrigger)
  isBuyUnitWndOpened.set(false)
}

function openBuyUnitWnd(name) {
  let researchStatus = unitsResearchStatus.get()?[name]
  if (researchStatus?.canBuy) {
    let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, name)
    purchaseUnit(name, bqPurchaseInfo, null, null, unitBuyWnd(name), loc("unitsTree/researchCompleted"),
      @() triggerAnim())
  } else
    triggerAnim()
}

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
      mkUnitBlueprintMark(unit, {
        pos = [0, -plateBarHeight]
        padding = hdpx(7)
      })
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
      mkUnitLock(unit, isLocked.get(), justUnlockedDelay.get())
      mkPriorityUnseenMarkWatch(needShowUnseenMark)
      mkPlateBlueprintBar(unit, {
        pos = [0, 0]
      })
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

let mkTreeNodesUnitPlateSpeedUpAnim = @(unit, price, discount, researchStatus, xmbNode, ovr) {
  children = {
    key = treeNodeUnitPlateKey(unit.name)
    size = unitPlateTiny
    function onAttach(){
      scrollToUnit(unit.name, xmbNode)
    }
    xmbNode
    children = [
      mkUnitBg(unit)
      {
        size = flex()
        padding = hdpx(7)
        children = mkUnitImage(unit, true)
      }
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      @() {
        watch = needShowPriceUnit
        vplace = ALIGN_BOTTOM
        children = [
          needShowPriceUnit.get() ? null
            : {
              flow = FLOW_VERTICAL
              gap = hdpx(7)
              children = [
                @() {
                  watch = animUnitAfterResearch
                  size = [flex(), SIZE_TO_CONTENT]
                  padding = plateTextsSmallPad
                  flow = FLOW_HORIZONTAL
                  children = mkUnitResearchPriceAnim(researchStatus.get(), { padding = 0 })
                }
                @() {
                  watch = animExpPart
                  size = flex()
                  rendObj = ROBJ_SOLID
                  valign = ALIGN_BOTTOM
                  color = 0xFF000000
                  children = mkPlateExpBarAnimSlot(animExpPart.get())
                }
              ]
            }
          !needShowPriceUnit.get() ? null
            : @() {
              watch = [price, discount]
              padding = hdpx(10)
              flow = FLOW_HORIZONTAL
              hplace = ALIGN_LEFT
              vplace = ALIGN_BOTTOM
              valign = ALIGN_BOTTOM
              children = {
                children = [
                  discount.get() != null ? discountTagUnit(discount.get().discount) : null
                  price.get() != null && price.get().price > 0
                      ? mkUnitsTreePrice(price.get())
                    : null
                ]
                transform = {}
                animations = [
                  {
                    prop = AnimProp.scale, from = [1, 1], to = [1.3, 1.3], duration = priceAnimDuration, play = true,
                    easing = CosineFull, trigger = "startWpAnim",
                    function onFinish() {
                      isBuyUnitWndOpened.set(true)
                      animUnitAfterResearch.set(null)
                      needShowPriceUnit.set(false)
                      resetTimeout(0.1, @() openBuyUnitWnd(unit.name))
                      unitsForExpAnim.mutate(@(v) v.$rawdelete(unit.name))
                    }
                  }
                ]
              }
            }
        ]
      }
    ]
    transform = {}
    animations = animUnitSlot(unit.name)
  }
}.__update(ovr)

let mkUnitGradRank = @(rank) {
  padding = hdpx(10)
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = mkGradRank(rank)
}

let hasChangedColor = Watched(false)
let mkUnitAnimGradColor = @(unit, animUnits, xmbNode, trigger) @() unitBgImageBase.__merge({
  watch = hasChangedColor,
  image = hasChangedColor.get() ? bgUnit : bgUnitNotAvailable,
  onAttach = @() hasChangedColor.set(false),
  onDetach = @() hasChangedColor.set(false),
  animations = [{
    trigger, prop = AnimProp.brightness, from = 1, to = 0,
    duration = aTimeUnitFromRed, easing = InQuad, onFinish = @() hasChangedColor.set(true),
    onStart = @() animUnits.values()?[ceil(animUnits.len() / 2.0) - 1] != unit.name ? null
      : scrollToUnit(unit.name, xmbNode)
  }, {
    trigger, prop = AnimProp.brightness, from = 0, to = 1,
    duration = aTimeUnitToGrey, easing = OutQuad, delay = aDelayUnitToGrey
  }],
})

function mkTreeNodesUnitPlateUnlockAnim(unit, xmbNode, ovr = {}) {
  let isPremium = unit.isPremium || unit?.isUpgraded
  let trigger = animNewUnitsAfterResearchTrigger
  return {
    children = {
      key = treeNodeUnitPlateKey(unit.name)
      size = unitPlateTiny
      xmbNode
      children = [
        {
          size = flex()
          children = [
            mkUnitAnimGradColor(unit, animNewUnitsAfterResearch.get(), xmbNode, trigger)
            !isPremium ? null : mkUnitBgPremium
          ]
        }
        mkUnitImage(unit, true)
        mkUnitTexts(unit, loc(getUnitLocId(unit.name)), true)
        mkUnitGradRank(unit.mRank)
        {
          size = flex()
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          children = [
            {
              size = [SIZE_TO_CONTENT, hdpx(40)]
              padding = plateTextsSmallPad
              valign = ALIGN_BOTTOM
              flow = FLOW_HORIZONTAL
              transform = {}
              opacity = 0
              children = mkUnitResearchPrice(unitsResearchStatus.get()?[unit.name], { padding = 0 })
              animations = [{
                trigger, delay = aDelayUnitAppearPrice, prop = AnimProp.opacity, from = 0, to = 1,
                duration = aTimeUnitAppearPrice, easing = InQuad
              }, {
                trigger, prop = AnimProp.opacity, from = 1, to = 1, delay = aDelayUnitAppearPrice + aTimeUnitAppearPrice,
                duration = totalATime - (aDelayUnitAppearPrice + aTimeUnitAppearPrice)
              }, {
                trigger, delay = aDelayUnitScalePrice, prop = AnimProp.scale, from = [1, 1], to = [1.3, 1.3],
                duration = aTimeUnitScalePrice, easing = CosineFull,
                function onFinish() {
                  animNewUnitsAfterResearch.set({})
                  hasAnimDarkScreen.set(true)
                }
              }]
            }
            {
              size = [flex(), SIZE_TO_CONTENT]
              opacity = 0
              children = mkPlateExpBar(unitsResearchStatus.get()?[unit.name])
              animations = [
                { trigger, delay = aDelayUnitAppearBar, prop = AnimProp.opacity, from = 0, to = 1,
                  duration = aTimeUnitAppearBar, easing = InQuad },
                { trigger, prop = AnimProp.opacity, from = 1, to = 1, delay = aDelayUnitAppearBar + aTimeUnitAppearBar,
                  duration = totalATime - (aDelayUnitAppearBar + aTimeUnitAppearBar) }
              ]
            }
          ]
        }
      ]
    }
    transform = {}
    animations = [
      {
        trigger, delay = aDelayUnitScaleUp, prop = AnimProp.scale, easing = InQuad
        from = [1.0, 1.0], to = [1.15, 1.15], duration = aTimeUnitScaleUp
      },
      {
        trigger, delay = aDelayUnitScaleDown, prop = AnimProp.scale, easing = OutQuad
        from = [1.15, 1.15], to = [1.0, 1.0], duration = aTimeUnitScaleDown
      }
    ]
  }.__update(ovr)
}

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
  let needShowPrice = Computed(@() researchStatus.get()?.isResearched && unit.name not in myUnits.get())
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get() || unit.name in unseenSkins.get())
  let needShowBlueprintBar = Computed(@() unit.name in serverConfigs.get()?.allBlueprints && unit.name not in myUnits.get())
  let trigger = $"{unit.name}_anim"
  let startCurAnim = @() anim_start(trigger)
  let needToShowHighlight = Computed(@() animNewUnitsAfterResearch.get().len() == 0
    && (currentResearch.get() ? currentResearch.get().name == unit.name : researchStatus.get()?.canResearch))
  return @() animUnitAfterResearch.get() == unit.name
      ? mkTreeNodesUnitPlateSpeedUpAnim(unit, price, discount, researchStatus, xmbNode,
        ovr.__merge({ watch = animUnitAfterResearch }))
    : animNewUnitsAfterResearch.get()?[unit.name]
      ? mkTreeNodesUnitPlateUnlockAnim(unit, xmbNode, ovr.__merge({ watch = animNewUnitsAfterResearch }))
    : {
      watch = [isSelected, isOwned, isLocked, canPurchase, researchStatus, needShowBlueprintBar,
        researchCountry, needToShowHighlight, animUnitAfterResearch, animNewUnitsAfterResearch]
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
        mkUnitBg(unit, isLocked.get(), null,
          !isLocked.get() || (researchStatus.get()?.canResearch ?? false) || (researchStatus.get()?.isResearched ?? false))
        mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
        needToShowHighlight.get()
          ? {
              key = unit.name
              size = [flex(), ph(70)]
              rendObj = ROBJ_IMAGE
              vplace = ALIGN_TOP
              image = highlighCurrentResearch
              transform = {}
              opacity = 0
              onDetach = @() clearTimer(startCurAnim)
              animations = [
                {
                  prop = AnimProp.opacity, from = 0.0, to = 0.3, trigger, duration = 1, play = true,
                  easing = CosineFull, onFinish = @() resetTimeout(1, startCurAnim)
                }
              ]
          }
          : null
        mkUnitImage(unit, canPurchase.get() || isLocked.get())
        mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
        mkPriorityUnseenMarkWatch(needShowUnseenMark)
        @() {
          padding = hdpx(10)
          watch = [price, discount, needShowPrice, researchStatus]
          key = price
          flow = FLOW_HORIZONTAL
          hplace = ALIGN_LEFT
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          children = !needShowPrice.get() ? null : [
            discount.get() != null ? discountTagUnit(discount.get().discount) : null
            price.get() != null && price.get().price > 0
                ? mkUnitsTreePrice(price.get(), null, researchStatus.get()?.canBuy)
              : null
          ]
          transform = {}
          animations = [
            { prop = AnimProp.rotate, to = 8, duration = aTimePriceShake, easing = Shake6,
              trigger = $"unit_price_{unit.name}", delay = aDelayPrice }
            { prop = AnimProp.scale, to = [1.2, 1.2], duration = aTimePriceScale, easing = CosineFull,
              trigger = $"unit_price_{unit.name}", delay = aDelayPrice }
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
                  : mkUnitResearchPrice(researchStatus.get(), { padding = 0 })
              ]
            }
            needShowBlueprintBar.get()
                ? mkPlateBlueprintBar(unit)
              : researchStatus.get()?.canResearch
                ? mkPlateExpBar(researchStatus.get())
              : null
          ]
        }
        mkUnitGradRank(unit.mRank)
        {
          size = flex()
          valign = ALIGN_TOP
          pos = [0, -selLineSize]
          children = selectedLineHorUnits(isSelected, isPremium, isCollectible)
        }
        @() researchStatus.get()?.isCurrent
          ? {
              watch = researchStatus
              size = [unitPlateTiny[0] + hdpxi(8), unitPlateTiny[1]]
              rendObj = ROBJ_BOX
              hplace = ALIGN_CENTER
              fillColor = 0
              borderColor = 0xFFFFFFFF
              borderWidth = hdpxi(2)
          }
          : {watch = researchStatus}
      ]
      transform = {}
      animations = [
        { prop = AnimProp.rotate, to = 2, duration = aTimePriceShake, easing = Shake4,
          trigger = $"unit_exp_{unit.name}", delay = aDelayPrice }
        { prop = AnimProp.scale, to = [1.1, 1.1], duration = aTimePriceScale, easing = CosineFull,
          trigger = $"unit_exp_{unit.name}", delay = aDelayPrice }
      ]
    }.__update(ovr)
}

return {
  mkUnitPlate
  mkTreeNodesUnitPlate
  framesGapMul
  treeNodeUnitPlateKey
}
