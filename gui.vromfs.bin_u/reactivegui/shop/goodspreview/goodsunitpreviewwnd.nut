from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { eventbus_subscribe } = require("eventbus")
let { defer, resetTimeout } = require("dagor.workcycle")
let { registerScene } = require("%rGui/navState.nut")
let { GPT_UNIT, GPT_BLUEPRINT, previewType, previewGoods, previewGoodsUnit, closeGoodsPreview, openPreviewCount
} = require("%rGui/shop/goodsPreviewState.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { opacityAnims, colorAnims, mkPreviewHeader, mkPriceWithTimeBlock, mkPreviewItems, doubleClickListener,
  ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimePackNameBack, aTimeBackBtn, aTimeInfoItem,
  aTimeInfoItemOffset, aTimeInfoLight, horGap, activeItemHint
} = require("goodsPreviewPkg.nut")
let { start_prem_cutscene, stop_prem_cutscene, get_prem_cutscene_preset_ids, set_load_sounds_for_model, SHIP_PRESET_TYPE, TANK_PRESET_TYPE,
  AIR_FIGHTER_PRESET_TYPE, AIR_BOMBER_PRESET_TYPE } = require("hangar")
let { loadedHangarUnitName, setCustomHangarUnit, resetCustomHangarUnit,
  hangarUnitDataBackup } = require("%rGui/unit/hangarUnit.nut")
