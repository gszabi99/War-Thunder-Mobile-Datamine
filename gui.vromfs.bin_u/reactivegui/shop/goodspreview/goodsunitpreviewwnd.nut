from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { eventbus_subscribe } = require("eventbus")
let { defer, resetTimeout } = require("dagor.workcycle")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { registerScene } = require("%rGui/navState.nut")
let { hideModals, unhideModals } = require("%rGui/components/modalWindows.nut")
let { GPT_UNIT, GPT_BLUEPRINT, previewType, previewGoods, previewGoodsUnit, closeGoodsPreview, openPreviewCount,
  HIDE_PREVIEW_MODALS_ID
} = require("%rGui/shop/goodsPreviewState.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { opacityAnims, colorAnims, mkPreviewHeader, mkPriceWithTimeBlock, mkPreviewItems, doubleClickListener,
  ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimePackNameBack, aTimeBackBtn, aTimeInfoItem, aTimePriceFull,
  aTimeInfoItemOffset, aTimeInfoLight, horGap, activeItemHint
} = require("goodsPreviewPkg.nut")
let { start_prem_cutscene, stop_prem_cutscene, get_prem_cutscene_preset_ids, set_load_sounds_for_model, SHIP_PRESET_TYPE, TANK_PRESET_TYPE,
  AIR_FIGHTER_PRESET_TYPE, AIR_BOMBER_PRESET_TYPE } = require("hangar")
let { loadedHangarUnitName, setCustomHangarUnit, resetCustomHangarUnit,
  hangarUnitDataBackup } = require("%rGui/unit/hangarUnit.nut")
