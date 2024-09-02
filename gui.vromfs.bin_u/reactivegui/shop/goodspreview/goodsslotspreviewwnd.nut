from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { playSound } = require("sound_wt")
let { registerScene } = require("%rGui/navState.nut")
let { GPT_SLOTS, previewType, previewGoods, closeGoodsPreview, openPreviewCount, GPT_BLUEPRINT, openedGoodsId
} = require("%rGui/shop/goodsPreviewState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { goodsLimitReset } = require("%appGlobals/pServer/campaign.nut")
let { serverTimeDay, getDay, untilNextDaySec } = require("%appGlobals/userstats/serverTimeDay.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { registerHandler, shopPurchaseInProgress, shopGenSlotInProgress,
  gen_goods_slots, buy_goods_slot, increase_goods_limit
} = require("%appGlobals/pServer/pServerApi.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_SHOP, PURCH_TYPE_GOODS_SLOT, PURCH_TYPE_GOODS_LIMIT, PURCH_TYPE_GOODS_REROLL_SLOTS,
  mkBqPurchaseInfo
} = require("%rGui/shop/bqPurchaseInfo.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { textButtonPricePurchase, buttonsHGap, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight, PRIMARY } = buttonStyles
let { getSlotsPreviewBg, getSlotsTexts } = require("%appGlobals/config/goodsPresentation.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM, getRewardPlateSize, progressBarHeight
} = require("%rGui/rewards/rewardStyles.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkRewardPlateTexts, mkRewardSearchPlate,
  mkRewardDisabledBkg, mkRewardReceivedMark
} = require("%rGui/rewards/rewardPlateComp.nut")
let { getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { revealAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkUnitFlag } = require("%rGui/unit/components/unitPlateComp.nut")


let MAX_BIG_SLOTS = 8
let maxWndWidth = min(saSize[0], hdpxi(2200))
let blockGap = buttonsHGap

let selBorderColor = 0xFFFFFFFF
let hoverBorderColor = 0x40404040
let borderHeight = hdpx(8)


let isAttached = Watched(false)
let openCount = Computed(@() previewType.get() == GPT_SLOTS ? openPreviewCount.get() : 0)
let rerollCost = Computed(@() serverConfigs.get()?.goodsRewardSlots[previewGoods.get()?.slotsPreset].rerollCost)
let rewardSlots = Computed(@() servProfile.get()?.rewardSlots[previewGoods.get()?.id])
let selIndex = Watched(-1)

let AUTO_REQUEST_AFTER_ERROR_TIME = 10
let freeRefreshErrorSoon = Watched(null)
let needFreeRefreshSlots = keepref(Computed(function() {
  if (!isAttached.get()
      || freeRefreshErrorSoon.get() == previewGoods.get()?.id
      || shopPurchaseInProgress.get() == previewGoods.get()?.id
      || shopGenSlotInProgress.get() == previewGoods.get()?.id
      || rerollCost.get() == null) //this mean that slots config is exists
    return false
  return getDay(rewardSlots.get()?.time ?? 0) != serverTimeDay.get()
}))

let resetError = @() freeRefreshErrorSoon.set(null)
registerHandler("autoGenerateGoodsSlots",
  function(res, context) {
    if (res?.error == null)
      return
    freeRefreshErrorSoon.set(context.goodsId)
    resetTimeout(AUTO_REQUEST_AFTER_ERROR_TIME, resetError)
  })

function freeRefreshSlots() {
  if (!needFreeRefreshSlots.get())
    return
  let { id = null } = previewGoods.get()
  if (id != null)
    gen_goods_slots(id, "", 0, { id = "autoGenerateGoodsSlots", goodsId = id })
}

needFreeRefreshSlots.subscribe(@(_) deferOnce(freeRefreshSlots))

rewardSlots.subscribe(@(_) selIndex.set(-1))

let txt = @(text, ovr = {}) { rendObj = ROBJ_TEXT, text }.__update(fontSmallAccented, ovr)

function balanceButtons() {
  let currencies = []
  let list = [
    previewGoods.get()?.price.currencyId
    previewGoods.get()?.limitResetPrice.currencyId
    rerollCost.get()?.currencyId
  ]
  foreach(c in list)
    if ((c ?? "") != "" && !currencies.contains(c))
      currencies.append(c)
  return {
    watch = [previewGoods, rerollCost]
    children = mkCurrenciesBtns(currencies)
  }
}

let headerPanel = {
  size = [flex(), gamercardHeight]
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = blockGap
  children = [
    backButton(closeGoodsPreview)
    @() {
      watch = [previewGoods, openedGoodsId]
      flow = FLOW_HORIZONTAL
      gap = hdpx(30)
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          color = 0xFFFFFFFF
          text = previewGoods.get() == null ? null
            : getGoodsLocName(previewGoods.get())
        }.__update(fontBig)
        infoTooltipButton(@() loc(getSlotsTexts(openedGoodsId.get()).description), { halign = ALIGN_LEFT },
          {
            size = [hdpx(52), hdpx(52)]
            fillColor = 0x80000000
            children = {
              rendObj = ROBJ_TEXT
              text = "i"
              halign = ALIGN_CENTER
            }.__update(fontTinyAccented)
          })
      ]
    }
    { size = flex() }
    balanceButtons
  ]
}

let highlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 25, 22, 31,-22))

