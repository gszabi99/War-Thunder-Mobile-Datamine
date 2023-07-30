from "%globalsDarg/darg_library.nut" import *
let logShop = log_with_prefix("[SHOP] ")
let { round } = require("math")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { shopPurchaseInProgress, buy_goods } = require("%appGlobals/pServer/pServerApi.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")

let function getCantPurchaseReason(goods) {
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

let function onShopItemPurchaseResult(res) {
  if (res?.error != null)
    openMsgBox({ text = loc("msgbox/internal_error_header") })
}

let function purchaseShopItemImpl(goodsId, currencyId, price, cb) {
  if (shopPurchaseInProgress.value != null)
    return "shopPurchaseInProgress"
  buy_goods(goodsId, currencyId, price, cb)
  return ""
}

let function purchaseShopItem(goodsId) {
  logShop($"User tries to purchase: {goodsId}")
  if (shopPurchaseInProgress.value != null)
    return logShop($"ERROR: shopPurchaseInProgress: {shopPurchaseInProgress.value}")
  let goods = shopGoods.value?[goodsId]
  if (goods == null)
    return logShop($"ERROR: Goods not found: {goodsId}")
  let { price, currencyId } = goods.price
  let isPriceValid = price > 0 && currencyId != ""
  if (!isPriceValid && goods.purchaseGuid != "")
    openMsgBox({ text = loc("notAvailable/currentVersion") })
  if (!isPriceValid)
    return logShop("ERROR: Invalid price")

  let { logText = null, msgboxText = null, canPurchase = true } = getCantPurchaseReason(goods)
  if (logText != null)
    logShop(logText)
  if (msgboxText != null)
     openMsgBox({ text = msgboxText })
  if (!canPurchase)
    return

  let { discountInPercent = 0 } = goods
  let finalPrice = discountInPercent <= 0 ? price : round(price * (1.0 - (discountInPercent / 100.0)))
  let function purchaseFunc() {
    let errString = purchaseShopItemImpl(goodsId, currencyId, finalPrice, onShopItemPurchaseResult)
    if (errString != "")
      logShop($"ERROR: {errString}")
  }

  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion", { item = colorize(userlogTextColor, getGoodsLocName(goods).replace(" ", nbsp)) }),
    { price = finalPrice, currencyId },
    purchaseFunc)
}

return purchaseShopItem
