from "%globalsDarg/darg_library.nut" import *
let { unitsMaxRank, unitsTreeOpenRank } = require("%rGui/unitsTree/unitsTreeState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { isCampaignWithSlots } = require("%appGlobals/pServer/slots.nut")
let { playerLevelInfo, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkPlatoonPlateFrame,
  mkUnitsTreePrice, bgPlatesTranslate, mkUnitBlueprintMark, mkUnitResearchPrice,
  mkUnitSelectedGlow, mkUnitEquippedIcon, plateTextsSmallPad, unitPlateTiny,
  bgUnit, bgUnitNotAvailable, mkUnitBgPremium, unitBgImageBase, mkUnitInfo, mkProfileUnitDailyBonus
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { canBuyUnits, buyUnitsData } = require("%appGlobals/unitsState.nut")
let { flagsWidth, unitPlateSize, blockSize } = require("%rGui/unitsTree/unitsTreeComps.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { discountTagUnitSmall } = require("%rGui/components/discountTag.nut")
let { curSelectedUnit, curUnitName } = require("%rGui/unit/unitsWndState.nut")
let { unseenUnits, markUnitSeen } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitCustom/unitSkins/unseenSkins.nut")
let { mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature, priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { isLvlUpAnimated } = require("%rGui/levelUp/levelUpState.nut")
let { selectedLineHorUnits, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let { ceil } = require("math")
let { nodeToScroll } = require("%rGui/unitsTree/unitsTreeScroll.nut")
let { unitsResearchStatus, researchCountry, currentResearch, blueprintUnitsStatus,
  unseenResearchedUnits, selectedCountry } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { mkPlateExpBar, mkPlateBlueprintBar, mkPlateExpBarAnimSlot, plateBarHeight } = require("%rGui/unitsTree/unitResearchBar.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { animUnitAfterResearch, needShowPriceUnit, animExpPart, animNewUnitsAfterResearch, needDelayAnimation, loadStatusesAnimUnits,
  animNewUnitsAfterResearchTrigger, hasAnimDarkScreen, unitsForExpAnim, isBuyUnitWndOpened, canPlayAnimUnitAfterResearch
} = require("%rGui/unitsTree/animState.nut")
let { animUnitSlot, mkUnitResearchPriceAnim, priceAnimDuration } = require("%rGui/unitsTree/components/unitPlateAnimations.nut")
let { PURCH_SRC_UNITS, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let unitBuyWnd = require("%rGui/unitsTree/components/unitBuyWnd.nut")
let { aDelayPrice, aTimePriceScale, aTimePriceShake } = require("%rGui/unitsTree/treeAnimConsts.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")
let { curCampaignUnseenBranches } = require("%rGui/unitsTree/unseenBranches.nut")
let { draggedData } = require("%rGui/slotBar/dragDropSlotState.nut")

let frameBorderWidth = hdpxi(2)
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

function openBuyUnitWnd(name, price) {
  let researchStatus = unitsResearchStatus.get()?[name]
  let blueprintStatus = blueprintUnitsStatus.get()?[name]
  if (researchStatus?.canBuy || blueprintStatus?.canBuy) {
    let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, name)
    purchaseUnit({
      unitId = name,
      bqInfo = bqPurchaseInfo,
      price,
      content = unitBuyWnd(name),
      title = loc("unitsTree/researchCompleted"),
      onCancel = @() triggerAnim()})
  } else
    triggerAnim()
}

function mkPlatoonPlates(unit) {
  let { platoonUnits = [] } = unit
  let platoonSize = platoonUnits.len()
  let isLocked = Computed(@() (unit.name not in campMyUnits.get()) && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.get())

  return @() {
    watch = [isSelected, isLocked]
    size = flex()
    children = platoonUnits?.map(@(_, idx) {
      size = flex()
      transform = {
        translate = bgPlatesTranslate(platoonSize, idx, isSelected.get(), framesGapMul)
      }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      children = [
        mkUnitBg(unit, isLocked.get())
        mkPlatoonPlateFrame(unit, isEquipped, isSelected)
      ]
    })
  }
}

function mkUnitPlate(unit, xmbNode, ovr = {}) {
  if (unit == null)
    return null

  let stateFlags = Watched(0)
  let isLocked = Computed(@() (unit.name not in campMyUnits.get()) && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let isEquipped = Computed(@() unit.name == curUnitName.get())
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let canBuyForLvlUp = Computed(@() playerLevelInfo.get().isReadyForLevelUp && (unit?.name in buyUnitsData.get().canBuyOnLvlUp))
  let price = Computed(@() canPurchase.get() ? getUnitAnyPrice(unit, canBuyForLvlUp.get(), unitDiscounts.get()) : null)
  let discount = Computed(@() unitDiscounts?.get()[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isCollectible = unit?.isCollectible
  let hasUnseenRewards = Computed(@() unit.name in unseenUnitLvlRewardsList.get())
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get()
    || unit.name in unseenSkins.get()
    || hasUnseenRewards.get())

  return @() {
    watch = [isSelected, isLocked, canPurchase]
    size = unitPlateSize
    behavior = Behaviors.Button
    function onClick() {
      if (isLvlUpAnimated.get())
        return
      curSelectedUnit.set(unit.name)
      markUnitSeen(unit)
    }
    onAttach = unitsTreeOpenRank.get() != null
      && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
          ? nodeToScroll.set(xmbNode)
        : null
    onElemState = @(s) stateFlags.set(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    xmbNode
    sound = { click = "choose" }
    children = [
      mkPlatoonPlates(unit)
      mkUnitBg(unit, isLocked.get())
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitBlueprintMark(unit, {
        pos = [0, -plateBarHeight]
        padding = hdpx(7)
      })
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
      mkUnitLock(unit, isLocked.get())
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
          discount.get() != null ? discountTagUnitSmall(discount.get().discount) : null
          price.get() != null && price.get().price > 0
              ? mkUnitsTreePrice(price.get())
            : null
        ]
      }
      mkProfileUnitDailyBonus(unit)
      mkPlatoonPlateFrame(unit, isEquipped, isSelected)
      mkUnitEquippedIcon(unit, isEquipped)
      unit.platoonUnits.len() == 0 ?{
        size = flex()
        valign = ALIGN_TOP
        pos = [0, -selLineSize]
        children = selectedLineHorUnits(isSelected, isPremium, isCollectible)
      } : null
      mkPriorityUnseenMarkWatch(needShowUnseenMark)
    ]
  }.__update(ovr)
}

let treeNodeUnitPlateKey = @(name) name == null ? null : $"treeNodeUnitPlate:{name}"

let mkTreeNodesUnitPlateSpeedUpAnim = @(unit, price, discount, researchStatus, xmbNode, ovr) {
  children = {
    key = treeNodeUnitPlateKey(unit.name)
    size = unitPlateTiny
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
                  size = FLEX_H
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
                  discount.get() != null ? discountTagUnitSmall(discount.get().discount) : null
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
                      animUnitAfterResearch.set(null)
                      needShowPriceUnit.set(false)
                      resetTimeout(0.1, function() {
                        isBuyUnitWndOpened.set(true)
                        openBuyUnitWnd(unit.name, price.get())
                      })
                      unitsForExpAnim.mutate(@(v) v.$rawdelete(unit.name))
                      if(unit.name in serverConfigs.get()?.allBlueprints)
                        loadStatusesAnimUnits()
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

let hasChangedColor = Watched(false)
let mkUnitAnimGradColor = @(unit, animUnits, xmbNode, trigger) @() unitBgImageBase.__merge({
  watch = hasChangedColor,
  image = hasChangedColor.get() ? bgUnit : bgUnitNotAvailable,
  onAttach = @() hasChangedColor.set(false),
  onDetach = @() hasChangedColor.set(false),
  animations = [
    {
      trigger, prop = AnimProp.brightness, from = 1, to = 0,
      duration = aTimeUnitFromRed, easing = InQuad, onFinish = @() hasChangedColor.set(true),
      onStart = @() animUnits.values()?[ceil(animUnits.len() / 2.0) - 1] != unit.name ? null
        : nodeToScroll.set(xmbNode)
    },
    {
      trigger, prop = AnimProp.brightness, from = 0, to = 1,
      duration = aTimeUnitToGrey, easing = OutQuad, delay = aDelayUnitToGrey
    }
  ],
})

function mkTreeNodesUnitPlateUnlockAnim(unit, xmbNode, ovr = {}) {
  let isPremium = unit.isPremium || unit?.isUpgraded
  let trigger = animNewUnitsAfterResearchTrigger
  return {
    children = {
      key = treeNodeUnitPlateKey(unit.name)
      size = unitPlateTiny
      onAttach = @() nodeToScroll.set(xmbNode)
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
        mkUnitInfo(unit, {padding = hdpx(10)})
        {
          size = flex()
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          children = [
            {
              size = const [SIZE_TO_CONTENT, hdpx(40)]
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
              size = FLEX_H
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

function mkTreeNodesUnitPlateDefault(unit, xmbNode, ovr = {}) {
  if (unit == null)
    return null

  let researchStatus = Computed(@() unitsResearchStatus.get()?[unit.name])
  let isOwned = Computed(@() unit.name in campMyUnits.get())
  let isLocked = Computed(@() !isOwned.get() && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isCollectible = unit?.isCollectible
  return @() {
    watch = [isSelected, isOwned, isLocked, canPurchase, researchStatus, researchCountry]
    size = unitPlateTiny
    key = treeNodeUnitPlateKey(unit.name)
    xmbNode
    children = [
      mkUnitBg(unit, isLocked.get(),
        !isLocked.get() || (researchStatus.get()?.canResearch ?? false) || (researchStatus.get()?.isResearched ?? false))
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)), isLocked.get())
      mkUnitInfo(unit)
      {
        size = flex()
        valign = ALIGN_TOP
        pos = [0, -selLineSize]
        children = selectedLineHorUnits(isSelected, isPremium, isCollectible)
      }
      @() researchStatus.get()?.isCurrent
        ? {
            watch = researchStatus
            size = [unitPlateTiny[0] + frameBorderWidth * 2, unitPlateTiny[1]]
            rendObj = ROBJ_BOX
            hplace = ALIGN_CENTER
            fillColor = 0
            borderColor = 0xFFFFFFFF
            borderWidth = frameBorderWidth
        }
        : { watch = researchStatus }
      mkProfileUnitDailyBonus(unit)
    ]
  }.__update(ovr)
}

function mkTreeNodesUnitPlate(unit, xmbNode, ovr = {}) {
  if (unit == null)
    return null

  let stateFlags = Watched(0)
  let researchStatus = Computed(@() unitsResearchStatus.get()?[unit.name])
  let blueprintStatus = Computed(@() blueprintUnitsStatus.get()?[unit.name])
  let isOwned = Computed(@() unit.name in campMyUnits.get())
  let isLocked = Computed(@() !isOwned.get() && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let canDrag = Computed(@() isOwned.get() && isCampaignWithSlots.get())
  let isDraggedUnit = Computed(@() draggedData.get() != null && draggedData.get()?.unitName == unit.name)
  let price = Computed(@() canPurchase.get() || (researchStatus.get()?.isResearched && unit.name not in campMyUnits.get())
      ? getUnitAnyPrice(unit, false, unitDiscounts.get())
    : null)
  let discount = Computed(@() unitDiscounts?.get()[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isCollectible = unit?.isCollectible
  let hasUnseenRewards = Computed(@() unit.name in unseenUnitLvlRewardsList.get())
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get()
    || unit.name in unseenSkins.get()
    || unit.name in unseenResearchedUnits.get()?[selectedCountry.get()]
    || hasUnseenRewards.get())
  let needShowUnseenBranchMark = Computed(@() curCampaignUnseenBranches.get()?[unit.country]
    && unitsResearchStatus.get()?[unit.name].canResearch)
  let needShowBlueprintBar = Computed(@() unit.name in serverConfigs.get()?.allBlueprints
    && unit.name not in campMyUnits.get()
    && (servProfile.get()?.blueprints[unit.name] ?? 0) < (serverConfigs.get()?.allBlueprints[unit.name].targetCount ?? 0))
  let trigger = $"{unit.name}_anim"
  let startCurAnim = @() anim_start(trigger)
  let needToShowHighlight = Computed(@() animNewUnitsAfterResearch.get().len() == 0
    && (currentResearch.get() ? currentResearch.get().name == unit.name : researchStatus.get()?.canResearch))
  return @() animUnitAfterResearch.get() == unit.name && canPlayAnimUnitAfterResearch.get()
      ? mkTreeNodesUnitPlateSpeedUpAnim(unit, price, discount, blueprintStatus.get() != null ? blueprintStatus : researchStatus, xmbNode,
        ovr.__merge({ watch = [animUnitAfterResearch, canPlayAnimUnitAfterResearch, blueprintStatus] }))
    : animNewUnitsAfterResearch.get()?[unit.name]
      ? mkTreeNodesUnitPlateUnlockAnim(unit, xmbNode, ovr.__merge({ watch = animNewUnitsAfterResearch }))
    : {
      watch = [isSelected, isLocked, isDraggedUnit, canPurchase, researchStatus, needShowBlueprintBar,
        researchCountry, needToShowHighlight, animUnitAfterResearch, animNewUnitsAfterResearch,
        needDelayAnimation, canPlayAnimUnitAfterResearch]
      size = unitPlateTiny
      behavior = canDrag.get() ? Behaviors.DragAndDrop : Behaviors.Button
      dropData = { unitName = unit.name }
      onDragMode = @(on, data) draggedData.set(on ? data : null)
      function onClick() {
        curSelectedUnit.set(unit.name)
        markUnitSeen(unit)
      }
      dragStartDelay = 0.5
      key = treeNodeUnitPlateKey(unit.name)
      onAttach = unitsTreeOpenRank.get() != null
        && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
            ? nodeToScroll.set(xmbNode)
          : null
      onElemState = @(s) stateFlags.set(s)
      clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
      xmbNode
      sound = { click  = "choose" }
      children = [
        mkUnitBg(unit, isLocked.get(),
          !isLocked.get() || (researchStatus.get()?.canResearch ?? false) || (researchStatus.get()?.isResearched ?? false))
        mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
        needToShowHighlight.get()
          ? {
              key = unit.name
              size = const [flex(), ph(70)]
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
        @() {
          watch = [price, discount, canPurchase, researchStatus]
          key = price
          flow = FLOW_HORIZONTAL
          hplace = ALIGN_LEFT
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          children = !price.get() ? null : [
            discount.get() != null ? discountTagUnitSmall(discount.get().discount) : null
            price.get() != null && price.get().price > 0
                ? mkUnitsTreePrice(price.get(), canPurchase.get())
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
              size = const [flex(), hdpx(40)]
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
        mkUnitInfo(unit)
        {
          size = flex()
          valign = ALIGN_TOP
          pos = [0, -selLineSize]
          children = selectedLineHorUnits(isSelected, isPremium, isCollectible)
        }
        @() {
          watch = [needShowUnseenBranchMark, needShowUnseenMark]
          children = needShowUnseenBranchMark.get() ? priorityUnseenMarkFeature
            : needShowUnseenMark.get() ? priorityUnseenMark
            : null
        }
        @() researchStatus.get()?.isCurrent
          ? {
              watch = researchStatus
              size = [unitPlateTiny[0] + frameBorderWidth * 2, unitPlateTiny[1]]
              rendObj = ROBJ_BOX
              hplace = ALIGN_CENTER
              fillColor = 0
              borderColor = 0xFFFFFFFF
              borderWidth = frameBorderWidth
          }
          : { watch = researchStatus }
        mkProfileUnitDailyBonus(unit)
      ]
      transform = { scale = isDraggedUnit.get() ? [1.1, 1.1] : [1, 1] }
      animations = [
        { prop = AnimProp.rotate, to = 2, duration = aTimePriceShake, easing = Shake4,
          trigger = $"unit_exp_{unit.name}", delay = aDelayPrice }
        { prop = AnimProp.scale, to = [1.1, 1.1], duration = aTimePriceScale, easing = CosineFull,
          trigger = $"unit_exp_{unit.name}", delay = aDelayPrice }
      ]
    }.__update(ovr)
}

return {
  triggerAnim
  mkUnitPlate
  mkTreeNodesUnitPlate
  mkTreeNodesUnitPlateDefault
  framesGapMul
  treeNodeUnitPlateKey
}
