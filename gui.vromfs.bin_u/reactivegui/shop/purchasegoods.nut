from "%globalsDarg/darg_library.nut" import *
let logShop = log_with_prefix("[SHOP] ")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { shopPurchaseInProgress, buy_goods, buy_offer, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { activeOffer } = require("offerState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { playSound } = require("sound_wt")
let { GOLD } = require("%appGlobals/currenciesState.nut")

function getCantPurchaseReason(goods) {
  let hasUnits = goods.units.filter(@(unitId) myUnits.value?[unitId] != null)
  if (hasUnits.len())
    return {
      canPurchase = false
      logText = $"ERROR: Units already received: {", ".join(hasUnits)}"
      msgboxText = loc("trophy/prizeAlreadyReceived",
        { prizeText = ", ".join(hasUnits.map(
            @(unitId) colorize(userlogTextColor, loc(getUnitLocId(unitId))))) })
    }

  let hasUpgraded = goods.unitUpgrades.filter(@(unitId) myUnits.value?[unitId]?.isUpgraded ?? false)
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
  buy_goods(goodsId, currencyId, price, "onShopGoodsPurchase")
  return ""
}

function purchaseOfferImpl(offer, currencyId, price) {
  if (shopPurchaseInProgress.get() != null)
    return "shopPurchaseInProgress"
  buy_offer(offer.campaign, offer.id, currencyId, price, "onShopGoodsPurchase")
  return ""
}

function purchaseGoods(goodsId) {
  logShop($"User tries to purchase: {goodsId}")
  if (shopPurchaseInProgress.value != null)
    return logShop($"ERROR: shopPurchaseInProgress: {shopPurchaseInProgress.value}")
  let isOffer = activeOffer.get()?.id == goodsId
  let goods = isOffer ? activeOffer.get() : shopGoods.get()?[goodsId]
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

  function purchaseFunc() {
    let errString = isOffer ? purchaseOfferImpl(goods, currencyId, price)
      : purchaseGoodsImpl(goodsId, currencyId, price)
    if (errString != "")
      logShop($"ERROR: {errString}")
  }

  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, getGoodsLocName(goods).replace(" ", nbsp)) }),
    { price = price, currencyId },
    purchaseFunc,
    mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(goods.gtype), $"pack {goods.id}"))
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money" )
}

return purchaseGoods