let mkHightlightPlate = @(isSelected) {
  size = flex()
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      flipY = true
      image = highlight()
      animations = revealAnimation(0)
      transform = { rotate = 180 }
      opacity = 0.5
    }
    {
      size = [flex(), borderHeight]
      pos = [0, -borderHeight]
      rendObj = ROBJ_BOX
      hplace = ALIGN_TOP
      fillColor = isSelected ? selBorderColor : hoverBorderColor
    }
    !isSelected ? null
      : {
          pos = [0, -progressBarHeight]
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_LEFT
          padding = hdpx(5)
          children = mkRewardSearchPlate
        }
  ]
}

function mkTimeLeftInfo(ovr = {}) {
  let text = Computed(@() secondsToHoursLoc(untilNextDaySec(serverTime.get())))
  return @() {
    watch = openedGoodsId
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    children = [
      txt(loc(getSlotsTexts(openedGoodsId.get()).updateIn))
      @() txt(text.get(), { watch = text })
    ]
  }.__update(ovr)
}

function mkDisableBkgWithTooltip(isPurchased, rStyle) {
  let stateFlags = Watched(0)
  let key = {}

  return {
    key
    size = flex()
    behavior = Behaviors.Button
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, key, @() { content = mkTimeLeftInfo({ halign = ALIGN_CENTER }) })
    children = isPurchased ? mkRewardReceivedMark(rStyle) : mkRewardDisabledBkg
  }
}

function mkSlot(slotIdx, reward, rStyle) {
  let size = getRewardPlateSize(reward.slots, rStyle)
  let stateFlags = Watched(0)
  let isSelected = Computed(@() selIndex.get() == slotIdx)
  let unit = Computed(@() serverConfigs.value?.allUnits?[reward.id])

  return @() {
    watch = [isSelected, stateFlags, rewardSlots, unit]
    size
    behavior = Behaviors.Button
    onElemState = @(v) rewardSlots.get()?.isPurchased ? null : stateFlags(v)
    onClick = @() rewardSlots.get()?.isPurchased
        ? null
      : isSelected.get()
        ? unitDetailsWnd({ name = reward.id })
      : selIndex.set(slotIdx)
    sound = rewardSlots.get()?.isPurchased ? {} : { click  = "click" }

    children = [
      mkRewardPlateBg(reward, rStyle)
      mkRewardPlateImage(reward, rStyle)
      !isSelected.get() && !(stateFlags.get() & S_HOVER) ? null
        : mkHightlightPlate(isSelected.get())
      mkRewardPlateTexts(reward, rStyle)
      reward.rType == GPT_BLUEPRINT ? mkUnitFlag(unit.get(), rStyle) : null
      !rewardSlots.get()?.isPurchased ? null
        : mkDisableBkgWithTooltip(rewardSlots.get()?.purchasedIdx == slotIdx, rStyle)
    ]
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14 }]
  }
}

function fillRewardsByRows(goods, slotsInRowMax, style) {
  let res = []
  let rewards = goods.map(@(g) getRewardsViewInfo(g)[0])
  let totalSlots = rewards.reduce(@(tsRes, r) tsRes + r.slots, 0)
  let rowsCount = totalSlots / slotsInRowMax + ((totalSlots % slotsInRowMax) ? 1 : 0)
  if (rowsCount == 0)
    return res
  let slotsInRowMin = totalSlots / rowsCount + ((totalSlots % rowsCount) ? 1 : 0)

  local curRowSlots = slotsInRowMax
  foreach(slotIdx, r in rewards) {
    if (curRowSlots >= slotsInRowMin || curRowSlots + r.slots > slotsInRowMax) {
      res.append([])
      curRowSlots = 0
    }
    curRowSlots += r.slots
    res.top().append(mkSlot(slotIdx, r, style))
  }
  return res
}

function purchaseSelectedSlot(price, currencyId) {
  let slot = rewardSlots.get()?.goods[selIndex.get()][0]
  if (slot == null) {
    openMsgBox({ text = loc("msg/selectSlotForPurchase") })
    return
  }

  let { id } = previewGoods.get()
  let bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, PURCH_TYPE_GOODS_SLOT, $"{id}:{slot.gType}/{slot.id}x{slot.count}")
  if (showNoBalanceMsgIfNeed(price, currencyId, bqInfo))
    return
  buy_goods_slot(id, selIndex.get(), currencyId, price)
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")
}

