from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "math" import ceil
from "%appGlobals/pServer/profile.nut" import playerLevelInfo, campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/slots.nut" import isCampaignWithSlots
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/unitsState.nut" import canBuyUnits
from "%rGui/components/discountTag.nut" import discountTagUnitSmall
from "%rGui/components/levelBlockPkg.nut" import maxLevelStarChar
from "%rGui/components/selectedLineUnits.nut" import selectedLineHorUnits, selLineSize
from "%rGui/components/unseenMark.nut" import mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature, priorityUnseenMark
from "%rGui/options/options/gameOptions.nut" import isAllowAutoOfferToBuyUnitEnabled
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_UNITS, PURCH_TYPE_UNIT, mkBqPurchaseInfo
from "%rGui/slotBar/dragDropSlotState.nut" import draggedData
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/unit/components/unitPlateComp.nut" import mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkUnitTimeLeft,
  mkUnitLevel, mkUnitsTreePrice, mkUnitBlueprintMark, mkUnitResearchPrice, mkUnitSelectedGlow, mkUnitEquippedIcon,
  plateTextsSmallPad, unitPlateTiny, bgUnit, bgUnitNotAvailable, mkUnitBgPremium, unitBgImageBase, mkUnitInfo
import "%rGui/unit/purchaseUnit.nut" as purchaseUnit
from "%rGui/unit/unitUtils.nut" import getUnitAnyPrice
from "%rGui/unit/unitsDiscountState.nut" import unitDiscounts
from "%rGui/unit/unitsWndState.nut" import curSelectedUnit, curUnitName
from "%rGui/unit/unseenUnits.nut" import unseenUnits, markUnitSeen
from "%rGui/unitsTree/animState.nut" import animUnitAfterResearch, needShowPriceUnit, animExpPart,
  animNewUnitsAfterResearch, needDelayAnimation, loadStatusesAnimUnits, animNewUnitsAfterResearchTrigger,
  hasAnimDarkScreen, unitsForExpAnim, isBuyUnitWndOpened, canPlayAnimUnitAfterResearch
import "%rGui/unitsTree/components/unitBuyWnd.nut" as unitBuyWnd
from "%rGui/unitsTree/components/unitPlateAnimations.nut" import animUnitSlot, mkUnitResearchPriceAnim,
  mkBlueprintUnitResearchPriceAnim, priceAnimDuration
from "%rGui/unitsTree/treeAnimConsts.nut" import aDelayPrice, aTimePriceScale, aTimePriceShake
from "%rGui/unitsTree/unitNodesReceiveInfo.nut" import mkReceiveTimeLeft
from "%rGui/unitsTree/unitResearchBar.nut" import mkPlateExpBar, mkPlateBlueprintBar, mkPlateExpBarAnimSlot,
  plateBarHeight
from "%rGui/unitsTree/unitsTreeComps.nut" import flagsWidth, unitPlateSize, blockSize
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unitsResearchStatus, researchCountry, currentResearch,
  blueprintUnitsStatus, unseenResearchedUnits, selectedCountry, shownUnitsOffersForPurchase, markUnitOfferShown
from "%rGui/unitsTree/unitsTreeScroll.nut" import nodeToScroll
from "%rGui/unitsTree/unitsTreeState.nut" import unitsMaxRank, unitsTreeOpenRank, isUnitPlateLevelVisible
from "%rGui/unitsTree/unseenBranches.nut" import curCampaignUnseenBranches


const frameBorderWidth = hdpxi(2)
let scrollBlocks = ceil((saSize[0] - saBorders[0] - flagsWidth) / blockSize[0] / 2)

let highlighCurrentResearch = mkColoredGradientY(0x20A0A0A0, 0)

const aTimeUnitFromRed = 0.25
const aTimeUnitToGrey = 0.25
const aTimeUnitScaleUp = 0.25
const aTimeUnitScaleDown = 0.25
const aTimeUnitAppearBar = 0.6
const aTimeUnitAppearPrice = 0.1
const aTimeUnitScalePrice = 0.5

