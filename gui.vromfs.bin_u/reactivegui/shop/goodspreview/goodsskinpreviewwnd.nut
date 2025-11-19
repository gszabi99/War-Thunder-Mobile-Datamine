from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { eventbus_subscribe } = require("eventbus")
let { defer, resetTimeout } = require("dagor.workcycle")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { registerScene } = require("%rGui/navState.nut")
let { hideModals, unhideModals } = require("%rGui/components/modalWindows.nut")
let { GPT_SKIN, previewType, previewGoods, previewGoodsUnit, closeGoodsPreview, openPreviewCount,
  HIDE_PREVIEW_MODALS_ID
} = require("%rGui/shop/goodsPreviewState.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { opacityAnims, colorAnims, mkPreviewHeader, mkPriceWithTimeBlock, mkPreviewItems, doubleClickListener,
  ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimePackNameBack, aTimeBackBtn, aTimeInfoItem, aTimePriceFull,
  aTimeInfoItemOffset, aTimeInfoLight, horGap, activeItemHint
} = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { start_prem_cutscene, stop_prem_cutscene, get_prem_cutscene_preset_ids, set_load_sounds_for_model, SHIP_PRESET_TYPE, TANK_PRESET_TYPE,
  AIR_FIGHTER_PRESET_TYPE, AIR_BOMBER_PRESET_TYPE } = require("hangar")
let { loadedHangarUnitName, setCustomHangarUnit, resetCustomHangarUnit,
  hangarUnitDataBackup } = require("%rGui/unit/hangarUnit.nut")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { rnd_int } = require("dagor.random")
let { SHIP, AIR } = require("%appGlobals/unitConst.nut")
let { mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")
let { getUnitTags } = require("%appGlobals/unitTags.nut")
let { showBlackOverlay, closeBlackOverlay } = require("%rGui/shop/blackOverlay.nut")
let { get_settings_blk } = require("blkGetters")
let { doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")


let TIME_TO_SHOW_UI = 5.0 
let TIME_TO_SHOW_UI_AFTER_SHOT = 0.3

let verticalGap = hdpx(20)

let isWindowAttached = Watched(false)
let needShowUi = Watched(false)
let skipAnimsOnce = Watched(false)
let openCount = Computed(@() previewType.get() == GPT_SKIN ? openPreviewCount.get() : 0)


let aTimeHeaderStart = 0
let aTimePackInfoStart = aTimePackNameFull
let aTimePackInfoHeader = 0.3
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
  let unitName = previewGoods.get()?.skins.keys()[0]
  if (!unitName)
    return null

  local res = campUnitsCfg.get()?[unitName]
  let skin = previewGoods.get()?.skins[unitName]
  if (skin != null) {
    res = clone res
    res.currentSkins <- clone (res?.currentSkins ?? {})
    res.currentSkins[unitName] <- skin
  }
  return res
})

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
eventbus_subscribe("onHangarModelStartLoad", @(_) readyToShowCutScene.set(false))
eventbus_subscribe(cutSceneWaitForVisualsLoaded ? "onHangarModelVisualsLoaded" : "onHangarModelLoaded", @(_) readyToShowCutScene.set(true))

let needShowCutscene = keepref(Computed(@() unitForShow.get() != null
  && loadedHangarUnitName.get() == getTagsUnitName(unitForShow.get()?.name ?? "")
  && readyToShowCutScene.get() ))

function showCutscene(v) {
  if (!v)
    stop_prem_cutscene()
  else if (!needShowUi.get() && !skipAnimsOnce.get()) {
    let unitType = unitForShow.get()?.unitType ?? ""
    local presetType = TANK_PRESET_TYPE
    if (unitType == SHIP)
      presetType = SHIP_PRESET_TYPE
    else if (unitType == AIR) {
      let tags = getUnitTags(unitForShow.get().name)
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
showCutscene(needShowCutscene.get())
needShowCutscene.subscribe(showCutscene)

function openDetailsWnd() {
  hangarUnitDataBackup.set({
    name = unitForShow.get().name,
    custom = unitForShow.get(),
  })
  let cfg = {
    name = unitForShow.get()?.name
    isUpgraded = previewGoodsUnit.get()?.isUpgraded ?? false
    canShowOwnUnit = false
  }
  let { currentSkins = null } = unitForShow.get()
  if (currentSkins != null && currentSkins != previewGoodsUnit.get()?.currentSkins)
    cfg.currentSkins <- currentSkins
  unitDetailsWnd(cfg)
}


let mkHeader = @() mkPreviewHeader(
  Computed(@() previewGoods.get()?.offerClass == "seasonal" || previewGoods.get()?.meta.eventId
    ? loc("seasonalOffer")
    : loc("limitedTimeOffer")),
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
      children = mkPreviewItems(previewGoods.get(), aTimePackInfoStart + aTimeFirstItemOfset)
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
    (previewGoods.get()?.price.price ?? 0) <= 0 ? null
      : mkCurrencyBalance(previewGoods.get().price.currencyId)
  ]
  animations = opacityAnims(aTimeBackBtn, aTimePackNameBack)
}

let unitHeaderBlock = @() {
  watch = unitForShow
  children = mkPlatoonOrUnitTitle(unitForShow.get())
  animations = opacityAnims(aTimePackInfoHeader, aTimePackInfoStart)
}

let goodsBlock = {
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  gap = verticalGap
  children = [
    packInfo
    {
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      valign = ALIGN_CENTER
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = hdpx(5)
          valign = ALIGN_CENTER
          children = mkTextRow(
            loc("reward/skin_for"),
            @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmallAccentedShaded),
            { ["{unitName}"] = unitHeaderBlock } 
          )
        }
        unitInfoButton
      ]
      animations = opacityAnims(aTimePackInfoHeader, aTimePackInfoStart)
    }
  ]
}
let rightBlock = {
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  gap = hdpx(20)
  children = [
    goodsBlock
    {
      pos = [doubleSideGradientPaddingX, 0]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_BOTTOM
      children = mkPriceWithTimeBlock(aTimePriceStart)
    }
  ]
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
  touchMarginPriority = TOUCH_BACKGROUND
  stopMouse = true
  stopHotkeys = true

  function onAttach() {
    isWindowAttached.set(true)
    if (transitionThroughBlackScreen) {
      showBlackOverlay()
      if (!readyToShowCutScene.get())
        readyToShowCutScene.subscribe(closeBlackOverlayOnceOnVisualsLoaded)
      else
        closeBlackOverlay()
    }
  }
  onDetach = @() isWindowAttached.set(false)

  children = !needShowUi.get() ? doubleClickListener(@() needShowUi.set(true)):
   [
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          children = [
            mkHeader
            balanceBlock
          ]
        }
        {
          size = flex()
          children = rightBlock
        }
      ]
}

registerScene("goodsSkinPreviewWnd", previewWnd, closeGoodsPreview, openCount)