let { isPurchEffectVisible, requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { rnd_int } = require("dagor.random")
let { SHIP, AIR } = require("%appGlobals/unitConst.nut")
let { getPlatoonOrUnitName, getUnitPresentation, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitPlatesGap, unitPlateSmall, mkUnitInfo,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSelectedUnderlineVert,
  unitPlateWidth, unitPlateHeight, mkUnitSlotLockedLine
} = require("%rGui/unit/components/unitPlateComp.nut")
let { unitInfoPanel, mkUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")
let { getUnitTags } = require("%appGlobals/unitTags.nut")
let { showBlackOverlay, closeBlackOverlay } = require("%rGui/shop/blackOverlay.nut")
let { get_settings_blk } = require("blkGetters")
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
let mkGiftSchRewardBtn = require("mkGiftSchRewardBtn.nut")
let { doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")
let skipOfferBtn = require("skipOfferBtn.nut")

let TIME_TO_SHOW_UI = 5.0 
let TIME_TO_SHOW_UI_AFTER_SHOT = 0.3

let unitPlateSize = unitPlateSmall
let unitPlateSizeMain = unitPlateSize.map(@(v) v * 1.16)
let unitPlateSizeSingle = unitPlateSize.map(@(v) v * 1.3)
let verticalGap = hdpx(20)
let maxInfoPanelHeight = saSize[1] - hdpx(380)

let isWindowAttached = Watched(false)
let needShowUi = Watched(false)
let skipAnimsOnce = Watched(false)
let openCount = Computed(@() previewType.value == GPT_UNIT || previewType.value == GPT_BLUEPRINT ? openPreviewCount.get() : 0)
let needScroll = Computed(@() (previewGoods.get()?.units.len() ?? 0) + (previewGoods.get()?.unitUpgrades.len() ?? 0) > 8)


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

isWindowAttached.subscribe(function(v) {
  if (!v) {
    unhideModals(HIDE_PREVIEW_MODALS_ID)
    if (openCount.get() != 0 && needShowUi.get())
      skipAnimsOnce.set(true)
    return
  }

  needShowUi.set(skipAnimsOnce.value)
  if (!skipAnimsOnce.value) {
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
previewGoodsUnit.subscribe(@(v) curSelectedUnitId(v?.name ?? ""))

let unitForShow = keepref(Computed(function() {
  if (!isWindowAttached.value || previewGoodsUnit.value == null)
    return null
  let unitName = curSelectedUnitId.value
  if (unitName == previewGoodsUnit.value.name || unitName == "")
    return previewGoodsUnit.value
  return campUnitsCfg.get()?[unitName] ?? previewGoodsUnit.value.__merge({ name = unitName })
}))

unitForShow.subscribe(function(unit) {
  if (unit != null)
    setCustomHangarUnit(unit)
  else
    resetCustomHangarUnit()
})

previewGoodsUnit.subscribe(function(unit) {
  if (unit != null)
    set_load_sounds_for_model(true)
})

let cutSceneWaitForVisualsLoaded = get_settings_blk()?.unitOffer.cutSceneWaitForVisualsLoaded ?? false
let transitionThroughBlackScreen = get_settings_blk()?.unitOffer.transitionThroughBlackScreen ?? false

let readyToShowCutScene = mkWatched(persist, "readyToShowCutScene", false)
eventbus_subscribe("onHangarModelStartLoad", @(_) readyToShowCutScene(false))
eventbus_subscribe(cutSceneWaitForVisualsLoaded ? "onHangarModelVisualsLoaded" : "onHangarModelLoaded", @(_) readyToShowCutScene(true))

let needShowCutscene = keepref(Computed(@() unitForShow.value != null
  && loadedHangarUnitName.value == getTagsUnitName(unitForShow.value?.name ?? "")
  && readyToShowCutScene.value ))

function showCutscene(v) {
  if (!v)
    stop_prem_cutscene()
  else if (!needShowUi.value && !skipAnimsOnce.value) {
    let unitType = unitForShow.value?.unitType ?? ""
    local presetType = TANK_PRESET_TYPE
    if (unitType == SHIP)
      presetType = SHIP_PRESET_TYPE
    else if (unitType == AIR) {
      let tags = getUnitTags(unitForShow.value.name)
      if (tags?.type_fighter == true || tags?.type_strike_aircraft == true)
        presetType = AIR_FIGHTER_PRESET_TYPE
      else
        presetType = AIR_BOMBER_PRESET_TYPE
    }
    let presetIds = get_prem_cutscene_preset_ids(presetType)
    if(presetIds.len() > 0)
      start_prem_cutscene(presetIds[rnd_int(0, presetIds.len()-1)])
  }
}
showCutscene(needShowCutscene.value)
needShowCutscene.subscribe(showCutscene)

function openDetailsWnd() {
  hangarUnitDataBackup({
    name = unitForShow.value.name,
    custom = unitForShow.value,
  })
  unitDetailsWnd({
    name = unitForShow.get()?.name
    isUpgraded = previewGoodsUnit.value?.isUpgraded ?? false
    canShowOwnUnit = false
  })
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
            image = Picture($"ui/unitskin#blueprint_{unit.name}.avif:{unitPlateWidth}:{unitPlateHeight}:P")
          }
          mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
          {
            size = flex()
            valign = ALIGN_BOTTOM
            flow = FLOW_VERTICAL
            children = [
              {
                size = [flex(), SIZE_TO_CONTENT]
                halign = ALIGN_RIGHT
                padding = [0, hdpx(5), 0 , 0]
                children = [
                  {
                    size = [pw(100), SIZE_TO_CONTENT]
                    rendObj = ROBJ_TEXT
                    text = "/".concat((servProfile.get()?.blueprints?[unit.name] ?? 0), (serverConfigs.get()?.allBlueprints?[unit.name].targetCount ?? 1) )
                    halign = ALIGN_CENTER
                    vplace = ALIGN_CENTER
                    fontFx = FFT_GLOW
                    fontFxColor = 0xFF000000
                    fontFxFactor = hdpxi(32)
                  }.__update(fontTinyAccented)
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
                  fontFx = FFT_GLOW
                  fontFxColor = 0xFF000000
                  fontFxFactor = hdpxi(32)
                }.__update(fontTinyAccented))
            ]
          }
        ]
      }
    ]
  }
}

function mkAirBranchUnitPlate(unit, platoonUnit, onSelectUnit){
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isSelected = Computed(@() curSelectedUnitId.get() == platoonUnit.name)
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
          mkUnitImage(platoonUnitFull)
          mkUnitTexts(platoonUnitFull, loc(p.locId))
          mkUnitInfo(unit)
        ]
      }
      {
        size = flex()
        valign = ALIGN_TOP
        pos = [0, -selLineSize]
        children = selectedLineHorUnits(isSelected)
      }
    ]
    animations = opacityAnims(aTimePackUnitPlates, aTimePackUnitInfoStart + aTimePackUnitPlatesOffset)
  }
}