const aDelayUnitToGrey = aTimeUnitFromRed
const aDelayUnitScaleUp = aDelayUnitToGrey + aTimeUnitToGrey
const aDelayUnitScaleDown = aDelayUnitScaleUp + aTimeUnitScaleUp
const aDelayUnitAppearBar = aDelayUnitScaleDown + aTimeUnitScaleDown
const aDelayUnitAppearPrice = aDelayUnitAppearBar
const aDelayUnitScalePrice = aDelayUnitAppearBar + aTimeUnitAppearPrice

const totalATime = aDelayUnitScalePrice + aTimeUnitScalePrice

function triggerAnim() {
  anim_start(animNewUnitsAfterResearchTrigger)
  isBuyUnitWndOpened.set(false)
}

function openBuyUnitWnd(name, price) {
  let researchStatus = unitsResearchStatus.get()?[name]
  let blueprintStatus = blueprintUnitsStatus.get()?[name]
  if (!researchStatus?.canBuy && !blueprintStatus?.canBuy)
    return triggerAnim()

  if ((!(isAllowAutoOfferToBuyUnitEnabled.get() ?? true) || name in shownUnitsOffersForPurchase.get()))
    return triggerAnim()

  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, name)
  markUnitOfferShown(name)
  purchaseUnit({
    unitId = name,
    bqInfo = bqPurchaseInfo,
    price,
    content = unitBuyWnd(name),
    title = loc("unitsTree/researchCompleted"),
    onCancel = @() triggerAnim()
  })
}

