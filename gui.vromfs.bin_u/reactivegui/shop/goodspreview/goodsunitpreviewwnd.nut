from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { eventbus_subscribe } = require("eventbus")
let { defer, resetTimeout } = require("dagor.workcycle")
let { getCustomGoodsNameById } = require("%appGlobals/config/goodsPresentation.nut")
let { getBattleModPresentationForOffer } = require("%appGlobals/config/battleModPresentation.nut")
let { isCampaignWithSlots } = require("%appGlobals/pServer/slots.nut")
let { blockedResearchByBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { mark_offer_seen, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { unitRewardTypes, G_UNIT_UPGRADE, G_UNIT, G_BLUEPRINT, G_BATTLE_MOD, G_SKIN
} = require("%appGlobals/rewardType.nut")
let { battleRentInfo, rentalCd } = require("%appGlobals/rentalState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { hideModals, unhideModals } = require("%rGui/components/modalWindows.nut")
let { GPT_UNIT, GPT_BLUEPRINT, previewType, previewGoods, previewGoodsUnit, closeGoodsPreview, openPreviewCount,
  HIDE_PREVIEW_MODALS_ID
} = require("%rGui/shop/goodsPreviewState.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let { openUnitDetailsWnd } = require("%rGui/unitDetails/unitDetailsState.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { mkRentBattlesButton, queueCurRandomBattleMode } = require("%rGui/mainMenu/toBattleButton.nut")
let { opacityAnims, colorAnims, mkPreviewHeader, mkPriceWithTimeBlock, mkPreviewItems, doubleClickListener,
  ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimePackNameBack, aTimeBackBtn, aTimeInfoItem, aTimePriceFull,
  aTimeInfoItemOffset, aTimeInfoLight, horGap
} = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { activeRewardHint } = require("%rGui/shop/goodsPreview/goodsPreviewHint.nut")
let { unitForCutscene } = require("%rGui/shop/goodsPreview/unitCutscene.nut")
let { set_load_sounds_for_model } = require("hangar")
let { setCustomHangarUnit, resetCustomHangarUnit, hangarUnitDataBackup } = require("%rGui/unit/hangarUnit.nut")
let { isPurchEffectVisible, requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitName } = require("%appGlobals/unitPresentation.nut")
let { unitPlateTiny, mkUnitInfo, mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts,
  unitPlateWidth, unitPlateHeight
} = require("%rGui/unit/components/unitPlateComp.nut")
let { unitInfoPanel, mkUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { REWARD_STYLE_TINY } = require("%rGui/rewards/rewardStyles.nut")
let { mkRewardReceivedMark } = require("%rGui/rewards/rewardPlateComp.nut")
let { isEmptyByRType } = require("%rGui/rewards/rewardViewInfo.nut")
let { animatedProgressBar } = require("%rGui/unitsTree/components/unitPlateNodeComp.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { schRewards } = require("%rGui/shop/schRewardsState.nut")
let { activeOffer } = require("%rGui/shop/offerState.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall, scrollArrowImageSmallSize } = require("%rGui/components/scrollArrows.nut")
let { backButtonHeight } = require("%rGui/components/backButton.nut")
let { selectedLineHorUnits, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let mkGiftSchRewardBtn = require("%rGui/shop/goodsPreview/mkGiftSchRewardBtn.nut")
let mkPersonalDiscountBtn = require("%rGui/shop/goodsPreview/mkPersonalDiscountBtn.nut")
let skipOfferBtn = require("%rGui/shop/goodsPreview/skipOfferBtn.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")


let TIME_TO_SHOW_UI = 5.0 
let TIME_TO_SHOW_UI_AFTER_SHOT = 0.3
let MAX_ITEMS_IN_ROW = 6

let unitPlateSize = unitPlateTiny
let verticalGap = hdpx(20)
let maxInfoPanelHeight = saSize[1] - hdpx(380)

let isWindowAttached = Watched(false)
let needShowUi = Watched(false)
let skipAnimsOnce = Watched(false)
let openCount = Computed(@() previewType.get() == GPT_UNIT || previewType.get() == GPT_BLUEPRINT ? openPreviewCount.get() : 0)
let needScroll = Computed(@() previewGoods.get() != null
  && previewGoods.get().rewards.reduce(@(res, r) r.gType in unitRewardTypes ? res + 1 : res, 0) > 8)
let goodsBattleMode = Computed(function() {
  let { campaign = "", country = "" } = previewGoodsUnit.get()
  let battleMode = blockedResearchByBattleMods.get()?[campaign][country] ?? ""
  if (null != previewGoods.get()?.rewards.findvalue(@(r) r.id == battleMode && r.gType == G_BATTLE_MOD))
    return battleMode
  return null
})


let aTimeHeaderStart = 0
let aTimePackInfoStart = aTimePackNameFull
let aTimePackInfoHeader = 0.3
let aTimePackUnitInfoStart = aTimePackInfoHeader + 0.05
let aTimePackUnitPlates = 0.3
let aTimePackUnitPlatesOffset = 0.05
let aTimeFirstItemOfset = 0.1
let aTimeInfoHeaderFull = aTimeInfoLight + 0.3 * aTimeInfoItem + aTimeFirstItemOfset + 3 * aTimeInfoItemOffset

let aTimePriceStart = aTimePackInfoStart + aTimeInfoHeaderFull
let aTimeShowModals = aTimePriceStart + aTimePriceFull

function showUi() {
  resetTimeout(aTimeShowModals, @() unhideModals(HIDE_PREVIEW_MODALS_ID))
  needShowUi.set(true)
}

openCount.subscribe(@(v) v == 0 ? battleRentInfo.set(null) : null)

isWindowAttached.subscribe(function(v) {
  if (!v) {
    unhideModals(HIDE_PREVIEW_MODALS_ID)
    if (openCount.get() != 0 && needShowUi.get())
      skipAnimsOnce.set(true)
    needShowUi.set(false)
    return
  }

  needShowUi.set(skipAnimsOnce.get())
  if (!skipAnimsOnce.get()) {
    resetTimeout(TIME_TO_SHOW_UI, showUi)
    hideModals(HIDE_PREVIEW_MODALS_ID)
  }
  else {
    skipAnimsOnce.set(false)
    defer(function() {
      anim_skip(ANIM_SKIP)
      anim_skip_delay(ANIM_SKIP_DELAY)
    })
  }
})

isPurchEffectVisible.subscribe(function(v) {
  if (v && openCount.get() > 0)
    closeGoodsPreview()
})

eventbus_subscribe("onCutsceneUnitShoot", @(_) resetTimeout(TIME_TO_SHOW_UI_AFTER_SHOT, showUi))

let curSelectedUnitId = Watched("")
previewGoodsUnit.subscribe(@(v) curSelectedUnitId.set(v?.name ?? ""))

let unitForShow = Computed(function() {
  if (!isWindowAttached.get() || previewGoodsUnit.get() == null)
    return null
  let unitName = curSelectedUnitId.get()
  local res = clone (unitName == previewGoodsUnit.get().name || unitName == "" ? previewGoodsUnit.get()
    : (campUnitsCfg.get()?[unitName] ?? previewGoodsUnit.get().__merge({ name = unitName })))

  res.skin <- previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_SKIN && r.id == unitName).subId
    ?? (previewGoodsUnit.get()?.isUpgraded ? "upgraded" : "")
  return res
})

unitForShow.subscribe(function(unit) {
  if (unit != null)
    setCustomHangarUnit(unit)
  else
    resetCustomHangarUnit()
})

let unitForCutsceneExt = keepref(Computed(@(prev) prev == unitForShow.get() ? prev
  : !needShowUi.get() && !skipAnimsOnce.get() ? unitForShow.get()
  : null))
unitForCutsceneExt.subscribe(@(v) unitForCutscene.set(v))

previewGoodsUnit.subscribe(function(unit) {
  if (unit != null)
    set_load_sounds_for_model(true)
})

function openDetailsWnd() {
  let { name } = unitForShow.get()
  hangarUnitDataBackup.set({ name, custom = unitForShow.get() })
  let cfg = {
    name
    isUpgraded = previewGoodsUnit.get()?.isUpgraded ?? false
    canShowOwnUnit = false
  }
  let { skin = null } = unitForShow.get()
  if (skin != null && skin != (previewGoodsUnit.get()?.skin ?? previewGoodsUnit.get()?.currentSkins?[name] ?? "")) 
    cfg.skin <- skin
  openUnitDetailsWnd(cfg)
}

function mkBlueprintUnitPlate(unit){
  let deltaBlueprints = Computed(@() (serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1) - (servProfile.get()?.blueprints?[unit.name] ?? 0))
  return @() {
    watch = deltaBlueprints
    flow = FLOW_VERTICAL
    children = [
      {
        size = [unitPlateWidth, unitPlateHeight]
        children = [
          mkUnitBg(unit)
          {
            size = [unitPlateWidth, unitPlateHeight]
            rendObj = ROBJ_IMAGE
            fallbackImage = Picture($"ui/unitskin#blueprint_default.avif:{unitPlateWidth}:{unitPlateHeight}:P")
            image = Picture($"{getUnitPresentation(unit).blueprintImage}:{unitPlateWidth}:{unitPlateHeight}:P")
          }
          mkUnitTexts(unit, getUnitName(unit.name))
          {
            size = FLEX
            valign = ALIGN_BOTTOM
            flow = FLOW_VERTICAL
            children = [
              {
                size = FLEX_H
                halign = ALIGN_RIGHT
                padding = const [0, hdpx(5), 0 , 0]
                children = [
                  {
                    size = const [pw(100), SIZE_TO_CONTENT]
                    rendObj = ROBJ_TEXT
                    text = "/".concat((servProfile.get()?.blueprints?[unit.name] ?? 0), (serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1) )
                    halign = ALIGN_CENTER
                    vplace = ALIGN_CENTER
                  }.__update(fontTinyAccentedShaded)
                  mkGradRank(unit?.mRank)
                ]
              }
              animatedProgressBar(unit,
                {
                  width = unitPlateWidth,
                  height = hdpx(30),
                  gap = hdpx(-30),
                  sectorSize = [hdpx(60), hdpx(30)]
                },
                {
                  rendObj = ROBJ_TEXT
                  text = "".concat("+", deltaBlueprints.get())
                  hplace = ALIGN_RIGHT
                  vplace = ALIGN_CENTER
                }.__update(fontTinyAccentedShaded))
            ]
          }
        ]
      }
    ]
  }
}

function mkAirBranchUnitPlate(unit, onSelectUnit) {
  let p = getUnitPresentation(unit)
  let isSelected = Computed(@() curSelectedUnitId.get() == unit.name)
  return {
    behavior = Behaviors.Button
    onClick = onSelectUnit
    sound = { click  = "choose" }
    children = [
      {
        size = unitPlateSize
        children = [
          mkUnitBg(unit)
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(unit)
          mkUnitTexts(unit, loc(p.locId))
          mkUnitInfo(unit)
          unit?.isReceived ? mkRewardReceivedMark(REWARD_STYLE_TINY) : null
        ]
      }
      {
        size = FLEX
        valign = ALIGN_TOP
        pos = [0, -selLineSize]
        children = selectedLineHorUnits(isSelected)
      }
    ]
    animations = opacityAnims(aTimePackUnitPlates, aTimePackUnitInfoStart + aTimePackUnitPlatesOffset)
  }
}

function mkUnitPlate(idx, unit) {
  let p = getUnitPresentation(unit)
  return {
    sound = { click  = "choose" }
    children = [
      {
        size = unitPlateSize
        children = [
          mkUnitBg(unit)
          mkUnitImage(unit)
          mkUnitTexts(unit, loc(p.locId))
          mkUnitInfo(unit)
        ]
      }
    ]
    animations = opacityAnims(aTimePackUnitPlates, aTimePackUnitInfoStart + aTimePackUnitPlatesOffset * idx)
  }
}

let singleUnitBlock = @() {
  watch = [previewGoodsUnit, previewType]
  children = previewGoodsUnit.get() == null ? null
    : previewType.get() == GPT_BLUEPRINT ? mkBlueprintUnitPlate(previewGoodsUnit.get())
    : mkUnitPlate(0, previewGoodsUnit.get())
}

let branchUnitsBlock = @(unit)
  mkAirBranchUnitPlate(unit, @() curSelectedUnitId.set(unit.name))

let mkHeader = @() mkPreviewHeader(
  Computed(@() getCustomGoodsNameById(previewGoods.get()?.id ?? "")
    ?? (goodsBattleMode.get() != null ? loc("offer/earlyAccess")
          : previewGoods.get()?.offerClass == "seasonal" ? loc("seasonalOffer")
          : (previewGoods.get()?.id ?? "") == "branch_offer"
            ? " ".concat(getUnitName(previewGoodsUnit.get()), loc("offer/airBranch"))
          : previewGoodsUnit.get() ? getUnitName(previewGoodsUnit.get())
          : "")),
  closeGoodsPreview,
  aTimeHeaderStart)

let packInfo = @(isHintBottom) {
  flow = isHintBottom ? FLOW_VERTICAL : null
  children = [
    @() {
      watch = [previewGoods, goodsBattleMode]
      children = mkPreviewItems(
        (previewGoods.get()?.rewards ?? [])
          .filter(@(r) (r.gType not in unitRewardTypes) && (r.gType != G_BATTLE_MOD || r.id != goodsBattleMode.get())),
        aTimePackInfoStart + aTimeFirstItemOfset,
        MAX_ITEMS_IN_ROW)
      animations = colorAnims(aTimePackInfoHeader, aTimePackInfoStart)
    }
    {
      padding = [REWARD_STYLE_TINY.boxGap, 0]
      pos = [0, isHintBottom ? 0 : ph(-100)]
      valign = ALIGN_BOTTOM
      vplace = ALIGN_BOTTOM
      children = activeRewardHint
    }
  ]
}

let unitInfoButton = {
  size = [evenPx(70), evenPx(70)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    infoEllipseButton(
      openDetailsWnd,
      { hotkeys = [["^J:Y", loc("msgbox/btn_more")]] }
    )
  ]
}

let balanceBlock = @() {
  watch = previewGoods
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = horGap
  children = [
    (previewGoods.get()?.price.price ?? 0) <= 0 ? null
      : mkCurrencyBalance(previewGoods.get().price.currencyId)
    unitInfoButton
  ]
  animations = opacityAnims(aTimeBackBtn, aTimePackNameBack)
}

let itemsDescText = {
  rendObj = ROBJ_TEXT
  valign = ALIGN_CENTER
  text = loc("offer/itemsDesc")
  animations = opacityAnims(aTimePackInfoHeader, aTimePackInfoStart)
}.__update(fontSmall)

function itemsDesc() {
  let { rewards = [] } = previewGoods.get()
  let hasOtherRewards = null != rewards.findvalue(@(r) r.gType not in unitRewardTypes)
  return hasOtherRewards ? itemsDescText.__update({ watch = previewGoods }) : { watch = previewGoods }
}

let packInfoWithHeader = @(isHintBottom = true) {
  flow = FLOW_VERTICAL
  gap = REWARD_STYLE_TINY.boxGap
  children = [
    itemsDesc
    packInfo(isHintBottom)
  ]
}

let earlyAccessImageBlock = @(img) img == null ? null
  : {
      pos = [-saBorders[0], 0]
      size = const [sw(50), sh(50)]
      rendObj = ROBJ_IMAGE
      image = Picture($"{img}:0:P")
      keepAspect = true
      imageHalign = ALIGN_LEFT
    }

let earlyAccessDescriptionBlock = @(locId, unitName = null) {
  flow = FLOW_VERTICAL
  pos = [-saBorders[0], 0]
  rendObj = ROBJ_IMAGE
  image = simpleHorGrad
  color = 0x80000000
  flipX = true
  gap = hdpx(10)
  padding = [0, saBorders[0], hdpx(25), saBorders[0]]
  children = [
    @() itemsDescText.__update({ watch = previewGoods, padding = const [hdpx(20), 0] })
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = unitName != null ? loc(locId, { unitName }) : loc(locId)
    }.__update(fontSmall)
  ]
}

let leftBlockSingleUnit = {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = verticalGap
  children = [
    singleUnitBlock
    packInfoWithHeader(true)
  ]
}

function leftBlockEarlyAccess() {
  let presentation = getBattleModPresentationForOffer(goodsBattleMode.get())
  let locId = presentation.locId
  let backgroundImg = presentation.image
  return {
    watch = [goodsBattleMode, previewGoodsUnit]
    size = FLEX
    flow = FLOW_VERTICAL
    gap = verticalGap
    children = [
      earlyAccessDescriptionBlock(locId, getUnitName(previewGoodsUnit.get()))
      singleUnitBlock
      earlyAccessImageBlock(backgroundImg)
      packInfo(false)
    ]
  }
}

let rightBlock = {
  size = FLEX
  children = [
    {
      size = [FLEX, maxInfoPanelHeight]
      vplace = ALIGN_TOP
      children = unitInfoPanel({
        maxHeight = maxInfoPanelHeight
        padding = const [hdpx(30), hdpx(30), hdpx(20), hdpx(30)]
        hplace = ALIGN_RIGHT
        behavior = [ Behaviors.Button, HangarCameraControl ]
        touchMarginPriority = TOUCH_BACKGROUND
        onClick = openDetailsWnd
        clickableInfo = loc("msgbox/btn_more")
      }, mkUnitTitle)
      animations = opacityAnims(aTimeBackBtn, aTimePackNameBack)
    }
    {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = mkPriceWithTimeBlock(aTimePriceStart, skipOfferBtn)
    }
  ]
}

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != "unitUpgrade" && g.gType != "unitLevel")
let markPurchasesSeenDelayed = function(purchList) {
  defer(function() {
    local unit = campMyUnits.get()?[purchList.findvalue(@(_) true)?.goods[0].id]
    if (unit == null)
      return
    markPurchasesSeen(purchList.keys())
    requestOpenUnitPurchEffect(unit)
  })
}

let sortedUnits = Computed(function() {
  if (previewGoods.get() == null)
    return []
  let { rewards } = previewGoods.get()
  let res = []
  let received = []
  let configs = serverConfigs.get()
  let profile = servProfile.get()
  foreach (r in rewards) {
    if (r.gType not in unitRewardTypes)
      continue
    let unit = campUnitsCfg.get()?[r.id]
    if (unit == null)
      continue
    if (isEmptyByRType?[r.gType](r.id, r.subId, profile, configs))
      received.append(unit.__merge({ isUpgraded = r.gType == G_UNIT_UPGRADE, isReceived = true }))
    else
      res.append(r.gType != G_UNIT_UPGRADE ? unit : unit.__merge({ isUpgraded = true }))
  }
  return res.extend(received)
})
let totalUnits = Computed(@() sortedUnits.get().len())

let pannableArea = verticalPannableAreaCtor(sh(100) - saBorders[1] * 2 - backButtonHeight - 2*verticalGap, [verticalGap, saBorders[1]*3])
let scrollHandler = ScrollHandler()

let gapForBranch = hdpx(20)

let scrollArrowsBlock = {
  size = [SIZE_TO_CONTENT, saSize[1] - backButtonHeight - verticalGap - hdpx(100)]
  pos = [unitPlateSize[0] - (scrollArrowImageSmallSize / 2).tointeger(), 0]
  children = [
    mkScrollArrow(scrollHandler, MR_T, scrollArrowImageSmall)
    mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
  ]
}

let leftBlockUnits = @() {
  watch = [totalUnits, previewGoodsUnit, schRewards, goodsBattleMode]
  size = totalUnits.get() > 1 ? [unitPlateSize[0] * 2 + gapForBranch, SIZE_TO_CONTENT] : FLEX
  halign = ALIGN_LEFT
  children = totalUnits.get() > 1
    ? @() {
        watch = sortedUnits
        flow = FLOW_VERTICAL
        gap = gapForBranch
        children = arrayByRows(sortedUnits.get().map(branchUnitsBlock), 2)
          .map(@(u)
            {
              flow = FLOW_HORIZONTAL
              gap = gapForBranch
              children = u
            })
          .append(packInfoWithHeader(false))
      }
    : getBattleModPresentationForOffer(goodsBattleMode.get()) != null ? leftBlockEarlyAccess
    : leftBlockSingleUnit
}

let cbId = "onResetPenaltyToRandomBattleInUnitPreview"

registerHandler(cbId, @(res) res?.error == null ? showNoPremMessageIfNeed(@() queueCurRandomBattleMode()) : null)

let leftBlock = {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = verticalGap
  children = [
    @() {
      watch = needScroll
      size = !needScroll.get()
        ? FLEX
        : [unitPlateSize[0] * 2 + 2 * gapForBranch, SIZE_TO_CONTENT]
      children = [
        !needScroll.get() ? leftBlockUnits
          : pannableArea(leftBlockUnits, {}, { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
        !needScroll.get() ? null
          : scrollArrowsBlock
      ]
    }
    @() {
      watch = [battleRentInfo, previewGoodsUnit, rentalCd]
      children = rentalCd.get() <= 0 || battleRentInfo.get() == null ? null
        : mkRentBattlesButton(rentalCd.get(), previewGoodsUnit.get().campaign, function() {
            sendNewbieBqEvent("pressToBattleButtonUnitPreview", { status = "online_battle" })
            if (tryOpenQueuePenaltyWnd(previewGoodsUnit.get().campaign, randomBattleMode.get(), cbId))
              return
            showNoPremMessageIfNeed(@() queueCurRandomBattleMode())
          })
    }
  ]
}

let gTypesRental = [G_UNIT, G_UNIT_UPGRADE, G_BLUEPRINT].reduce(@(res, v) res.$rawset(v, true), {})

let previewRentUnitId = keepref(Computed(@() rentalCd.get() <= 0 ? null
  : activeOffer.get()?.id == null || activeOffer.get()?.id != previewGoods.get()?.id ? null
  : !activeOffer.get()?.rentalEnabled ? null
  : previewGoods.get()?.rewards.findvalue(@(v) gTypesRental?[v.gType] && v.id == curSelectedUnitId.get()).id
      ?? previewGoods.get()?.rewards.findvalue(@(v) gTypesRental?[v.gType]).id))

previewRentUnitId.subscribe(@(id) battleRentInfo.set(id == null ? null
  : isCampaignWithSlots.get() ? { isSlots = isCampaignWithSlots.get(), unitList = [id] }
  : { isSlots = isCampaignWithSlots.get(), unit = id }))

let previewWnd = @() {
  watch = needShowUi
  key = openCount
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = verticalGap
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  stopMouse = true
  stopHotkeys = true

  function onAttach() {
    addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    isWindowAttached.set(true)
    if (activeOffer.get()?.id != null && activeOffer.get()?.id == previewGoods.get()?.id)
      mark_offer_seen(activeOffer.get().campaign, activeOffer.get().id)
  }

  function onDetach() {
    removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    isWindowAttached.set(false)
  }

  children = !needShowUi.get() ? doubleClickListener(@() needShowUi.set(true))
    : [
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          children = [
            {
              flow = FLOW_HORIZONTAL
              children = [
                mkHeader
                {
                  size = 0
                  flow = FLOW_HORIZONTAL
                  gap = hdpx(10)
                  children = [
                    @() {
                      watch = [previewGoodsUnit, schRewards, activeOffer, previewGoods]
                      children = activeOffer.get()?.id != previewGoods.get()?.id ? null :
                        mkGiftSchRewardBtn(
                          schRewards.get()?[$"gift_{previewGoodsUnit.get()?.campaign ?? ""}_offer"]
                          aTimeHeaderStart,
                          skipAnimsOnce)
                    }
                    @() {
                      watch = previewGoods
                      children = !previewGoods.get()?.id ? null
                        : mkPersonalDiscountBtn(previewGoods, aTimeHeaderStart)
                    }
                  ]
                }
              ]
            }
            balanceBlock
          ]
        }
        {
          size = FLEX
          children = [
            leftBlock
            rightBlock
          ]
        }
      ]
}

registerScene("goodsUnitPreviewWnd", previewWnd, closeGoodsPreview, openCount)
