from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { defer, resetTimeout } = require("dagor.workcycle")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { registerScene, moveSceneToTop } = require("%rGui/navState.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { GPT_UNIT, previewType, previewGoods, previewGoodsUnit, closeGoodsPreview, openPreviewCount
} = require("%rGui/shop/goodsPreviewState.nut")
let { infoBlueButton } = require("%rGui/components/infoButton.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY } = require("%rGui/components/gradientDefComps.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { opacityAnims, colorAnims, mkPreviewHeader, mkPriceWithTimeBlock, mkPreviewItems, doubleClickListener,
  ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimePackNameBack, aTimeBackBtn, aTimeInfoItem,
  aTimeInfoItemOffset, aTimeInfoLight, aTimePriceFull, horGap, mkActiveItemHint, mkInfoText
} = require("goodsPreviewPkg.nut")
let { start_prem_cutscene, stop_prem_cutscene, get_prem_cutscene_preset_ids, SHIP_PRESET_TYPE, TANK_PRESET_TYPE } = require("hangar")
let { loadedHangarUnitName, isLoadedHangarUnitUpgraded, setCustomHangarUnit, isHangarUnitLoaded
} = require("%rGui/unit/hangarUnit.nut")
let { mkUnitBonuses } = require("%rGui/unit/components/unitInfoComps.nut")
let { isPurchEffectVisible, requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { gradCircularSqCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { rnd_int } = require("dagor.random")
let { SHIP } = require("%appGlobals/unitConst.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")


let TIME_TO_SHOW_UI = 5.0 //timer need to show UI eve with bug with cutscene
let TIME_TO_SHOW_UI_AFTER_SHOT = 0.3

let isWindowAttached = Watched(false)
let needShowUi = Watched(false)
let skipAnimsOnce = Watched(false)
let isOpened = Computed(@() previewType.value == GPT_UNIT)

//anim pack info
let aTimePackInfoStart = aTimePackNameFull
let aTimePackInfoHeader = 0.3
let aTimePackUnitInfoStart = aTimePackInfoStart + 0.15
let aTimePackUnitInfo = 0.3
let aTimeFirstItemOfset = 0.1
let aTimeInfoHeaderFull = aTimeInfoLight + 0.3 * aTimeInfoItem + aTimeFirstItemOfset + 3 * aTimeInfoItemOffset
//anim price and time
let aTimePriceStart = aTimePackInfoStart + aTimeInfoHeaderFull


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
  if (v && isOpened.value)
    closeGoodsPreview()
})

subscribe("onCutsceneUnitShoot", @(_) resetTimeout(TIME_TO_SHOW_UI_AFTER_SHOT, showUi))

let unitForShow = keepref(Computed(@() isWindowAttached.value ? previewGoodsUnit.value : null))
unitForShow.subscribe(function(unit) {
  if (unit != null)
    setCustomHangarUnit(unit)
})

let needShowCutscene = keepref(Computed(@() unitForShow.value != null
  && loadedHangarUnitName.value == unitForShow.value?.name
  && isLoadedHangarUnitUpgraded.value == (unitForShow.value?.isUpgraded ?? false)
  && isHangarUnitLoaded.value ))
let function showCutscene(v) {
  if (!v)
    stop_prem_cutscene()
  else if (!needShowUi.value && !skipAnimsOnce.value) {
    let unitType = unitForShow.value?.unitType ?? ""
    let presetIds = get_prem_cutscene_preset_ids(unitType == SHIP ? SHIP_PRESET_TYPE : TANK_PRESET_TYPE)
    if(presetIds.len() > 0)
      start_prem_cutscene(presetIds[rnd_int(0, presetIds.len()-1)])
  }
}
showCutscene(needShowCutscene.value)
needShowCutscene.subscribe(showCutscene)


let rightBottomBlock = mkPriceWithTimeBlock(aTimePriceStart)
let headerLeft = mkPreviewHeader(Computed(@() unitForShow.value ? getPlatoonOrUnitName(unitForShow.value, loc) : ""), closeGoodsPreview, 0)

let function mkUnitShortInfo(unit) {
  let { isUpgraded = false, isPremium = false, unitClass = "", unitType = "", mRank = 1 } = unit
  let isElite = isUpgraded || isPremium
  let unitTypeName = loc($"mainmenu/type_{unitClass == "" ? unitType : unitClass}")
  return {
    rendObj = ROBJ_TEXT
    color = isElite ? premiumTextColor : 0xFFFFFFFF
    text = comma.concat(
      isElite ? loc("shop/premUnitType", { unitType = unitTypeName }) : unitTypeName,
      " ".concat(loc("options/mRank"), getRomanNumeral(mRank))
    )
    animations = opacityAnims(aTimePackUnitInfo, aTimePackUnitInfoStart, "element_appear")
  }.__update(fontSmall)
}

let unitInfoChildren = @(unit) unit == null ? []
  : [
      mkInfoText(loc("shop/youWillGet"), aTimePriceStart + aTimePriceFull)
      mkUnitShortInfo(unit)
      mkUnitBonuses(unit, { animations = opacityAnims(aTimePackUnitInfo, aTimePackUnitInfoStart) })
    ]

let activeItemHint = {
  size = [0, 0]
  children = mkActiveItemHint({ pos = [2 * doubleSideGradientPaddingX, -doubleSideGradientPaddingY] })
}

let packInfo = @() doubleSideGradient.__merge({
  watch = [previewGoods, previewGoodsUnit]
  pos = [-doubleSideGradientPaddingX, 0]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = unitInfoChildren(previewGoodsUnit.value).append(
    { size = [hdpx(10), hdpx(10)] }
    mkInfoText(loc("shop/additionalBonus"), aTimePriceStart + aTimePriceFull + 0.3)
    {
      flow = FLOW_HORIZONTAL
      children = [
        mkPreviewItems(previewGoods.value, aTimePackInfoStart + aTimeFirstItemOfset)
        activeItemHint
      ]
    }
  )
  animations = colorAnims(aTimePackInfoHeader, aTimePackInfoStart)
})

let unitInfoButton = {
  size = [evenPx(70), evenPx(70)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = [evenPx(95), evenPx(95)]
      rendObj = ROBJ_9RECT
      image = gradCircularSqCorners
      texOffs = [gradCircCornerOffset, gradCircCornerOffset]
      screenOffs = hdpx(20)
      color = 0xFF000000
    }
    infoBlueButton(
      function() {
        unitDetailsWnd({
          name = previewGoodsUnit.value?.name
          isUpgraded = previewGoodsUnit.value?.isUpgraded ?? false
          canShowOwnUnit = false
        })
        skipAnimsOnce(true)
      },
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

let headerPanel = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      valign = ALIGN_CENTER
      children = [
        headerLeft
        balanceBlock
      ]
    }
    packInfo
  ]
}

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != "unit" && g.gType != "unitUpgrade" && g.gType != "unitLevel")
let markPurchasesSeenDelayed = function(purchList) {
  defer(function() {
    local unit = myUnits.value?[purchList.findvalue(@(_) true).goods[0].id]
    if (unit == null)
      return
    markPurchasesSeen(purchList.keys())
    requestOpenUnitPurchEffect(unit)
  })
}

let previewWnd = @() {
  watch = needShowUi
  key = isOpened
  size = flex()
  behavior = Behaviors.HangarCameraControl
  stopMouse = true
  stopHotkeys = true

  onAttach = function() {
    addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    isWindowAttached(true)
  }

  onDetach = function() {
    removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    isWindowAttached(false)
  }

  children = !needShowUi.value ? doubleClickListener(@() needShowUi(true))
    : {
        size = flex()
        margin = saBordersRv
        children = [
          headerPanel
          rightBottomBlock
        ]
      }
}

registerScene("goodsUnitPreviewWnd", previewWnd, closeGoodsPreview, isOpened)
openPreviewCount.subscribe(@(_) moveSceneToTop("goodsUnitPreviewWnd"))