function increaseLimit(price, currencyId) {
  let { id = null } = previewGoods.get()
  if (id == null)
    return
  let bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, PURCH_TYPE_GOODS_LIMIT, id)
  if (showNoBalanceMsgIfNeed(price, currencyId, bqInfo))
    return
  increase_goods_limit(id, currencyId, price)
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")
}

function rerollSlots(price, currencyId) {
  let { id = null } = previewGoods.get()
  if (id == null)
    return
  let bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, PURCH_TYPE_GOODS_REROLL_SLOTS, id)
  if (showNoBalanceMsgIfNeed(price, currencyId, bqInfo))
    return
  gen_goods_slots(id, currencyId, price)
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")
}

function purchButton(text, priceCfg, purchAction, purchCount = 0, styleOvr = {}) {
  let { price = 0, currencyId = "", priceInc = 0 } = priceCfg
  if (price <= 0 || currencyId == "")
    return null

  let priceFinal = price + priceInc * purchCount
  return textButtonPricePurchase(utf8ToUpper(text),
    mkCurrencyComp(priceFinal, currencyId)
    @() purchAction(priceFinal, currencyId),
    styleOvr)
}

function buttons() {
  let res = {
    watch = [shopGenSlotInProgress, shopPurchaseInProgress, previewGoods, rewardSlots, rerollCost,
      goodsLimitReset, serverTimeDay
    ]
    size = [SIZE_TO_CONTENT, defButtonHeight]
  }
  if (previewGoods.get() == null)
    return res

  let { id, price, limitResetPrice } = previewGoods.get()
  let { isPurchased = false } = rewardSlots.get()
  return res.__update({
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    valign = ALIGN_CENTER
    children = shopGenSlotInProgress.get() == id ? null
      : shopPurchaseInProgress.get() ? spinner
      : isPurchased
        ? [
            mkTimeLeftInfo()
            purchButton(loc("btn/skipWait"), limitResetPrice, increaseLimit,
              serverTimeDay.get() != getDay(goodsLimitReset.get()?[id].time ?? 0) ? 0
                : goodsLimitReset.get()?[id].count)
          ]
      : [
          purchButton(loc("btn/rerollItems"), rerollCost.get(), rerollSlots, 0, PRIMARY)
          purchButton(loc("btn/buySelected"), price, purchaseSelectedSlot)
        ]
  })
}

function content() {
  let isActual = Computed(@() shopGenSlotInProgress.get() != previewGoods.get()?.id
    && getDay(rewardSlots.get()?.time ?? 0) == serverTimeDay.get())
  return function() {
    let { goods = [] } = rewardSlots.get()
    let style = goods.len() > MAX_BIG_SLOTS ? REWARD_STYLE_SMALL : REWARD_STYLE_MEDIUM
    let { boxSize, boxGap } = style
    let slotsInRow = (maxWndWidth + boxGap) / (boxSize + boxGap)
    let rows = !isActual.get() || shopGenSlotInProgress.get() ? []
      : fillRewardsByRows(goods, slotsInRow, style)

    return {
      watch = [rewardSlots, isActual, shopGenSlotInProgress, openedGoodsId]
      size = flex()
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = blockGap
      children = [
        {
          size = [SIZE_TO_CONTENT, max(2, rows.len()) * (boxSize + boxGap) - boxGap]
          flow = FLOW_VERTICAL
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          gap = boxGap
          children = shopGenSlotInProgress.get() ? spinner
            : rows.map(@(children) {
                flow = FLOW_HORIZONTAL
                gap = boxGap
                children
              })
        }
        rewardSlots.get()?.isPurchased ? null
          : txt(rows.len() > 0 ? utf8ToUpper(loc("shop/pickOneItem")) : utf8ToUpper(loc(getSlotsTexts(openedGoodsId.get()).missing)))
        rows.len() > 0 ? buttons : null
      ]
    }
  }
}

let previewWnd = bgShaded.__merge({
  key = openCount
  size = flex()
  onAttach = @() isAttached.set(true)
  onDetach = @() isAttached.set(false)

  children = [
    @() {
      watch = previewGoods
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture(getSlotsPreviewBg(previewGoods.get()?.id))
      keepAspect = KEEP_ASPECT_FILL
    }
    {
      size = flex()
      margin = saBordersRv
      flow = FLOW_VERTICAL
      children = [
        headerPanel
        content()
      ]
    }
  ]
  animations = wndSwitchAnim
})

registerScene("goodsSlotsPreviewWnd", previewWnd, closeGoodsPreview, openCount)
