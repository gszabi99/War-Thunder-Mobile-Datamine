from "%globalsDarg/darg_library.nut" import *
let logG = log_with_prefix("[GOODS] ")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setTimeout, resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { doesLocTextExist } = require("dagor.localize")
let { parse_json, object_to_json_string } = require("json")
let { registerHuaweiPurchase, YU2_WRONG_PAYMENT, YU2_OK } = require("auth_wt")
let { is_pc } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { parse_duration } = require("%sqstd/iso8601.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { startSeveralCheckPurchases } = require("%rGui/shop/checkPurchases.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { logEvent } = require("appsFlyer")

let isDebugMode = is_pc
let getDebugPriceMicros = @(sku) (sku.hash() % 1000) * 1000000 + ((sku.hash() / 7) % 1000000)
let billingModule = require("android.billing.huawei")
let { HMS_ORDER_STATE_SUCCESS, HMS_ORDER_STATE_FAILED, HMS_ORDER_STATE_DEFAULT_CODE, HMS_ORDER_STATE_CANCEL,
  HMS_ORDER_STATE_CALLS_FREQUENT, HMS_ORDER_STATE_NET_ERROR
  } = billingModule
let dbgStatuses = [HMS_ORDER_STATE_SUCCESS, HMS_ORDER_STATE_CANCEL, HMS_ORDER_STATE_FAILED, HMS_ORDER_STATE_NET_ERROR]
local dbgStatusIdx = 0
let { //defaults only to allow test this module on PC
  initAndRequestData = function(listStr) {
    let list = parse_json(listStr)
    let result = {
      status = HMS_ORDER_STATE_SUCCESS
      value = object_to_json_string(
        list.values().map(@(v) {
          productId = v.huawei_id,
          type = "inapp",
          title = $"{v.huawei_id} title",
          name = $"{v.huawei_id} name",
          description = $"{v.huawei_id} description",
          price = $"{round_by_value(0.000001 * getDebugPriceMicros(v.huawei_id), 0.01)} ₽".replace(".", ","),
          priceAmountMicros = getDebugPriceMicros(v.huawei_id)
          priceCurrencyCode = "RUB"
          skuDetailsToken = $"{v.huawei_id}_token"
          iconUrl = $"https://example.com/{v.huawei_id}"
          billingPeriod = v?.sku_type == "subs" ? "P1M" : ""
          subscriptionOfferDetails = v?.sku_type != "subs" ? null
            : { subPeriod = "P30D" }
        }))
    }
    setTimeout(0.1, @() eventbus_send("android.billing.huawei.onInitAndDataRequested", result))
  },
  startPurchaseAsync = @(_) setTimeout(1.0,
    @() eventbus_send("android.billing.huawei.onHuaweiPurchaseCallback", {
      status = dbgStatuses[dbgStatusIdx++ % dbgStatuses.len()],
      value = "{ \"orderId\" : -1, \"productId\" : \"debug\" }"
    })),
  confirmPurchase = @(_) setTimeout(1.0, @() eventbus_send("android.billing.huawei.onConfirmPurchaseCallback", { status = 0, value = "{}" })),
} = !isDebugMode ? billingModule : {}
let register_huawei_purchase = !is_pc ? registerHuaweiPurchase
  : @(_, __, eventId) setTimeout(0.1, @() eventbus_send(eventId, { status = 0, item_id = "id", purch_token = "token" })) //for debug on pc


const REPEAT_ON_ERROR_MSEC = 60000
let lastInitStatus = hardPersistWatched("goodsHuawei.lastInitStatus", HMS_ORDER_STATE_DEFAULT_CODE)
let skusInfo = hardPersistWatched("goodsHuawei.skusInfo", {})
let purchaseInProgress = mkWatched(persist, "purchaseInProgress", null)
let nextRefreshTime = Watched(-1)

let availableSkusPrices = Computed(function() {
  let res = {}
  foreach (info in skusInfo.value) {
    let { productId = null, priceCurrencyCode = null, priceAmountMicros = null, subscriptionOfferDetails = null } = info
    let { subPeriod = "" } = subscriptionOfferDetails
    if (productId == null || priceAmountMicros == null || priceCurrencyCode == null)
      continue
    let priceFloat = round_by_value(0.000001 * priceAmountMicros, 0.01)
    let currencyId = priceCurrencyCode.tolower()
    res[productId] <- {
      price = priceFloat
      currencyId
      priceText = getPriceExtStr(priceFloat, currencyId)
      billingPeriod = parse_duration(subPeriod)
    }
  }
  return res
})

let statusNames = {}
foreach(id, val in billingModule)
  if (type(val) == "integer" && id.startswith("HMS_"))
    statusNames[val] <- id
let getStatusName = @(status) statusNames?[status] ?? status

lastInitStatus.subscribe(@(v) logG($"init status {getStatusName(v)}"))
skusInfo.subscribe(@(v) logG($"available skus: ", v.keys()))
isAuthorized.subscribe(function(v) {
  if (v)
    return
  lastInitStatus(HMS_ORDER_STATE_DEFAULT_CODE)
  skusInfo({})
})

eventbus_subscribe("android.billing.huawei.onInitAndDataRequested", function(result) {
  let { status, value = null } = result
  lastInitStatus(status)
  if (status != HMS_ORDER_STATE_SUCCESS)
    return
  let info = parse_json(value)
  if (type(info) != "array") {
    logerr($"Bad format of android.billing.huawei.onInitAndDataRequested: type of parsed value is {type(info)}")
    return
  }
  skusInfo.mutate(@(allInfo) info.each(function(v) {
    let { productId = null } = v
    if (productId != null)
      allInfo[productId] <- v
  }))
})

let getSku = @(goods) goods?.purchaseGuids.huawei.extId
let getHuaweiDiscount = @(goods) goods?.purchaseGuids.huawei.discountInPercent ?? 0
let getPlanId = @(goods) goods?.purchaseGuids.android.planId

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

let subsIdByPlanId = Computed(function() {
  let res = {}
  foreach (id, subs in campConfigs.value?.subscriptionsCfg ?? {}) {
    let planId = getPlanId(subs)
    if (planId != null)
      res[planId] <- id
  }
  return res
})

let offerSku = Computed(@() getSku(activeOffers.value))

let skusForRequest = keepref(Computed(function() {
  if (!isAuthorized.value)
    return ""

  let received = skusInfo.get()
  let ids = goodsIdBySku.get().filter(@(_, sku) sku not in received)
  if (offerSku.get() != null && (offerSku.value not in received))
    ids[offerSku.value] <- activeOffers.get().id
  let subsIds = subsIdByPlanId.get().filter(@(_, sku) sku not in received)
  if (ids.len() == 0 && subsIds.len() == 0)
    return ""
  let list = {}
  foreach (k, _ in ids)
    list[k] <- { huawei_id = k }
  foreach (k, _ in subsIds)
    list[k] <- { huawei_id = k, sku_type = "subs" }
  return object_to_json_string(list)
}))

function refreshAvailableSkus() {
  if (skusForRequest.value.len() == 0)
    return
  if (lastInitStatus.value != HMS_ORDER_STATE_SUCCESS)
    lastInitStatus(HMS_ORDER_STATE_DEFAULT_CODE) //remove error status by request
  logG("initAndRequestData: ", skusForRequest.value)
  initAndRequestData(skusForRequest.value)
}

skusForRequest.subscribe(@(_) refreshAvailableSkus())
if (lastInitStatus.value == HMS_ORDER_STATE_DEFAULT_CODE)
  refreshAvailableSkus()

let updateNextRefreshTime = @(status)
  nextRefreshTime(status == HMS_ORDER_STATE_DEFAULT_CODE || status == HMS_ORDER_STATE_SUCCESS ? -1 : get_time_msec() + REPEAT_ON_ERROR_MSEC)
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
    if (goods == null)
      continue
    let platformDiscount = getHuaweiDiscount(goods)
    let discountInPercent = platformDiscount != 0 ? platformDiscount : (goods?.discountInPercent ?? 0)
    res[goodsId] <- goods.__merge({ priceExt, discountInPercent }) //warning disable: -potentially-nulled-index
  }
  return res
})

