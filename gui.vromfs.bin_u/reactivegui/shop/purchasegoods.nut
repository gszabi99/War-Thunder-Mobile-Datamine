from "%globalsDarg/darg_library.nut" import *
from "sound_wt" import playSound
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/pServerApi.nut" import shopPurchaseInProgress, buy_goods, buy_offer, registerHandler,
  get_profile, get_all_configs
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import G_UNIT, G_UNIT_UPGRADE, G_CURRENCY, G_BOOSTER, unitRewardTypes
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, CS_INCREASED_ICON
from "%rGui/components/msgBox.nut" import msgBoxText, openMsgBox
from "%rGui/navState.nut" import tryResetToMainScene
from "%rGui/rewards/rewardViewInfo.nut" import isEmptyByRType
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo
from "%rGui/shop/discounts.nut" import discountsToApply, applyDiscount
from "%rGui/shop/goodsView/goods.nut" import getGoodsLocName
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase, closePurchaseAndBalanceBoxes
from "%rGui/shop/offerState.nut" import activeOffer
from "%rGui/shop/personalGoodsPurchase.nut" import purchasePersonalGoods
from "%rGui/shop/personalGoodsState.nut" import activePersonalGoods
from "%rGui/shop/rewardsToShopGoods.nut" import personalGoodsToShopGoods
from "%rGui/shop/shopCommon.nut" import getGoodsType
from "%rGui/shop/shopConst.nut" import SGT_EVT_CURRENCY
from "%rGui/shop/shopState.nut" import shopGoodsAllCampaigns
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/unit/unseenUnits.nut" import markUnitsUnseen
from "types" import String


let logShop = log_with_prefix("[SHOP] ")


function getCantPurchaseReason(goods) {
  let units = []
  local hasNotPurchasedUnits = false
  foreach (r in goods.rewards)
    if (r.gType in unitRewardTypes)
      if (isEmptyByRType?[r.gType](r.id, r.subId, servProfile.get(), serverConfigs.get()) ?? false)
        units.append(r.id)
      else
        hasNotPurchasedUnits = true
  if (units.len() > 0 && !hasNotPurchasedUnits)
    return {
      canPurchase = false
      logText = $"ERROR: Units already received: {", ".join(units)}"
      msgboxText = loc("trophy/prizeAlreadyReceived",
        { prizeText = ", ".join(units.map(
            @(unitName) colorize(userlogTextColor, getUnitName(unitName)))) })
    }
  return null
}

function onGoodsError(err) {
  let errStr = err instanceof String ? err : err?.message ?? ""
  if (errStr.startswith("Wrong pay data")) {
    openMsgBox({ text = loc("error/Wrong pay data") })
    get_profile()
    get_all_configs()
  }
  else
    openMsgBox({ text = loc("msgbox/internal_error_header") })
}

registerHandler("onShopGoodsPurchase",
  function(res) {
    if (res?.error != null)
      onGoodsError(res.error)
  })

function purchaseGoodsImpl(goodsId, currencyId, price, count = 1) {
  if (shopPurchaseInProgress.get() != null)
    return "shopPurchaseInProgress"
  buy_goods(goodsId, currencyId, price, count, "onShopGoodsPurchase")
  return ""
}

registerHandler("onShopGoodsPurchaseSequence",
  function(result, context) {
    if (result?.error != null) {
      onGoodsError(result.error)
      return
    }

    let { nextGoods } = context
    if (nextGoods.len() == 0)
      return
    let { id, price } = nextGoods[0]
    let newNextGoods = clone nextGoods
    newNextGoods.remove(0)
    buy_goods(id, price.currencyId, price.price, 1, { id = "onShopGoodsPurchaseSequence", nextGoods = newNextGoods })
  })

function purchaseGoodsSeqImpl(goodsList) {
  if (shopPurchaseInProgress.get() != null)
    return "shopPurchaseInProgress"
  let nextGoods = goodsList.map(@(g) { id = g.id, price = g.price })
  let { id, price } = nextGoods[0]
  nextGoods.remove(0)
  buy_goods(id, price.currencyId, price.price, 1, { id = "onShopGoodsPurchaseSequence", nextGoods })
  return ""
}

registerHandler("onOfferPurchase",
  function(res, context) {
    if (res?.error != null)
      onGoodsError(res.error)
    else
      markUnitsUnseen(context.units)
  })

function purchaseOfferImpl(offer, currencyId, price) {
  if (shopPurchaseInProgress.get() != null)
    return "shopPurchaseInProgress"
  local units = []
  foreach (r in offer.rewards)
    if (r.gType == G_UNIT_UPGRADE || r.gType == G_UNIT)
      units.append(r.id)

  buy_offer(offer.campaign, offer.id, currencyId, price,
    { id = "onOfferPurchase", units })
  return ""
}

let mkCurrencyWithIcon = @(goods) function() {
  let { id = null, count = null } = goods?.rewards.findvalue(@(r) r.gType == G_CURRENCY)
  return {
    watch = currencyToFullId
    flow = FLOW_VERTICAL
    size = FLEX_H
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    gap = hdpx(30)
    children = [
      msgBoxText(loc("shop/orderQuestion"), { size = SIZE_TO_CONTENT })
      mkCurrencyComp(count, currencyToFullId.get()?[id] ?? id, CS_INCREASED_ICON)
      msgBoxText(loc("shop/cost"), { size = SIZE_TO_CONTENT })
    ]
  }
}

