from "%globalsDarg/darg_library.nut" import *
let logG = log_with_prefix("[GOODS] ")
let { send } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { doesLocTextExist } = require("dagor.localize")
let { isEqual } = require("%sqstd/underscore.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { severalCheckPurchasesOnActivate } = require("%rGui/shop/checkPurchases.nut")
let { requestData, createGuidsRequestParams } = require("%rGui/shop/httpRequest.nut")


const REPEAT_ON_ERROR_SEC = 60
const NO_ANSWER_TIMEOUT_SEC = 60
const AUTO_UPDATE_TIME_SEC = 3600

let successPaymentUrl = "https://store.gaijin.net/success_payment.php" //webview should close on success payment url

let isGoodsRequested = mkHardWatched("goodsGaijin.isGoodsRequested", false)
let goodsInfo = mkHardWatched("goodsGaijin.goodsInfo", {})
let lastError = mkHardWatched("goodsGaijin.lastError", null)
let lastUpdateTime = mkHardWatched("goodsGaijin.lastUpdateTime", 0)
let needForceUpdate = Watched(false)
let needRetry = Computed(@() lastError.value != null && !isInBattle.value && !isGoodsRequested.value)

let resetRequestedFlag = @() isGoodsRequested(false)
isGoodsRequested.subscribe(@(_) resetTimeout(NO_ANSWER_TIMEOUT_SEC, resetRequestedFlag))
if (isGoodsRequested.value)
  resetTimeout(NO_ANSWER_TIMEOUT_SEC, resetRequestedFlag)

let goodsIdByGuid = Computed(function() {
  let res = {}
  foreach (id, goods in campConfigs.value?.allGoods ?? {})
    if (can_debug_shop.value || !goods.isShowDebugOnly) {
      let { purchaseGuid = "" } = goods
      if (purchaseGuid != "")
        res[purchaseGuid] <- id
    }
  return res
})

let guidsForRequest = keepref(Computed(function(prev) {
  if (!isAuthorized.value)
    return []
  let res = goodsIdByGuid.value.filter(@(_, guid) needForceUpdate.value || (guid not in goodsInfo.value))
    .keys()
  let offerGuid = activeOffers.value?.purchaseGuid ?? ""
  if (offerGuid != "" && (offerGuid not in goodsInfo.value))
    res.append(offerGuid)
  return isEqual(prev, res) ? prev : res
}))

let function refreshAvailableGuids() {
  if (guidsForRequest.value.len() == 0)
    return
  logG("requestData: ", guidsForRequest.value)
  isGoodsRequested(true)
  requestData(
    "https://api.gaijinent.com/item_info.php",
    createGuidsRequestParams(guidsForRequest.value),
    function(data) {
      isGoodsRequested(false)
      lastError(null)
      lastUpdateTime(serverTime.value)
      let list = data?.items
      if (type(list) == "table" && list.len() > 0)
        goodsInfo.mutate(@(v) v.__update(list))
    },
    function(errData) {
      isGoodsRequested(false)
      lastError(errData)
    }
  )
}

guidsForRequest.subscribe(@(_) refreshAvailableGuids())
needRetry.subscribe(@(v) v ? resetTimeout(REPEAT_ON_ERROR_SEC, refreshAvailableGuids)
  : clearTimer(refreshAvailableGuids))
if (needRetry.value)
  resetTimeout(REPEAT_ON_ERROR_SEC, refreshAvailableGuids)
else if (goodsInfo.value.len() == 0)
  refreshAvailableGuids()

let forceUpdateAllGuids = @() needForceUpdate(true)
let function startAutoUpdateTimer() {
  needForceUpdate(false)
  if (isInBattle.value || lastUpdateTime.value <= 0)
    clearTimer(forceUpdateAllGuids)
  else
    resetTimeout(max(0.1, lastUpdateTime.value + AUTO_UPDATE_TIME_SEC - serverTime.value), forceUpdateAllGuids)
}
startAutoUpdateTimer()
lastUpdateTime.subscribe(@(_) startAutoUpdateTimer())
isInBattle.subscribe(@(_) startAutoUpdateTimer())

let function buildPurchaseUrl(info) {
  let { url = "" } = info
  let parts = url.split("?")
  let path = parts[0]
  local query = parts?[1] ?? ""
  query = "&".join([ "closePayPopupButton=main__hidden", query ], true)
  query = "&".join([ "popupId=buy-popup", query ], true)
  return "?".join([ path, query ], true)
}

let function mkGoods(baseGoods, info) {
  if (baseGoods == null || info == null)
    return null
  let { shop_price = 0, shop_price_curr = "" } = info
  if (shop_price <= 0)
    return null
  let locId = $"priceText/{shop_price_curr.tolower()}"
  return baseGoods.__merge({
    purchaseUrl = buildPurchaseUrl(info)
    priceExt = {
      price = shop_price
      currencyId = shop_price_curr
      priceText = doesLocTextExist(locId) ? loc(locId, { price = shop_price }) : $"{shop_price}{shop_price_curr}"
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

let platformOffer = Computed(@()
  mkGoods(activeOffers.value, goodsInfo.value?[activeOffers.value?.purchaseGuid]))

let function buyPlatformGoods(goodsOrId) {
  local baseUrl = goodsOrId?.purchaseUrl ?? platformGoods.value?[goodsOrId].purchaseUrl
  if (baseUrl == null)
    return
  baseUrl = " ".concat("auto_local", "auto_login", baseUrl)
  send("openUrl", { baseUrl, onCloseUrl = successPaymentUrl })
  severalCheckPurchasesOnActivate()
}

return {
  platformGoodsDebugInfo = goodsInfo
  platformGoods
  platformOffer
  buyPlatformGoods
}