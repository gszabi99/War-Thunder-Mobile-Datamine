from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { DBGLEVEL } = require("dagor.system")
let { resetTimeout } = require("dagor.workcycle")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { severalCheckPurchasesOnActivate } = require("%rGui/shop/checkPurchases.nut")
let { addGoodsInfoGuids, addGoodsInfoGuid, goodsInfo } = require("gaijinGoodsInfo.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let { showRestorePurchasesDoneMsg } = require("platformGoodsCommon.nut")


let successPaymentUrl = "https://store.gaijin.net/success_payment.php" 

let getGaijinGuid = @(goods) goods?.purchaseGuids.gaijin.guid ?? ""
let getGaijinDiscount = @(goods) goods?.purchaseGuids.gaijin.discountInPercent ?? 0
let platformPurchaseInProgress = Watched(null) 

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
  let { shop_price = 0, shop_price_curr = "", duration = 0, item_id = null } = info
  if (!["integer", "float"].contains(type(shop_price))) {
    logerr($"Gaijin shop item {item_id} has bad shop_price = ({type(shop_price)}) {shop_price}")
    return null
  }
  if (shop_price <= 0)
    return null
  let currencyId = shop_price_curr.tolower()
  let platformDiscount = getGaijinDiscount(baseGoods)
  return baseGoods.__merge({
    discountInPercent = platformDiscount != 0 ? platformDiscount : (baseGoods?.discountInPercent ?? 0)
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
  foreach (guid, data in goodsInfo.get()) { 
    let goodsId = guidToGoodsId?[guid]
    let goods = mkGoods(allGoods?[goodsId], data)
    if (goods != null)
      res[goodsId] <- goods 
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
  mkGoods(activeOffers.value, goodsInfo.get()?[getGaijinGuid(activeOffers.value)]))

function buyPlatformGoods(goodsOrId) {
  local baseUrl = goodsOrId?.purchaseUrl ?? platformGoods.value?[goodsOrId].purchaseUrl
  if (baseUrl == null)
    return
  baseUrl = " ".concat("auto_local", "auto_login", baseUrl)
  eventbus_send("openUrl", { baseUrl, onCloseUrl = successPaymentUrl })
  severalCheckPurchasesOnActivate()
}

function buyPlatformGoodsFromOtherPlatform(otherPlatformGoodsId) {
  let goods = campConfigs.get()?.allGoods[otherPlatformGoodsId]
  if (!goods)
    return
  let guid = goods.purchaseGuids?.gaijin.guid ?? campConfigs.get()?.allGoods[goods.relatedGaijinId].purchaseGuids.gaijin.guid
  let url = goodsInfo.get()?[guid].url
  if (url == null)
    return
  let baseUrl = " ".concat("auto_local", "auto_login", url)
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

let restorePurchases = DBGLEVEL <= 0 ? null
  : function() {
      if (platformPurchaseInProgress.get() != null)
        return
      platformPurchaseInProgress.set("")
      resetTimeout(1.0, function() {
        platformPurchaseInProgress.set(null)
        showRestorePurchasesDoneMsg()
      })
    }

return {
  platformGoodsDebugInfo = goodsInfo
  platformGoods
  platformGoodsFromRussia = platformGoods
  platformOffer
  platformSubs
  platformPurchaseInProgress
  buyPlatformGoods
  buyPlatformGoodsFromOtherPlatform
  activatePlatfromSubscription
  restorePurchases
}