function mkUnitPlate(idx, unit, platoonUnit, onSelectUnit = null) {
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isSelected = Computed(@() onSelectUnit != null && curSelectedUnitId.value == platoonUnit.name)
  let size = idx != 0 ? unitPlateSize
    : onSelectUnit == null ? unitPlateSizeSingle
    : unitPlateSizeMain
  let isPremium = !!(unit?.isPremium || unit?.isUpgraded)
  let isLocked = Computed(@() !isPremium && platoonUnit.reqLevel > (campMyUnits.get()?[unit.name].level ?? 0))
  return {
    behavior = Behaviors.Button
    onClick = onSelectUnit
    sound = { click  = "choose" }
    children = [
      {
        watched = isLocked
        size
        children = [
          mkUnitBg(unit)
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(platoonUnitFull)
          mkUnitTexts(platoonUnitFull, loc(p.locId))
          !isLocked.value ? mkUnitInfo(unit) : null
          mkUnitSlotLockedLine(platoonUnit, isLocked.get())
        ]
      }
      onSelectUnit == null ? null : mkUnitSelectedUnderlineVert(unit, isSelected)
    ]
    animations = opacityAnims(aTimePackUnitPlates, aTimePackUnitInfoStart + aTimePackUnitPlatesOffset * idx)
  }
}

let platoonUnitsBlock = @() {
  watch = previewGoodsUnit
  flow = FLOW_VERTICAL
  gap = unitPlatesGap
  children = previewGoodsUnit.get() == null ? null
    : [ { name = previewGoodsUnit.value.name, reqLevel = 0 } ]
        .extend(previewGoodsUnit.value?.platoonUnits)
        .map(@(pu, idx) mkUnitPlate(idx, previewGoodsUnit.value, pu, @() curSelectedUnitId(pu.name)))
}

let singleUnitBlock = @() {
  watch = [previewGoodsUnit, previewType]
  children = previewGoodsUnit.get() == null ? null
    : previewType.get() == GPT_BLUEPRINT ? mkBlueprintUnitPlate(previewGoodsUnit.get())
    : mkUnitPlate(0, previewGoodsUnit.get(), { name = previewGoodsUnit.get().name, reqLevel = 0 })
}

function branchUnitsBlock(unitName) {
  let unit = Computed(@() campUnitsCfg.get()?[unitName])
  return @() {
    watch = unit
    children = unit.get() == null ? null
      : mkAirBranchUnitPlate(unit.get(), { name = unitName, reqLevel = 0 },
          @() curSelectedUnitId.set(unitName))
  }
}

let mkHeader = @() mkPreviewHeader(
  Computed(@() previewGoods.get()?.offerClass == "seasonal" ? loc("seasonalOffer")
    : (previewGoods.get()?.id ?? "") == "branch_offer" ? " ".concat(getPlatoonOrUnitName(previewGoodsUnit.get(), loc), loc("offer/airBranch"))
    : previewGoodsUnit.get() ? getPlatoonOrUnitName(previewGoodsUnit.get(), loc)
    : ""),
  closeGoodsPreview,
  aTimeHeaderStart)

let packInfo = @(hintOffsetMulY = 1, ovr = {}) {
  children = [
    {
      size = flex()
      pos = [-saBorders[0], REWARD_STYLE_MEDIUM.boxSize * 1.1 * hintOffsetMulY]
      valign = hintOffsetMulY > 0 ? ALIGN_TOP : ALIGN_BOTTOM
      children = activeItemHint
    }
    @() {
      watch = previewGoods
      flow = FLOW_HORIZONTAL
      children = mkPreviewItems(previewGoods.value, aTimePackInfoStart + aTimeFirstItemOfset)
      animations = colorAnims(aTimePackInfoHeader, aTimePackInfoStart)
    }
  ]
}.__update(ovr)

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
    (previewGoods.value?.price.price ?? 0) <= 0 ? null
      : mkCurrencyBalance(previewGoods.value.price.currencyId)
    unitInfoButton
  ]
  animations = opacityAnims(aTimeBackBtn, aTimePackNameBack)
}

let itemsDesc = @() previewGoods.get().items.len() < 1 && previewGoods.get().decorators.len() < 1
  ? { watch = previewGoods }
  : {
    watch = previewGoods
    padding = [hdpx(20), hdpx(20)]
    rendObj = ROBJ_TEXT
    valign = ALIGN_CENTER
    text = loc("offer/itemsDesc")
    animations = opacityAnims(aTimePackInfoHeader, aTimePackInfoStart)
  }.__update(fontSmall)

let leftBlockPlatoon = {
  size = flex()
  flow = FLOW_VERTICAL
  children = [
    platoonUnitsBlock
    {size = flex()}
    itemsDesc
    packInfo(-1, { pos = [0, 0] })
  ]
}

let leftBlockSingleUnit = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = verticalGap
  children = [
    singleUnitBlock
    itemsDesc
    packInfo
  ]
}

