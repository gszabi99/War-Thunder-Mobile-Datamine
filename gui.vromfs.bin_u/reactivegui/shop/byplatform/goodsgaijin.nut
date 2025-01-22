from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { severalCheckPurchasesOnActivate } = require("%rGui/shop/checkPurchases.nut")
let { addGoodsInfoGuids, addGoodsInfoGuid, goodsInfo } = require("gaijinGoodsInfo.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")


let successPaymentUrl = "https://store.gaijin.net/success_payment.php" //webview should close on success payment url

let getGaijinGuid = @(goods) goods?.purchaseGuids.gaijin.guid ?? ""

let goodsIdByGuid = Computed(function() {
  let res = {}
  let { allGoods = {}, subscriptionsCfg = {} } = campConfigs.get()
  foreach (id, goods in allGoods)
    if ((can_debug_shop.value || !goods.isShowDebugOnly)
        && !goods?.isHiddenInGaijinStore) {
      let guid = getGaijinGuid(goods)
      if (guid != "")
        res[guid] <- id
    }
  foreach (id, subs in subscriptionsCfg) {
    let guid = getGaijinGuid(subs)
    if (guid != "")
      res[guid] <- id
  }
  return res
})

let addGoodsInfoTbl = @(tbl) addGoodsInfoGuids(tbl.keys())
addGoodsInfoTbl(goodsIdByGuid.value)
goodsIdByGuid.subscribe(addGoodsInfoTbl)

function addOfferGuid(offer) {
  let offerGuid = getGaijinGuid(offer)
  if (offerGuid != "")
    addGoodsInfoGuid(offerGuid)
}
addOfferGuid(activeOffers.value)
activeOffers.subscribe(addOfferGuid)

function buildPurchaseUrl(info) {
  let { url = "" } = info
  let parts = url.split("?")
  let path = parts[0]
  local query = parts?[1] ?? ""
  query = "&".join([ "closePayPopupButton=main__hidden", query ], true)
  query = "&".join([ "popupId=buy-popup", query ], true)
  return "?".join([ path, query ], true)
}

function mkGoods(baseGoods, info) {
  if (baseGoods == null || info == null)
    return null
  let { shop_price = 0, shop_price_curr = "", duration = 0 } = info
  if (shop_price <= 0)
    return null
  let currencyId = shop_price_curr.tolower()
  return baseGoods.__merge({
    duration = duration.tointeger()
    purchaseUrl = buildPurchaseUrl(info)
    priceExt = {
      price = shop_price
      currencyId
      priceText = getPriceExtStr(shop_price, currencyId)
    }
  })
}

let platformGoods = Computed(function() {
  let { allGoods = {} } = campConfigs.value
  let guidToGoodsId = goodsIdByGuid.value
  let res = {}
  foreach (guid, data in goodsInfo.value) { //todo: need to divide price and currency here to 2 fields
    let goodsId = guidToGoodsId?[guid]
    let goods = mkGoods(allGoods?[goodsId], data)
    if (goods != null)
      res[goodsId] <- goods //warning disable: -potentially-nulled-index
  }
  return res
})

let platformSubs = Computed(function() {
  let res = {}
  foreach (id, subs in campConfigs.get()?.subscriptionsCfg ?? {}) {
    let subsExt = mkGoods(subs, goodsInfo.get()?[getGaijinGuid(subs)])
    if (subsExt != null)
      res[id] <- subsExt
  }
  return res
})

let platformOffer = Computed(@()
  mkGoods(activeOffers.value, goodsInfo.value?[getGaijinGuid(activeOffers.value)]))

function buyPlatformGoods(goodsOrId) {
  local baseUrl = goodsOrId?.purchaseUrl ?? platformGoods.value?[goodsOrId].purchaseUrl
  if (baseUrl == null)
    return
  baseUrl = " ".concat("auto_local", "auto_login", baseUrl)
  eventbus_send("openUrl", { baseUrl, onCloseUrl = successPaymentUrl })
  severalCheckPurchasesOnActivate()
}

function activatePlatfromSubscription(subsOrId) {
  local baseUrl = subsOrId?.purchaseUrl ?? platformSubs.get()?[subsOrId].purchaseUrl
  if (baseUrl == null)
    return
  baseUrl = " ".concat("auto_local", "auto_login", baseUrl)
  eventbus_send("openUrl", { baseUrl, onCloseUrl = successPaymentUrl })
  severalCheckPurchasesOnActivate()
}

return {
  platformGoodsDebugInfo = goodsInfo
  platformGoods
  platformGoodsFromRussia = platformGoods
  platformOffer
  platformSubs
  buyPlatformGoods
  activatePlatfromSubscription
}