let platformSubs = Computed(function() {
  let { subscriptionsCfg = {} } = campConfigs.get()
  let prices = availableSkusPrices.get()
  let res = {}
  foreach (planId, subsId in subsIdByPlanId.get()) {
    let priceExt = prices?[planId]
    let subs = subscriptionsCfg?[subsId]
    if (priceExt != null && subs != null)
      res[subsId] <- subs.__merge({ priceExt, billingPeriod = priceExt.billingPeriod })
  }
  return res
})

let platformOffer = Computed(function() {
  let offer = activeOffers.get()
  let priceExt = availableSkusPrices.value?[getSku(offer)]
  if (priceExt == null || offer == null)
    return null
  let platformDiscount = getHuaweiDiscount(offer)
  return offer.__merge({
    priceExt
    discountInPercent = platformDiscount != 0 ? platformDiscount : (offer?.discountInPercent ?? 0)
  })
})

function buyPlatformGoods(goodsOrId) {
  let productId = getPlanId(platformSubs.get()?[goodsOrId] ?? goodsOrId)
    ?? getSku(platformGoods.value?[goodsOrId] ?? goodsOrId)
  if (productId == null)
    return
  logG($"Buy {productId}")
  startPurchaseAsync(productId)
  purchaseInProgress.set(productId)
}