function getGoodsRemoveTime(goods) {
  if ("situation" in goods)  
    return null

  if ("endTime" in goods)
    return goods.endTime

  let { timeRanges = [] } = goods
  let time = serverTime.get()
  foreach (tr in timeRanges)
    if (tr.start <= time && tr.end > time)
      return tr.end
  return null
}

function startRemoveTimer(goods) {
  let timeLeft = (getGoodsRemoveTime(goods) ?? 0) - serverTime.get()
  if (timeLeft <= 0)
    clearExtTimer(closePurchaseAndBalanceBoxes)
  else
    resetExtTimeout(timeLeft, closePurchaseAndBalanceBoxes)
}

function mkLimitCountText(id, gType) {
  let configType = gType == G_BOOSTER ? "allBoosters" : "allItems"
  let limit = campConfigs.get()[configType]?[id].limit ?? 0
  if (limit <= 0)
    return null
  let count = (gType == G_BOOSTER ? servProfile.get()?.boosters[id].battlesLeft
    : servProfile.get()?.items[id].count) ?? 0

  return $"{count}/{limit}"
}

function purchaseGoods(goodsId, description = "", locParam = null, count = 1) {
  let personalGoods = activePersonalGoods.get()?[goodsId]
  if (personalGoods != null) {
    purchasePersonalGoods(personalGoods, personalGoodsToShopGoods(personalGoods))
    return
  }

  logShop($"User tries to purchase: {goodsId}")
  if (shopPurchaseInProgress.get() != null)
    return logShop($"ERROR: shopPurchaseInProgress: {shopPurchaseInProgress.get()}")
  let isOffer = activeOffer.get()?.id == goodsId
  let goods = isOffer ? activeOffer.get()
    : shopGoodsAllCampaigns.get()?[goodsId]
  if (goods == null)
    return logShop($"ERROR: Goods not found: {goodsId}")
  let { price, currencyId } = applyDiscount(goods, discountsToApply.get()).price
  let fullPrice = price * count
  let isPriceValid = fullPrice > 0 && currencyId != ""
  if (!isPriceValid)
    return logShop("ERROR: Invalid price")

  let { logText = null, msgboxText = null, canPurchase = true } = getCantPurchaseReason(goods)
  if (logText != null)
    logShop(logText)
  if (msgboxText != null)
     openMsgBox({ text = msgboxText })
  if (!canPurchase)
    return

  startRemoveTimer(goods)

  let currencyFullId = currencyToFullId.get()?[currencyId] ?? currencyId
  function purchase() {
    let errString = isOffer ? purchaseOfferImpl(goods, currencyFullId, fullPrice)
      : purchaseGoodsImpl(goodsId, currencyFullId, fullPrice, count)
    if (errString != "")
      logShop($"ERROR: {errString}")
    if (isOffer)
      tryResetToMainScene()
  }

  let limitCountText = mkLimitCountText(goods.rewards[0].id, goods.rewards[0].gType)
  let textItem = colorize(userlogTextColor, getGoodsLocName(goods, locParam).replace(" ", nbsp))

  openMsgBoxPurchase({
    text = getGoodsType(goods) == SGT_EVT_CURRENCY ? mkCurrencyWithIcon(goods)
      : description != ""
        ? loc("shop/needMoneyQuestion/desc", { item = textItem, description })
      : loc("shop/needMoneyQuestion", { item = textItem }),
    price = { price = fullPrice, currencyId = currencyFullId },
    limitCountText,
    purchase,
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(getGoodsType(goods)), $"pack {goods.id}")
    goodsId
  })
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money" )
}

function purchaseGoodsSeq(goodsList, name, description = "") {
  logShop($"User tries to purchase: ", goodsList.map(@(v) v.id))
  if (shopPurchaseInProgress.get() != null || goodsList.len() == 0)
    return logShop($"ERROR: shopPurchaseInProgress: {shopPurchaseInProgress.get()}")
  local sum = 0
  local currency = ""
  foreach (goods in goodsList) {
    let { price, currencyId } = goods.price
    let currencyFullId = currencyToFullId.get()?[currencyId] ?? currencyId
    if (currency == "")
      currency = currencyFullId
    let isPriceValid = price > 0 && currencyFullId != "" && currencyFullId == currency
    if (!isPriceValid) {
      logerr("Try to buy goods with invalid price")
      return
    }

    let { logText = null, msgboxText = null, canPurchase = true } = getCantPurchaseReason(goods)
    if (logText != null)
      logShop(logText)
    if (!canPurchase) {
      if (msgboxText != null)
        openMsgBox({ text = msgboxText })
      return
    }
    sum += price
  }

  function purchase() {
    let errString = purchaseGoodsSeqImpl(goodsList)
    if (errString != "")
      logShop($"ERROR: {errString}")
  }

  let textItem = colorize(userlogTextColor, name)

  openMsgBoxPurchase({
    text = description != ""
      ? loc("shop/needMoneyQuestion/desc", { item = textItem, description })
      : loc("shop/needMoneyQuestion", { item = textItem }),
    price = { price = sum, currencyId = currency },
    purchase,
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(getGoodsType(goodsList[0])), $"pack {",".join(goodsList.map(@(v) v.id))}")
  })
  playSound(currency == GOLD ? "meta_products_for_gold" : "meta_products_for_money" )
}



return {
  purchaseGoods
  purchaseGoodsSeq
}
