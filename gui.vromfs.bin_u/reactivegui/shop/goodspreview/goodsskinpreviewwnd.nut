from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer, resetTimeout
from "eventbus" import eventbus_subscribe
from "hangar" import set_load_sounds_for_model
from "wt.behaviors" import HangarCameraControl
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%appGlobals/pServer/profile.nut" import campUnitsCfg
from "%appGlobals/rewardType.nut" import G_SKIN, unitRewardTypes
from "%rGui/components/infoButton.nut" import infoEllipseButton
from "%rGui/components/modalWindows.nut" import hideModals, unhideModals
from "%rGui/mainMenu/balanceComps.nut" import mkCurrencyBalance
from "%rGui/navState.nut" import registerScene
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_TINY
from "%rGui/shop/goodsPreview/goodsPreviewHint.nut" import activeRewardHint
from "%rGui/shop/goodsPreview/goodsPreviewPkg.nut" import opacityAnims, colorAnims, mkPreviewHeader,
  mkPriceWithTimeBlock, mkPreviewItems, doubleClickListener, ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull,
  aTimePackNameBack, aTimeBackBtn, aTimeInfoItem, aTimePriceFull, aTimeInfoItemOffset, aTimeInfoLight, horGap
from "%rGui/shop/goodsPreview/unitCutscene.nut" import unitForCutscene
from "%rGui/shop/goodsPreviewState.nut" import GPT_SKIN, previewType, previewGoods, previewGoodsUnit,
  closeGoodsPreview, openPreviewCount, HIDE_PREVIEW_MODALS_ID
from "%rGui/unit/components/unitInfoPanel.nut" import mkUnitTitle
from "%rGui/unit/hangarUnit.nut" import setCustomHangarUnit, resetCustomHangarUnit, hangarUnitDataBackup
from "%rGui/unit/unitPurchaseEffectScene.nut" import isPurchEffectVisible
from "%rGui/unitDetails/unitDetailsState.nut" import openUnitDetailsWnd


const TIME_TO_SHOW_UI = 5.0 
const TIME_TO_SHOW_UI_AFTER_SHOT = 0.3

const verticalGap = hdpx(20)

let isWindowAttached = Watched(false)
let needShowUi = Watched(false)
let skipAnimsOnce = Watched(false)
let openCount = Computed(@() previewType.get() == GPT_SKIN ? openPreviewCount.get() : 0)


const aTimeHeaderStart = 0
let aTimePackInfoStart = aTimePackNameFull
const aTimePackInfoHeader = 0.3
const aTimeFirstItemOfset = 0.1
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
  if (!isWindowAttached.get())
    return null
  let skinReward = previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_SKIN)
  let unitName = skinReward?.id
  if (unitName == null)
    return null

  let skin = skinReward?.subId
  local res = campUnitsCfg.get()?[unitName]
  if (res != null && skin != null) {
    res = clone res
    res.skin <- skin
  }
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
  let skin = unitForShow.get()?.skin
    ?? unitForShow.get()?.currentSkins[unitForShow.get()?.name] 
  if (skin != null)
    cfg.skin <- skin
  openUnitDetailsWnd(cfg)
}

let packInfo = {
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = previewGoods
      flow = FLOW_HORIZONTAL
      children = mkPreviewItems(
        (previewGoods.get()?.rewards ?? []).filter(@(r) r.gType not in unitRewardTypes),
        aTimePackInfoStart + aTimeFirstItemOfset)
      animations = colorAnims(aTimePackInfoHeader, aTimePackInfoStart)
    }
    {
      padding = const [REWARD_STYLE_TINY.boxGap, 0]
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
  ]
  animations = opacityAnims(aTimeBackBtn, aTimePackNameBack)
}

let header = @() mkPreviewHeader(
  Computed(@() previewGoods.get()?.offerClass == "seasonal" || previewGoods.get()?.meta.event_id
    ? loc("seasonalOffer")
    : loc("limitedTimeOffer")),
  closeGoodsPreview,
  aTimeHeaderStart,
  [],
  balanceBlock)

let unitHeaderBlock = @() {
  watch = unitForShow
  children = mkUnitTitle(unitForShow.get())
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
  size = FLEX
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  gap = hdpx(20)
  children = [
    goodsBlock
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_BOTTOM
      children = mkPriceWithTimeBlock(aTimePriceStart)
    }
  ]
}

let previewWnd = @() {
  watch = needShowUi
  key = openCount
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  stopMouse = true
  stopHotkeys = true

  onAttach = @() isWindowAttached.set(true)
  onDetach = @() isWindowAttached.set(false)

  children = !needShowUi.get() ? doubleClickListener(@() needShowUi.set(true))
    : [
        header
        {
          size = FLEX
          children = rightBlock
        }
      ]
}

registerScene("goodsSkinPreviewWnd", previewWnd, closeGoodsPreview, openCount)