let { isPurchEffectVisible, requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { rnd_int } = require("dagor.random")
let { SHIP, AIR } = require("%appGlobals/unitConst.nut")
let { getPlatoonOrUnitName, getUnitPresentation, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitSelUnderlineFullSize, unitPlatesGap, unitPlateSmall, mkUnitRank,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSelectedUnderlineVert,
  unitPlateWidth, unitPlateHeight
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
let { schRewards, onSchRewardReceive } = require("%rGui/shop/schRewardsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { schRewardInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { activeOffer } = require("%rGui/shop/offerState.nut")

let TIME_TO_SHOW_UI = 5.0 //timer need to show UI even with bug with cutscene
let TIME_TO_SHOW_UI_AFTER_SHOT = 0.3

let unitPlateSize = unitPlateSmall
let unitPlateSizeMain = unitPlateSize.map(@(v) v * 1.16)
let unitPlateSizeSingle = unitPlateSize.map(@(v) v * 1.3)
let verticalGap = hdpx(20)

let isWindowAttached = Watched(false)
let needShowUi = Watched(false)
let skipAnimsOnce = Watched(false)
let openCount = Computed(@() previewType.value == GPT_UNIT || previewType.value == GPT_BLUEPRINT ? openPreviewCount.get() : 0)

//anim pack info
let aTimePackInfoStart = aTimePackNameFull
let aTimePackInfoHeader = 0.3
let aTimePackUnitInfoStart = aTimePackInfoHeader + 0.05
let aTimePackUnitPlates = 0.3
let aTimePackUnitPlatesOffset = 0.05
let aTimeFirstItemOfset = 0.1
let aTimeInfoHeaderFull = aTimeInfoLight + 0.3 * aTimeInfoItem + aTimeFirstItemOfset + 3 * aTimeInfoItemOffset
//anim price and time
let aTimePriceStart = aTimePackInfoStart + aTimeInfoHeaderFull

function mkGiftSchRewardBtn(giftSchReward, posX) {
  local { isReady = false } = giftSchReward
  function schRewardAndSkipAnim(){
    onSchRewardReceive(giftSchReward)
    skipAnimsOnce(true)
  }
  if (!isReady)
    return null
  local isPurchasing = Computed(@() schRewardInProgress.value == giftSchReward.id)
  return {
    size = [hdpx(130),hdpx(130)]
    pos = [posX + verticalGap,0]
    rendObj = ROBJ_IMAGE
    image = Picture("ui/gameuiskin#offer_gift_icon.avif:0:P")
    behavior = Behaviors.Button
    onClick = schRewardAndSkipAnim
    children = [
      {
        hplace = ALIGN_RIGHT
        margin = [hdpx(10), hdpx(10), 0, 0]
        children = priorityUnseenMark
      }
      @() {
        watch = isPurchasing
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = isPurchasing.get() ? spinner : null
      }
    ]
  }
}

let showUi = @() needShowUi(true)
isWindowAttached.subscribe(function(v) {
  if (!v)
    return
  needShowUi(skipAnimsOnce.value)
  if (!skipAnimsOnce.value)
    resetTimeout(TIME_TO_SHOW_UI, showUi)
  else {
    skipAnimsOnce(false)
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
  return previewGoodsUnit.value.__merge({ name = unitName })
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
  && loadedHangarUnitName.value == unitForShow.value?.name
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
    name = previewGoodsUnit.value?.name
    isUpgraded = previewGoodsUnit.value?.isUpgraded ?? false
    canShowOwnUnit = false
  })
  skipAnimsOnce(true)
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


function mkUnitPlate(idx, unit, platoonUnit, onSelectUnit = null) {
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isSelected = Computed(@() onSelectUnit != null && curSelectedUnitId.value == platoonUnit.name)
  let size = idx != 0 ? unitPlateSize
    : onSelectUnit == null ? unitPlateSizeSingle
    : unitPlateSizeMain

  return {
    behavior = Behaviors.Button
    onClick = onSelectUnit
    sound = { click  = "choose" }
    children = [
      {
        size
        children = [
          mkUnitBg(unit)
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(platoonUnitFull)
          mkUnitTexts(platoonUnitFull, loc(p.locId))
          mkUnitRank(unit)
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
  children = [ { name = previewGoodsUnit.value.name, reqLevel = 0 } ]
    .extend(previewGoodsUnit.value?.platoonUnits)
    .map(@(pu, idx) mkUnitPlate(idx, previewGoodsUnit.value, pu, @() curSelectedUnitId(pu.name)))
}

let singleUnitBlock = @() {
  watch = [previewGoodsUnit, previewType]
  children = previewType.get() == GPT_BLUEPRINT
    ? mkBlueprintUnitPlate(previewGoodsUnit.get())
    : mkUnitPlate(0, previewGoodsUnit.value, { name = previewGoodsUnit.value.name, reqLevel = 0 })
}

let mkHeader = @() mkPreviewHeader(
  Computed(@() previewGoods.get()?.offerClass == "seasonal" ? loc("seasonalOffer")
    : previewGoodsUnit.get() ? getPlatoonOrUnitName(previewGoodsUnit.get(), loc)
    : ""),
  closeGoodsPreview,
  0)

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

let itemsDesc = {
  padding = [hdpx(20), hdpx(20)]
  rendObj = ROBJ_TEXT
  valign = ALIGN_CENTER
  text = loc("offer/itemsDesc")
  animations = opacityAnims(aTimePackInfoHeader, aTimePackInfoStart)
}.__update(fontSmall)

let leftBlock = {
  size = flex()
  flow = FLOW_VERTICAL
  children = [
    platoonUnitsBlock
    { size = flex() }
    itemsDesc
    packInfo(-1, { pos = [unitSelUnderlineFullSize, 0] })
  ]
}

let leftBlockSingleUnit = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = verticalGap * 2
  children = [
    singleUnitBlock
    packInfo
  ]
}

let rightBlock = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = verticalGap
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = unitInfoPanel({
        maxHeight = hdpx(600)
        hplace = ALIGN_RIGHT
        behavior = [ Behaviors.Button, HangarCameraControl ]
        eventPassThrough = true
        onClick = openDetailsWnd
        clickableInfo = loc("msgbox/btn_more")
      }, mkUnitTitle)
      animations = opacityAnims(aTimeBackBtn, aTimePackNameBack)
    }
    {
      size = [SIZE_TO_CONTENT, flex()]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      children = mkPriceWithTimeBlock(aTimePriceStart)
    }
  ]
}

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != "unit" && g.gType != "unitUpgrade" && g.gType != "unitLevel")
let markPurchasesSeenDelayed = function(purchList) {
  defer(function() {
    local unit = myUnits.value?[purchList.findvalue(@(_) true)?.goods[0].id]
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

let previewWnd = @() {
  watch = needShowUi
  key = openCount
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = verticalGap
  behavior = HangarCameraControl
  stopMouse = true
  stopHotkeys = true

  onAttach = function() {
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

  onDetach = function() {
    removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    isWindowAttached(false)
  }

  children = !needShowUi.value ? doubleClickListener(@() needShowUi(true))
    : [
        {
          size = [flex(), SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          children = [
            mkHeader
            balanceBlock
          ]
        }
        @() {
          watch = [previewGoodsUnit, schRewards, previewGoods, activeOffer]
          size = flex()
          children = [
            previewGoodsUnit.get()?.platoonUnits.len() == 0 ? leftBlockSingleUnit : leftBlock
            activeOffer.get()?.id == previewGoods.get()?.id ? mkGiftSchRewardBtn(schRewards.get()?[$"gift_{previewGoodsUnit.get()?.campaign}_offer"],
              previewGoodsUnit.get()?.platoonUnits.len() ? unitPlateSizeMain[0] : unitPlateSizeSingle[0]) : null
            rightBlock
          ]
        }
      ]
}

registerScene("goodsUnitPreviewWnd", previewWnd, closeGoodsPreview, openCount)
