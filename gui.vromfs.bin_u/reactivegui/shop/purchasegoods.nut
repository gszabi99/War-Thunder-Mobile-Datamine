from "%globalsDarg/darg_library.nut" import *
let logShop = log_with_prefix("[SHOP] ")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { shopPurchaseInProgress, buy_goods, buy_offer, registerHandler, get_profile, get_all_configs
} = require("%appGlobals/pServer/pServerApi.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { G_UNIT, G_UNIT_UPGRADE, G_CURRENCY, unitRewardTypes } = require("%appGlobals/rewardType.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { shopGoodsAllCampaigns } = require("%rGui/shop/shopState.nut")
let { tryResetToMainScene } = require("%rGui/navState.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { activeOffer } = require("%rGui/shop/offerState.nut")
let { openMsgBoxPurchase, closePurchaseAndBalanceBoxes } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { msgBoxText, openMsgBox } = require("%rGui/components/msgBox.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { playSound } = require("sound_wt")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { SGT_EVT_CURRENCY } = require("%rGui/shop/shopConst.nut")
let { markUnitsUnseen } = require("%rGui/unit/unseenUnits.nut")
let { isEmptyByRType } = require("%rGui/rewards/rewardViewInfo.nut")


function getCantPurchaseReason(goods) {
  if ("rewards" in goods) {
    let units = []
    foreach (r in goods.rewards)
      if (r.gType in unitRewardTypes
          && (isEmptyByRType?[r.gType](r.id, r.subId, servProfile.get(), serverConfigs.get()) ?? false))
        units.append(r.id)
    if (units.len() > 0)
      return {
        canPurchase = false
        logText = $"ERROR: Units already received: {", ".join(units)}"
        msgboxText = loc("trophy/prizeAlreadyReceived",
          { prizeText = ", ".join(units.map(
              @(unitName) colorize(userlogTextColor, loc(getUnitLocId(unitName))))) })
      }
    return null
  }

  
  let hasUnits = goods.units.filter(@(unitId) campMyUnits.get()?[unitId] != null)
  if (hasUnits.len())
    return {
      canPurchase = false
      logText = $"ERROR: Units already received: {", ".join(hasUnits)}"
      msgboxText = loc("trophy/prizeAlreadyReceived",
        { prizeText = ", ".join(hasUnits.map(
            @(unitId) colorize(userlogTextColor, loc(getUnitLocId(unitId))))) })
    }

  let hasUpgraded = goods.unitUpgrades.filter(@(unitId) campMyUnits.get()?[unitId]?.isUpgraded ?? false)
  if (hasUpgraded.len())
    return {
      canPurchase = false
      logText = $"ERROR: Units already upgraded: {", ".join(hasUpgraded)}"
      msgboxText = loc("trophy/prizeAlreadyReceived",
        { prizeText = ", ".join(hasUpgraded.map(
            @(unitId) colorize(userlogTextColor, loc(getUnitLocId(unitId))))) })
    }

  return null
}

function onGoodsError(err) {
  let errStr = type(err) == "string" ? err : err?.message ?? ""
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

function purchaseGoodsImpl(goodsId, currencyId, price) {
  if (shopPurchaseInProgress.get() != null)
    return "shopPurchaseInProgress"
  buy_goods(goodsId, currencyId, price, 1, "onShopGoodsPurchase")
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
  if ("rewards" in offer) {
    foreach (r in offer.rewards)
      if (r.gType == G_UNIT_UPGRADE || r.gType == G_UNIT)
        units.append(r.id)
  }
  else 
    units.extend(offer.unitUpgrades, offer.units)

  buy_offer(offer.campaign, offer.id, currencyId, price,
    { id = "onOfferPurchase", units })
  return ""
}

let mkCurrencyWithIcon = @(goods) function() {
  local { id = null, count = null } = goods?.rewards.findvalue(@(r) r.gType == G_CURRENCY)
  if ("currencies" in goods) { 
    id = goods.currencies.findindex(@(_) true) ?? ""
    count =  goods.currencies?[id] ?? 0
  }
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

function startRemoveTimer(goods) {
  let { timeRanges = null } = goods
  let time = serverTime.get()
  local timeLeft = null
  if (timeRanges != null) 
    foreach (tr in timeRanges)
      if (tr.end > time)
        timeLeft = min(timeLeft ?? tr.end, tr.end)

  if ((timeLeft ?? 0) <= 0)
    clearTimer(closePurchaseAndBalanceBoxes)
  else
    resetTimeout(timeLeft, closePurchaseAndBalanceBoxes)
}

function purchaseGoods(goodsId, description = "", locParam = null) {
  logShop($"User tries to purchase: {goodsId}")
  if (shopPurchaseInProgress.get() != null)
    return logShop($"ERROR: shopPurchaseInProgress: {shopPurchaseInProgress.get()}")
  let isOffer = activeOffer.get()?.id == goodsId
  let goods = isOffer ? activeOffer.get() : shopGoodsAllCampaigns.get()?[goodsId]
  if (goods == null)
    return logShop($"ERROR: Goods not found: {goodsId}")
  let { price, currencyId } = goods.price
  let isPriceValid = price > 0 && currencyId != ""
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
    let errString = isOffer ? purchaseOfferImpl(goods, currencyFullId, price)
      : purchaseGoodsImpl(goodsId, currencyFullId, price)
    if (errString != "")
      logShop($"ERROR: {errString}")
    if (isOffer)
      tryResetToMainScene()
  }

  let textItem = colorize(userlogTextColor, getGoodsLocName(goods, locParam).replace(" ", nbsp))

  openMsgBoxPurchase({
    text = goods.gtype == SGT_EVT_CURRENCY ? mkCurrencyWithIcon(goods)
      : description != ""
        ? loc("shop/needMoneyQuestion/desc", { item = textItem, description })
      : loc("shop/needMoneyQuestion", { item = textItem }),
    price = { price, currencyId = currencyFullId },
    purchase,
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(goods.gtype), $"pack {goods.id}")
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
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(goodsList[0].gtype), $"pack {",".join(goodsList.map(@(v) v.id))}")
  })
  playSound(currency == GOLD ? "meta_products_for_gold" : "meta_products_for_money" )
}



return {
  purchaseGoods
  purchaseGoodsSeq
}