function mkUnitPlate(unit, xmbNode, ovr = {}) {
  if (unit == null)
    return null

  let stateFlags = Watched(0)
  let isLocked = Computed(@() (unit.name not in campMyUnits.get()) && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let isGlowing = Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER))
  let isEquipped = Computed(@() unit.name == curUnitName.get())
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let price = Computed(@() canPurchase.get() ? getUnitAnyPrice(unit, unitDiscounts.get()) : null)
  let discount = Computed(@() unitDiscounts.get()?[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isCollectible = unit?.isCollectible
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get())

  return @() {
    watch = [isSelected, isLocked, canPurchase]
    size = unitPlateSize
    behavior = Behaviors.Button
    function onClick() {
      curSelectedUnit.set(unit.name)
      markUnitSeen(unit.name)
    }
    onAttach = unitsTreeOpenRank.get() != null
      && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
          ? @() nodeToScroll.set(xmbNode)
        : null
    onElemState = @(s) stateFlags.set(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    xmbNode
    sound = { click = "choose" }
    children = [
      mkUnitBg(unit, isLocked.get())
      mkUnitSelectedGlow(unit, isGlowing)
      mkUnitImage(unit, canPurchase.get() || isLocked.get())
      mkUnitBlueprintMark(unit, {
        pos = [0, -plateBarHeight]
        padding = hdpx(7)
      })
      mkUnitTexts(unit, getUnitName(unit.name), isLocked.get())
      mkUnitLock(unit, isLocked.get())
      mkPlateBlueprintBar(unit, {
        pos = const [0, 0]
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
      mkUnitEquippedIcon(unit, isEquipped)
      {
        size = FLEX
        valign = ALIGN_TOP
        pos = [0, -selLineSize]
        children = selectedLineHorUnits(isSelected, isPremium, isCollectible)
      }
      mkPriorityUnseenMarkWatch(needShowUnseenMark)
    ]
  }.__update(ovr)
}

let treeNodeUnitPlateKey = @(name) name == null ? null : $"treeNodeUnitPlate:{name}"

let mkTreeNodesUnitPlateSpeedUpAnim = @(unit, price, discount, researchStatus, xmbNode, isBlueprint, ovr) {
  children = {
    key = treeNodeUnitPlateKey(unit.name)
    size = unitPlateTiny
    xmbNode
    children = [
      mkUnitBg(unit)
      {
        size = FLEX
        padding = hdpx(7)
        children = mkUnitImage(unit, true)
      }
      mkUnitTexts(unit, getUnitName(unit.name))
      @() {
        watch = needShowPriceUnit
        vplace = ALIGN_BOTTOM
        children = [
          needShowPriceUnit.get() ? null
            : {
              flow = FLOW_VERTICAL
              gap = hdpx(7)
              children = [
                {
                  size = const [FLEX, hdpx(40)]
                  padding = plateTextsSmallPad
                  valign = ALIGN_BOTTOM
                  children = isBlueprint.get() ? mkBlueprintUnitResearchPriceAnim(unit, researchStatus.get())
                    : mkUnitResearchPriceAnim(researchStatus.get(), { padding = 0 })
                }
                @() {
                  watch = animExpPart
                  size = FLEX
                  rendObj = ROBJ_SOLID
                  valign = ALIGN_BOTTOM
                  color = 0xFF000000
                  children = mkPlateExpBarAnimSlot(animExpPart.get(), isBlueprint.get())
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
          size = FLEX
          children = [
            mkUnitAnimGradColor(unit, animNewUnitsAfterResearch.get(), xmbNode, trigger)
            !isPremium ? null : mkUnitBgPremium
          ]
        }
        mkUnitImage(unit, true)
        mkUnitTexts(unit, getUnitName(unit.name), true)
        mkUnitInfo(unit, {padding = hdpx(10)})
        {
          size = FLEX
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
      mkUnitTexts(unit, getUnitName(unit.name), isLocked.get())
      mkUnitInfo(unit)
      {
        size = FLEX
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
    ]
  }.__update(ovr)
}

function mkTreeNodesUnitPlate(unit, xmbNode, ovr = {}, receiveInfo = null) {
  if (unit == null)
    return null

  let stateFlags = Watched(0)
  let researchStatus = Computed(@() unitsResearchStatus.get()?[unit.name])
  let blueprintStatus = Computed(@() blueprintUnitsStatus.get()?[unit.name])
  let isOwned = Computed(@() unit.name in campMyUnits.get())
  let isLocked = Computed(@() !isOwned.get() && (unit.name not in canBuyUnits.get()))
  let isSelected = Computed(@() curSelectedUnit.get() == unit.name)
  let isGlowing = Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER))
  let canPurchase = Computed(@() unit.name in canBuyUnits.get())
  let canDrag = Computed(@() isOwned.get() && isCampaignWithSlots.get())
  let isDraggedUnit = Computed(@() draggedData.get() != null
    && draggedData.get()?.unitName == unit.name
    && !draggedData.get()?.canRemove)
  let price = Computed(@() canPurchase.get() || (researchStatus.get()?.isResearched && unit.name not in campMyUnits.get())
      ? getUnitAnyPrice(unit, unitDiscounts.get())
    : null)
  let discount = Computed(@() unitDiscounts.get()?[unit.name])
  let isPremium = unit?.isUpgraded || unit?.isPremium
  let isCollectible = unit?.isCollectible
  let needShowUnseenMark = Computed(@() unit.name in unseenUnits.get()
    || unit.name in unseenResearchedUnits.get()?[selectedCountry.get()])
  let needShowUnseenBranchMark = Computed(@() curCampaignUnseenBranches.get()?[unit.country]
    && unitsResearchStatus.get()?[unit.name].canResearch)
  let isBlueprint = Computed(@() unit.name in serverConfigs.get()?.allBlueprints)
  let isMaxLevel = isPremium ? Watched(true)
    : Computed(function() {
        let levels = serverConfigs.get()?.unitLevels[unit?.levelPreset].len() ?? 0
        return ((unit?.level ?? 0) >= (unit?.maxLevel ?? levels)) && levels != 0 
      })
  let needShowBlueprintBar = Computed(@() isBlueprint.get()
    && unit.name not in campMyUnits.get()
    && (servProfile.get()?.blueprints[unit.name] ?? 0) < (serverConfigs.get()?.allBlueprints[unit.name].targetCount ?? 0))
  let trigger = $"{unit.name}_anim"
  let startCurAnim = @() anim_start(trigger)
  let needToShowHighlight = Computed(@() animNewUnitsAfterResearch.get().len() == 0
    && (currentResearch.get() ? currentResearch.get().name == unit.name : researchStatus.get()?.canResearch))
  let { receiveType = null, receiveData = null } = receiveInfo
  return @() animUnitAfterResearch.get() == unit.name && canPlayAnimUnitAfterResearch.get()
      ? mkTreeNodesUnitPlateSpeedUpAnim(unit, price, discount, blueprintStatus.get() != null ? blueprintStatus : researchStatus,
          xmbNode, isBlueprint, ovr.__merge({ watch = [animUnitAfterResearch, canPlayAnimUnitAfterResearch,
            blueprintStatus, researchStatus, isBlueprint] }))
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
        markUnitSeen(unit.name)
      }
      dragStartDelay = 0.5
      key = treeNodeUnitPlateKey(unit.name)
      onAttach = unitsTreeOpenRank.get() != null
        && unit.rank == (unitsTreeOpenRank.get() + min(scrollBlocks, unitsMaxRank.get() - playerLevelInfo.get().level))
            ? @() nodeToScroll.set(xmbNode)
          : null
      onElemState = @(s) stateFlags.set(s)
      clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
      xmbNode
      sound = { click  = "choose" }
      children = [
        mkUnitBg(unit, isLocked.get(),
          !isLocked.get() || (researchStatus.get()?.canResearch ?? false) || (researchStatus.get()?.isResearched ?? false))
        mkUnitSelectedGlow(unit, isGlowing)
        needToShowHighlight.get()
          ? {
              key = unit.name
              size = const [FLEX, ph(70)]
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
        mkUnitTexts(unit, getUnitName(unit.name), isLocked.get())
        @() {
          watch = [price, discount, canPurchase]
          key = price
          flow = FLOW_HORIZONTAL
          hplace = ALIGN_LEFT
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          children = price.get()
              ? [
                  discount.get() != null ? discountTagUnitSmall(discount.get().discount) : null
                  price.get() != null && price.get().price > 0
                      ? mkUnitsTreePrice(price.get(), canPurchase.get())
                    : null
                ]
            : receiveType != null ? mkUnitTimeLeft(mkReceiveTimeLeft(receiveType, receiveData))
            : null
          transform = {}
          animations = [
            { prop = AnimProp.rotate, to = 8, duration = aTimePriceShake, easing = Shake6,
              trigger = $"unit_price_{unit.name}", delay = aDelayPrice }
            { prop = AnimProp.scale, to = [1.2, 1.2], duration = aTimePriceScale, easing = CosineFull,
              trigger = $"unit_price_{unit.name}", delay = aDelayPrice }
          ]
        }
        {
          size = FLEX
          valign = ALIGN_BOTTOM
          flow = FLOW_VERTICAL
          children = [
            {
              size = const [FLEX, hdpx(40)]
              padding = plateTextsSmallPad
              valign = ALIGN_BOTTOM
              flow = FLOW_HORIZONTAL
              children = needShowBlueprintBar.get() ? mkUnitBlueprintMark(unit)
                : mkUnitResearchPrice(researchStatus.get(), { padding = 0 })
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
          size = FLEX
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
        unit?.level == null ? null
          : @() {
              watch = [isUnitPlateLevelVisible, isMaxLevel]
              size = flex()
              children = !isUnitPlateLevelVisible.get() ? null
                : [
                    mkUnitLevel(
                      isMaxLevel.get() ? maxLevelStarChar : unit.level,
                      unit.rewardedMasteryTier,
                      { size = evenPx(36) }
                    ).__update({ margin = hdpx(8) })
                  ]
            }
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
  treeNodeUnitPlateKey
}
