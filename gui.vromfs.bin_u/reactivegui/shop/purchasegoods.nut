from "%globalsDarg/darg_library.nut" import *
let logShop = log_with_prefix("[SHOP] ")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { shopPurchaseInProgress, buy_goods, buy_offer, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { shopGoodsAllCampaigns } = require("%rGui/shop/shopState.nut")
let { tryResetToMainScene } = require("%rGui/navState.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { activeOffer } = require("offerState.nut")
let { openMsgBoxPurchase, closePurchaseAndBalanceBoxes } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { msgBoxText, openMsgBox } = require("%rGui/components/msgBox.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { playSound } = require("sound_wt")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { SGT_EVT_CURRENCY } = require("%rGui/shop/shopConst.nut")

function getCantPurchaseReason(goods) {
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

registerHandler("onShopGoodsPurchase",
  function(res) {
    if (res?.error != null)
      openMsgBox({ text = loc("msgbox/internal_error_header") })
  })

function purchaseGoodsImpl(goodsId, currencyId, price) {
  if (shopPurchaseInProgress.value != null)
    return "shopPurchaseInProgress"
  buy_goods(goodsId, currencyId, price, 1, "onShopGoodsPurchase")
  return ""
}

registerHandler("onShopGoodsPurchaseSequence",
  function(result, context) {
    if (result?.error != null) {
      openMsgBox({ text = loc("msgbox/internal_error_header") })
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

function purchaseOfferImpl(offer, currencyId, price) {
  if (shopPurchaseInProgress.get() != null)
    return "shopPurchaseInProgress"
  buy_offer(offer.campaign, offer.id, currencyId, price, "onShopGoodsPurchase")
  return ""
}

let mkCurrencyWithIcon = @(id, count) {
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(30)
  children = [
    msgBoxText(loc("shop/orderQuestion"), { size = SIZE_TO_CONTENT })
    mkCurrencyComp(count, id, CS_INCREASED_ICON)
    msgBoxText(loc("shop/cost"), { size = SIZE_TO_CONTENT })
  ]
}

function startRemoveTimer(goods) {
  let { end = 0 } = goods?.timeRange
  let timeLeft = end - serverTime.get()
  if (timeLeft <= 0)
    clearTimer(closePurchaseAndBalanceBoxes)
  else
    resetTimeout(timeLeft, closePurchaseAndBalanceBoxes)
}

function purchaseGoods(goodsId, description = "") {
  logShop($"User tries to purchase: {goodsId}")
  if (shopPurchaseInProgress.value != null)
    return logShop($"ERROR: shopPurchaseInProgress: {shopPurchaseInProgress.value}")
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

  let textItem = colorize(userlogTextColor, getGoodsLocName(goods).replace(" ", nbsp))

  let goodsCurId = goods.currencies.findindex(@(_) true) ?? ""
  let goodsCurrencyFullId = currencyToFullId.get()?[goodsCurId] ?? goodsCurId
  let goodsCount = goods.currencies?[goodsCurId] ?? 0

  openMsgBoxPurchase({
    text = goods.gtype == SGT_EVT_CURRENCY
        ? mkCurrencyWithIcon(goodsCurrencyFullId, goodsCount)
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
  if (shopPurchaseInProgress.value != null || goodsList.len() == 0)
    return logShop($"ERROR: shopPurchaseInProgress: {shopPurchaseInProgress.value}")
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