let noNeedLogerr = [ HMS_ORDER_STATE_CANCEL, HMS_ORDER_STATE_NET_ERROR, HMS_ORDER_STATE_CALLS_FREQUENT, HMS_ORDER_STATE_DEFAULT_CODE ]

function sendLogPurchaseData(json_value) {
  //see more here: https://support.appsflyer.com/hc/en-us/articles/4410481112081
  local resp = parse_json(json_value)
  let { orderId = null, productId = null } = resp
  local af = {
    af_order_id = orderId
    af_content_id = productId
    af_revenue = availableSkusPrices.value?[productId].price ?? -1
    af_price = availableSkusPrices.value?[productId].price ?? -1
    af_currency = availableSkusPrices.value?[productId].currencyId ?? "USD" //or af_purchase_currency?
  }
  logEvent("af_purchase", object_to_json_string(af, true))
}

eventbus_subscribe("android.billing.huawei.onHuaweiPurchaseCallback", function(result) {
  let { status, value = "" } = result
  let statusName = getStatusName(status)
  if (status == HMS_ORDER_STATE_SUCCESS) {
    register_huawei_purchase(value, false, "auth.onRegisterHuaweiPurchase")
    sendLogPurchaseData(value)
    return
  }
  purchaseInProgress.set(null)
  if (!noNeedLogerr.contains(status))
    logerr($"onHuaweiPurchaseCallback fail: status = {statusName}")
  let msgLocId = $"error/appgallery/{statusName}"
  if (doesLocTextExist(msgLocId))
    openFMsgBox({ text = loc(msgLocId) })
})

eventbus_subscribe("android.billing.huawei.onConfirmPurchaseCallback", function(result) {
  let { status } = result
  purchaseInProgress.set(null)
  if (status == HMS_ORDER_STATE_SUCCESS) {
    logG("onConfirmPurchaseCallback success")
    startSeveralCheckPurchases()
  } else {
    logG($"onConfirmPurchaseCallback fail: status = {getStatusName(status)}")
    openFMsgBox({ text = loc("msg/errorAuthGoodsCheck") })
  }
})

eventbus_subscribe("auth.onRegisterHuaweiPurchase", function(result) {
  let {status, item_id = null, purch_token = null } = result
  if (status == YU2_OK && item_id && purch_token) {
    logG($"register_huawei_purchase success")
    local purchase = {
      productId = item_id
      purchaseToken = purch_token
    }
    local purch = object_to_json_string(purchase, true)
    confirmPurchase(purch)
    return
  }
  purchaseInProgress.set(null)
  if (status == YU2_WRONG_PAYMENT) {
    logG($"register_huawei_purchase delayed payment")
    openFMsgBox({ text = loc("msg/errorPaymentDelayed") })
  } else {
    logG($"register_huawei_purchase error={status}")
    openFMsgBox({ text = loc("msg/errorWhileRegisteringPurchase") })
  }
})


let platformPurchaseInProgress = Computed(@() purchaseInProgress.get() == null ? null
  : offerSku.get() == purchaseInProgress.get() ? activeOffers.get()?.id
  : (goodsIdBySku.get()?[purchaseInProgress.get()] ?? subsIdByPlanId.get()?[purchaseInProgress.get()]))

return {
  platformGoodsDebugInfo = skusInfo
  platformGoods
  platformOffer
  platformSubs
  buyPlatformGoods
  activatePlatfromSubscription = buyPlatformGoods
  platformPurchaseInProgress
}