let rightBlock = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = verticalGap
  children = [
    {
      size = [flex(), maxInfoPanelHeight]
      children = unitInfoPanel({
        maxHeight = maxInfoPanelHeight
        padding = [hdpx(30), hdpx(30), hdpx(20), hdpx(30)]
        hplace = ALIGN_RIGHT
        behavior = [ Behaviors.Button, HangarCameraControl ]
        touchMarginPriority = TOUCH_BACKGROUND
        onClick = openDetailsWnd
        clickableInfo = loc("msgbox/btn_more")
      }, mkUnitTitle)
      animations = opacityAnims(aTimeBackBtn, aTimePackNameBack)
    }
    {
      size = [SIZE_TO_CONTENT, flex()]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      flow = FLOW_HORIZONTAL
      valign = ALIGN_BOTTOM
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

function closeBlackOverlayOnceOnVisualsLoaded(loaded) {
  if (loaded) {
    closeBlackOverlay()
    readyToShowCutScene.unsubscribe(closeBlackOverlayOnceOnVisualsLoaded)
  }
}

let sortedBranchUnits = Computed(function(){
  let units = clone previewGoods.get()?.units
  if (units)
    return units
      .filter(@(u) u not in campMyUnits.get())
      .sort(@(a,b) (campUnitsCfg.get()?[b].mRank ?? 0) <=> (campUnitsCfg.get()?[a].mRank ?? 0))
})

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
  watch = [previewGoodsUnit, schRewards, previewGoods]
  size = (previewGoods.get()?.units.len() ?? 0) > 1
    ? [unitPlateSize[0] * 2 + gapForBranch, SIZE_TO_CONTENT]
    : flex()
  halign = ALIGN_LEFT
  children = (previewGoods.get()?.units.len() ?? 0) > 1
    ? @() {
        watch = sortedBranchUnits
        flow = FLOW_VERTICAL
        gap = gapForBranch
        children = arrayByRows((sortedBranchUnits.get() ?? []).map(@(u) branchUnitsBlock(u)), 2)
          .map(@(u)
            {
              flow = FLOW_HORIZONTAL
              gap = gapForBranch
              children = u
            })
      }
    : previewGoodsUnit.get()?.platoonUnits.len() == 0 ? leftBlockSingleUnit
    : leftBlockPlatoon
}

let leftBlock = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = verticalGap
  children = [
    @() (previewGoods.get()?.units.len() ?? 0) <= 1 ? { watch = previewGoods }
      : {
          watch = previewGoods
          rendObj = ROBJ_TEXT
          text = loc("offer/airBranch/descBuy", {count =(previewGoods.get()?.units.len() ?? 0)})
        }.__update(fontSmall)
    @() {
      watch = needScroll
      size = !needScroll.get()
        ? flex()
        : [unitPlateSizeSingle[0] * 2 + 2 * gapForBranch, SIZE_TO_CONTENT]
      children = [
        !needScroll.get() ? leftBlockUnits
          : pannableArea(leftBlockUnits, {}, { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
        !needScroll.get() ? null
          : scrollArrowsBlock
      ]
    }
  ]
}

let previewWnd = @() {
  watch = needShowUi
  key = openCount
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = verticalGap
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  stopMouse = true
  stopHotkeys = true

  function onAttach() {
    addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    isWindowAttached(true)
    if (transitionThroughBlackScreen) {
      showBlackOverlay()
      if (!readyToShowCutScene.value)
        readyToShowCutScene.subscribe(closeBlackOverlayOnceOnVisualsLoaded)
      else
        closeBlackOverlay()
    }
  }

  function onDetach() {
    removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    isWindowAttached(false)
  }

  children = !needShowUi.value ? doubleClickListener(@() needShowUi(true))
    : [
        {
          size = [flex(), SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          children = [
            {
              pos = [-doubleSideGradientPaddingX, 0]
              flow = FLOW_HORIZONTAL
              children = [
                mkHeader
                @() {
                  watch = [previewGoodsUnit, schRewards, activeOffer, previewGoods]
                  size = [0, 0]
                  children = activeOffer.get()?.id != previewGoods.get()?.id ? null :
                    mkGiftSchRewardBtn(
                      schRewards.get()?[$"gift_{previewGoodsUnit.get()?.campaign}_offer"]
                      aTimeHeaderStart,
                      skipAnimsOnce)
                }
              ]
            }
            balanceBlock
          ]
        }
        {
          size = flex()
          children = [
            leftBlock
            rightBlock
          ]
        }
      ]
}

registerScene("goodsUnitPreviewWnd", previewWnd, closeGoodsPreview, openCount)
