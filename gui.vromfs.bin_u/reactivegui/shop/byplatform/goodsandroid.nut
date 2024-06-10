from "%globalsDarg/darg_library.nut" import *

let { is_pc } = require("%sqstd/platform.nut")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setTimeout, resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { doesLocTextExist } = require("dagor.localize")
let { parse_json, object_to_json_string } = require("json")
let { registerGoogleplayPurchase, YU2_WRONG_PAYMENT, YU2_OK } = require("auth_wt")
let logG = log_with_prefix("[GOODS] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { startSeveralCheckPurchases } = require("%rGui/shop/checkPurchases.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { logEvent } = require("appsFlyer")


let getDebugPriceMicros = @(sku) (sku.hash() % 1000) * 1000000 + ((sku.hash() / 7) % 1000000)
let billingModule = require("android.billing.googleplay")
let { GP_OK, GP_NOT_INITED, GP_USER_CANCELED, GP_SERVICE_UNAVAILABLE, GP_ITEM_UNAVAILABLE,
  GP_SERVICE_TIMEOUT, GP_DEVELOPER_ERROR
} = billingModule
let dbgStatuses = [GP_OK, GP_USER_CANCELED, GP_SERVICE_UNAVAILABLE, GP_ITEM_UNAVAILABLE, GP_SERVICE_TIMEOUT]
local dbgStatusIdx = 0
let { //defaults only to allow test this module on PC
  initAndRequestData = function(listStr) {
    let list = parse_json(listStr)
    let result = {
      status = GP_OK
      value = object_to_json_string(
        list.values().map(@(v) {
          productId = v.google_id,
          type = "inapp",
          title = $"{v.google_id} title",
          name = $"{v.google_id} name",
          description = $"{v.google_id} description",
          price = $"{round_by_value(0.000001 * getDebugPriceMicros(v.google_id), 0.01)} ₽".replace(".", ","),
          priceAmountMicros = getDebugPriceMicros(v.google_id)
          priceCurrencyCode = "RUB"
          skuDetailsToken = $"{v.google_id}_token"
          iconUrl = $"https://example.com/{v.google_id}"
        }))
    }
    setTimeout(0.1, @() eventbus_send("android.billing.googleplay.onInitAndDataRequested", result))
  },
  startPurchaseAsync = @(_) setTimeout(1.0,
    @() eventbus_send("android.billing.googleplay.onGooglePurchaseCallback", {
      status = dbgStatuses[dbgStatusIdx++ % dbgStatuses.len()],
      value = "{ \"orderId\" : -1, \"productId\" : \"debug\" }"
    })),
  confirmPurchase = @(_) setTimeout(1.0, @() eventbus_send("android.billing.googleplay.onConfirmPurchaseCallback", { status = 0, value = "{}" })),
  checkPurchases = @() null
} = !is_pc ? billingModule : {}
let register_googleplay_purchase = !is_pc ? registerGoogleplayPurchase
  : @(_, __, eventId) setTimeout(0.1, @() eventbus_send(eventId, { status = 0, item_id = "id", purch_token = "token" })) //for debug on pc


const REPEAT_ON_ERROR_MSEC = 60000
let lastInitStatus = hardPersistWatched("goodsAndroid.lastInitStatus", GP_NOT_INITED)
let skusInfo = hardPersistWatched("goodsAndroid.skusInfo", {})
let purchaseInProgress = mkWatched(persist, "purchaseInProgress", null)
let nextRefreshTime = Watched(-1)
let availableSkusPrices = Computed(function() {
  let res = {}
  foreach (info in skusInfo.value) {
    let { productId = null, price_currency_code = null, price_amount_micros = null, //compatibility with old googleplay format. Was changed near 20.09.2023
      priceCurrencyCode = null, priceAmountMicros = null
    } = info
    let code = price_currency_code ?? priceCurrencyCode
    let amountMicros = price_amount_micros ?? priceAmountMicros
    if (productId == null || amountMicros == null || code == null)
      continue
    let priceFloat = round_by_value(0.000001 * amountMicros, 0.01)
    let currencyId = code.tolower()
    res[productId] <- {
      price = priceFloat
      currencyId
      priceText = getPriceExtStr(priceFloat, currencyId)
    }
  }
  return res
})

let statusNames = {}
foreach(id, val in billingModule)
  if (type(val) == "integer" && id.startswith("GP_"))
    statusNames[val] <- id
let getStatusName = @(status) statusNames?[status] ?? status

lastInitStatus.subscribe(@(v) logG($"init status {getStatusName(v)}"))
skusInfo.subscribe(@(v) logG($"available skus: ", v.keys()))
isAuthorized.subscribe(function(v) {
  if (v)
    return
  lastInitStatus(GP_NOT_INITED)
  skusInfo({})
})

eventbus_subscribe("android.billing.googleplay.onInitAndDataRequested", function(result) {
  let { status, value = null } = result
  lastInitStatus(status)
  if (status != GP_OK)
    return
  let info = parse_json(value)
  if (type(info) != "array") {
    logerr($"Bad format of android.billing.googleplay.onInitAndDataRequested: type of parsed value is {type(info)}")
    return
  }
  skusInfo.mutate(@(allInfo) info.each(function(v) {
    let { productId = null } = v
    if (productId != null)
      allInfo[productId] <- v
  }))
  checkPurchases()
})

let getSku = @(goods) goods?.purchaseGuids.android.extId

let goodsIdBySku = Computed(function() {
  let res = {}
  foreach (id, goods in campConfigs.value?.allGoods ?? {})
    if (can_debug_shop.value || !goods.isShowDebugOnly) {
      let sku = getSku(goods)
      if (sku != null)
        res[sku] <- id
    }
  return res
})

let offerSku = Computed(@() getSku(activeOffers.value))

let skusForRequest = keepref(Computed(function() {
  if (!isAuthorized.value)
    return ""

  let ids = goodsIdBySku.value.filter(@(_, sku) sku not in skusInfo.value)
  if (offerSku.value != null && (offerSku.value not in skusInfo.value))
    ids[offerSku.value] <- activeOffers.value.id
  if (ids.len() == 0)
    return ""
  let list = {}
  foreach (k, v in ids)
    list[v] <- { google_id = k }
  return object_to_json_string(list)
}))
function refreshAvailableSkus() {
  if (skusForRequest.value.len() == 0)
    return
  if (lastInitStatus.value != GP_OK)
    lastInitStatus(GP_NOT_INITED) //remove error status by request
  logG("initAndRequestData: ", skusForRequest.value)
  initAndRequestData(skusForRequest.value)
}

skusForRequest.subscribe(@(_) refreshAvailableSkus())
if (lastInitStatus.value == GP_NOT_INITED)
  refreshAvailableSkus()

let updateNextRefreshTime = @(status)
  nextRefreshTime(status == GP_NOT_INITED || status == GP_OK ? -1 : get_time_msec() + REPEAT_ON_ERROR_MSEC)
updateNextRefreshTime(lastInitStatus.value)
lastInitStatus.subscribe(updateNextRefreshTime)

function startRefreshTimer() {
  if (isInBattle.value || nextRefreshTime.value <= 0)
    clearTimer(refreshAvailableSkus)
  else
    resetTimeout(max(0.1, 0.001 * (nextRefreshTime.value - get_time_msec())), refreshAvailableSkus)
}
startRefreshTimer()
nextRefreshTime.subscribe(@(_) startRefreshTimer())
isInBattle.subscribe(@(_) startRefreshTimer())

let platformGoods = Computed(function() {
  let allGoods = campConfigs.value?.allGoods ?? {}
  let skuToGoodsId = goodsIdBySku.value
  let res = {}
  foreach (sku, priceExt in availableSkusPrices.value) {
    let goodsId = skuToGoodsId?[sku]
    let goods = allGoods?[goodsId]
    if (goods != null)
      res[goodsId] <- goods.__merge({ priceExt }) //warning disable: -potentially-nulled-index
  }
  return res
})

let platformOffer = Computed(function() {
  let priceExt = availableSkusPrices.value?[getSku(activeOffers.value)]
  return priceExt == null || activeOffers.value == null ? null
    : activeOffers.value.__merge({ priceExt })
})

function buyPlatformGoods(goodsOrId) {
  let sku = getSku(platformGoods.value?[goodsOrId] ?? goodsOrId)
  if (sku == null)
    return

  logG($"Buy {sku}")
  startPurchaseAsync(sku)
  purchaseInProgress(sku)
}

let noNeedLogerr = [ GP_SERVICE_TIMEOUT, GP_USER_CANCELED, GP_DEVELOPER_ERROR ]

function sendLogPurchaseData(json_value) {
  //see more here: https://support.appsflyer.com/hc/en-us/articles/4410481112081
  local googleResp = parse_json(json_value)
  let { orderId = null, productId = null } = googleResp
  local af = {
    af_order_id = orderId
    af_content_id = productId
    af_revenue = availableSkusPrices.value?[productId].price ?? -1
    af_price = availableSkusPrices.value?[productId].price ?? -1
    af_currency = availableSkusPrices.value?[productId].currencyId ?? "USD" //or af_purchase_currency?
  }
  logEvent("af_purchase", object_to_json_string(af, true))
}

eventbus_subscribe("android.billing.googleplay.onGooglePurchaseCallback", function(result) {
  let { status, value = "" } = result
  let statusName = getStatusName(status)
  logG("onGooglePurchaseCallback status = ", statusName)
  if (status == GP_OK) {
    register_googleplay_purchase(value, false, "auth.onRegisterGooglePurchase")
    sendLogPurchaseData(value)
    return
  }
  purchaseInProgress(null)
  if (!noNeedLogerr.contains(status))
    logerr($"onGooglePurchaseCallback fail: status = {statusName}")
  let msgLocId = $"error/googleplay/{statusName}"
  if (doesLocTextExist(msgLocId))
    openFMsgBox({ text = loc(msgLocId) })
})

eventbus_subscribe("android.billing.googleplay.onConfirmPurchaseCallback", function(result) {
  let { status } = result
  purchaseInProgress(null)
  if (status == GP_OK) {
    logG("onConfirmPurchaseCallback success")
    startSeveralCheckPurchases()
  } else {
    logG($"onConfirmPurchaseCallback fail: status = {getStatusName(status)}")
    openFMsgBox({ text = loc("msg/errorAuthGoodsCheck") })
  }
})

eventbus_subscribe("auth.onRegisterGooglePurchase", function(result) {
  let {status, item_id = null, purch_token = null } = result

  if (status == YU2_OK && item_id && purch_token) {
    logG($"register_googleplay_purchase success")
    local purchase = {
      productId = item_id
      purchaseToken = purch_token
    }
    local purch = object_to_json_string(purchase, true)
    confirmPurchase(purch)
    return
  }
  purchaseInProgress(null)
  if (status == YU2_WRONG_PAYMENT) {
    logG($"register_googleplay_purchase delayed payment")
    openFMsgBox({ text = loc("msg/errorPaymentDelayed") })
  } else {
    logG($"register_googleplay_purchase error={status}")
    openFMsgBox({ text = loc("msg/errorWhileRegisteringPurchase") })
  }
})


let platformPurchaseInProgress = Computed(@() offerSku.get() == null ? null
  : offerSku.get() == purchaseInProgress.get() ? activeOffers.get()?.id
  : goodsIdBySku.get()?[purchaseInProgress.get()])

return {
  platformGoodsDebugInfo = skusInfo
  platformGoods
  platformOffer
  buyPlatformGoods
  platformPurchaseInProgress
}