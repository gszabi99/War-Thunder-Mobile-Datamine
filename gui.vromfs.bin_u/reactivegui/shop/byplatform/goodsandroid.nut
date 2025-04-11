from "%globalsDarg/darg_library.nut" import *
let logG = log_with_prefix("[GOODS] ")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setTimeout, resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { doesLocTextExist } = require("dagor.localize")
let { parse_json, object_to_json_string } = require("json")
let { registerGoogleplayPurchase, YU2_WRONG_PAYMENT, YU2_OK } = require("auth_wt")
let { is_pc } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { parse_duration } = require("%sqstd/iso8601.nut")
let { getYu2CodeName, yu2BadConnectionCodes } = require("%appGlobals/yu2ErrCodes.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized, isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { startSeveralCheckPurchases } = require("%rGui/shop/checkPurchases.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { logEvent } = require("appsFlyer")
let { showRestorePurchasesDoneMsg } = require("platformGoodsCommon.nut")

let isDebugMode = is_pc
let getDebugPriceMicros = @(sku) (sku.hash() % 1000) * 1000000 + ((sku.hash() / 7) % 1000000)
let billingModule = require("android.billing.googleplay")
let { GP_OK, GP_NOT_INITED, GP_USER_CANCELED, GP_SERVICE_UNAVAILABLE, GP_ITEM_UNAVAILABLE,
  GP_SERVICE_TIMEOUT, GP_DEVELOPER_ERROR, SUBS_UPD_WITH_TIME_PRORATION, GP_ITEM_ALREADY_OWNED,
  GP_PURCHSTATE_PENDING, GP_BILLING_UNAVAILABLE
} = billingModule
let dbgStatuses = [GP_OK, GP_USER_CANCELED, GP_SERVICE_UNAVAILABLE, GP_ITEM_UNAVAILABLE, GP_SERVICE_TIMEOUT]
local dbgStatusIdx = 0
let dbgSubsPlans = {}
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
          billingPeriod = v?.sku_type == "subs" ? "P1M" : ""
          subscriptionOfferDetails = (dbgSubsPlans?[v.google_id].keys() ?? [])
            .map(@(planId) {
              basePlanId = planId,
              pricingPhases = [{
                priceAmountMicros = getDebugPriceMicros(planId)
                priceCurrencyCode = "RUB"
                billingPeriod = "P1M"
              }]
            })
        }))
    }
    setTimeout(0.1, @() eventbus_send("android.billing.googleplay.onInitAndDataRequested", result))
  },
  startPurchaseAsync = @(_) setTimeout(1.0,
    @() eventbus_send("android.billing.googleplay.onGooglePurchaseCallback", {
      status = dbgStatuses[dbgStatusIdx++ % dbgStatuses.len()],
      value = "{ \"orderId\" : -1, \"productId\" : \"debug\", \"purchaseState\" : 4 }"
    })),
  upgradeSubscription = @(_oldSku, _newSku, _proration_mode) setTimeout(1.0,
    @() eventbus_send("android.billing.googleplay.onGooglePurchaseCallback", {
      status = dbgStatuses[dbgStatusIdx++ % dbgStatuses.len()],
      value = "{ \"orderId\" : -1, \"productId\" : \"debug\" }"
    })),
  confirmPurchase = @(_) setTimeout(1.0, @() eventbus_send("android.billing.googleplay.onConfirmPurchaseCallback", { status = 0, value = "{}" })),
  restorePurchases = @() setTimeout(1.0,
    @() eventbus_send("android.billing.googleplay.onRestorePurchases", {
      status = GP_OK,
      transactions = [
        { status = GP_OK, value = "{ \"orderId\" : -1, \"productId\" : \"debug1\" }" },
        { status = GP_OK, value = "{ \"orderId\" : -2, \"productId\" : \"debug2\" }" }
      ]
    })),
} = !isDebugMode ? billingModule : {}
let register_googleplay_purchase = !is_pc ? registerGoogleplayPurchase
  : @(_, __, eventId) setTimeout(0.1, @() eventbus_send(eventId, { status = YU2_OK, item_id = "id", purch_token = "token" })) //for debug on pc


const REPEAT_ON_ERROR_MSEC = 60000
const RESTORE_NOT_STARTED = 0
const RESTORE_STARTED = 1
const RESTORE_STARTED_SILENT = 2
const RESTORE_REQUIRE = 3

let lastInitStatus = hardPersistWatched("goodsAndroid.lastInitStatus", GP_NOT_INITED)
let skusInfo = hardPersistWatched("goodsAndroid.skusInfo", {})
let purchaseInProgress = mkWatched(persist, "purchaseInProgress", null)
let restoreStatus = mkWatched(persist, "restoreStatus", RESTORE_NOT_STARTED)
let nextRefreshTime = Watched(-1)
let pendingTransactions = hardPersistWatched("goodsAndroid.pendingTransactions", [])
let isRegisterInProgress = hardPersistWatched("goodsAndroid.isRegisterInProgress", false)
let lastYu2TimeoutErrorTime = hardPersistWatched("goodsAndroid.lastYu2TimeoutErrorTime", 0)

function getPriceInfo(info) {
  let { priceCurrencyCode = null, priceAmountMicros = null, billingPeriod = "" } = info
  if (priceAmountMicros == null || priceCurrencyCode == null)
    return null
  let priceFloat = round_by_value(0.000001 * priceAmountMicros, 0.01)
  let currencyId = priceCurrencyCode.tolower()
  return {
    price = priceFloat
    currencyId
    priceText = getPriceExtStr(priceFloat, currencyId)
    billingPeriod = parse_duration(billingPeriod)
  }
}

let availableSkusPrices = Computed(function() {
  let res = {}
  foreach (info in skusInfo.value) {
    let { productId = null, subscriptionOfferDetails = [] } = info
    let priceInfo = getPriceInfo(info)
    if (productId == null || priceInfo == null)
      continue
    if (subscriptionOfferDetails.len() > 0) {
      priceInfo.subsPlans <- {}
      foreach(detail in subscriptionOfferDetails) {
        let { basePlanId = null, pricingPhases = [] } = detail
        let planPriceInfo = getPriceInfo(pricingPhases?[0]) //support only single phase atm
        if (basePlanId != null && planPriceInfo != null)
          priceInfo.subsPlans[basePlanId] <- planPriceInfo
      }
    }
    res[productId] <- priceInfo
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
})

let getSku = @(goods) goods?.purchaseGuids.android.extId
let getPlanId = @(goods) goods?.purchaseGuids.android.planId
let getAndroidDiscount = @(goods) goods?.purchaseGuids.android.discountInPercent ?? 0

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

let subsIdBySku = Computed(function() {
  let res = {}
  foreach (id, subs in campConfigs.value?.subscriptionsCfg ?? {}) {
    let sku = getSku(subs)
    let planId = getPlanId(subs)
    if (sku == null || planId == null)
      continue
    if (sku not in res)
      res[sku] <- {}
    res[sku][planId] <- id
  }
  if (isDebugMode)
    dbgSubsPlans.__update(res)
  return res
})

let skusForRequest = keepref(Computed(function() {
  if (!isAuthorized.value)
    return ""

  let received = skusInfo.get()
  let ids = goodsIdBySku.value.filter(@(_, sku) sku not in received)
  if (offerSku.value != null && (offerSku.value not in received))
    ids[offerSku.value] <- activeOffers.value.id
  let subsIds = subsIdBySku.get().filter(@(_, sku) sku not in received)
  if (ids.len() == 0 && subsIds.len() == 0)
    return ""
  let list = {}
  foreach (k, _ in ids)
    list[k] <- { google_id = k }
  foreach (k, _ in subsIds)
    list[k] <- { google_id = k, sku_type = "subs" }
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
    if (goods != null) {
      let platformDiscount = getAndroidDiscount(goods)
      let discountInPercent = platformDiscount != 0 ? platformDiscount : (goods?.discountInPercent ?? 0)
      res[goodsId] <- goods.__merge({ priceExt, discountInPercent }) //warning disable: -potentially-nulled-index
    }
  }
  return res
})

let platformSubs = Computed(function() {
  let { subscriptionsCfg = {} } = campConfigs.get()
  let prices = availableSkusPrices.get()
  let res = {}
  foreach (sku, plans in subsIdBySku.get())
    foreach (planId, subsId in plans) {
      let priceExt = prices?[sku].subsPlans[planId]
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
  let platformDiscount = getAndroidDiscount(offer)
  return offer.__merge({
    priceExt
    discountInPercent = platformDiscount != 0 ? platformDiscount : (offer?.discountInPercent ?? 0)
  })
})

function buyPlatformGoods(goodsOrId) {
  let goods = platformGoods.get()?[goodsOrId] ?? platformSubs.get()?[goodsOrId] ?? goodsOrId
  let sku = getSku(goods)
  let planId = getPlanId(goods)
  if (sku == null)
    return
  let skuExt = planId == null ? sku : $"{sku}:{planId}"
  logG($"Buy {skuExt}")
  startPurchaseAsync(skuExt)
  purchaseInProgress.set(skuExt)
}

function changeSubscription(subsTo, subsFrom) {
  let skuFrom = getSku(platformSubs.get()?[subsFrom] ?? subsFrom)
  let goodsTo = platformSubs.get()?[subsTo] ?? subsTo
  let skuTo = getSku(goodsTo)
  let planIdTo = getPlanId(goodsTo)
  if (skuTo == null || skuFrom == null)
   return
  let skuToExt = planIdTo == null ? skuTo : $"{skuTo}:{planIdTo}"
  logG($"Change subscription from {skuFrom} to {skuToExt}")
  upgradeSubscription(skuFrom, skuToExt, SUBS_UPD_WITH_TIME_PRORATION)
  purchaseInProgress.set(skuToExt)
}

let noNeedLogerr = [ GP_SERVICE_TIMEOUT, GP_USER_CANCELED, GP_DEVELOPER_ERROR, GP_BILLING_UNAVAILABLE ]

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

function onFinishRestore() {
  logG("Restore finished")
  if (restoreStatus.get() == RESTORE_STARTED)
    showRestorePurchasesDoneMsg()
  restoreStatus.set(RESTORE_NOT_STARTED)
  purchaseInProgress.set(null)
}

function restorePurchasesExt(isSilent = true) {
  logG($"restorePurchases (isSilent = {isSilent})")
  lastYu2TimeoutErrorTime.set(0)
  purchaseInProgress.set("")
  restoreStatus.set(isSilent ? RESTORE_STARTED_SILENT : RESTORE_STARTED)
  restorePurchases()
}

let needAutoRestore = keepref(Computed(@() isLoggedIn.get() && lastInitStatus.get() == GP_OK))
needAutoRestore.subscribe(@(v) v ? restorePurchasesExt() : null)

let startSilentRestorePurchases = @() restorePurchasesExt()
function startRestorePurchasesTimer() {
  if (isInBattle.get() || lastYu2TimeoutErrorTime.get() <= 0)
    clearTimer(startSilentRestorePurchases)
  else
    resetTimeout(max(0.1, 0.001 * (lastYu2TimeoutErrorTime.get() + REPEAT_ON_ERROR_MSEC - get_time_msec())),
      startSilentRestorePurchases)
}
startRestorePurchasesTimer()
lastYu2TimeoutErrorTime.subscribe(@(_) startRestorePurchasesTimer())
isInBattle.subscribe(@(_) startRestorePurchasesTimer())

function registerNextTransaction() {
  if (isRegisterInProgress.get())
    return
  if (pendingTransactions.get().len() == 0) {
    if (restoreStatus.get() == RESTORE_REQUIRE) {
      restorePurchasesExt()
      return
    }
    if (restoreStatus.get() != RESTORE_NOT_STARTED)
      onFinishRestore()
    return
  }
  let { status, value } = pendingTransactions.get()[0]
  pendingTransactions.set(pendingTransactions.get().slice(1))
  if (status == GP_OK) {
    logG("registerGooglePurchase ", value)

    let info = parse_json(value)
    if (info?.purchaseState == GP_PURCHSTATE_PENDING) {
      logG("purchaseState = GP_PURCHSTATE_PENDING")
      purchaseInProgress.set(null)
      if (restoreStatus.get() != RESTORE_STARTED_SILENT)
        openFMsgBox({ text = loc("msg/purchasePending") })
      registerNextTransaction()
      return
    }

    isRegisterInProgress.set(true)
    register_googleplay_purchase(value, false, "auth.onRegisterGooglePurchase")
    sendLogPurchaseData(value)
    return
  }

  purchaseInProgress.set(null)
  let statusName = getStatusName(status)
  local needLogerr = !noNeedLogerr.contains(status)
  if (status == GP_ITEM_ALREADY_OWNED
      && (restoreStatus.get() == RESTORE_NOT_STARTED || restoreStatus.get() == RESTORE_REQUIRE)) {
    needLogerr = false
    logG("Set require restore on GP_ITEM_ALREADY_OWNED")
    restoreStatus.set(RESTORE_REQUIRE)
  }
  if (needLogerr)
    logerr($"onGooglePurchaseCallback fail: status = {statusName}")
  let msgLocId = $"error/googleplay/{statusName}"
  if (doesLocTextExist(msgLocId))
    openFMsgBox({ text = loc(msgLocId) })

  registerNextTransaction()
}

eventbus_subscribe("android.billing.googleplay.onGooglePurchaseCallback", function(result) {
  let { status, value = "" } = result
  logG($"onGooglePurchaseCallback status = {getStatusName(status)}")
  let list =  [{ status, value }]
  pendingTransactions.mutate(@(v) v.extend(list))
  registerNextTransaction()
})

eventbus_subscribe("android.billing.googleplay.onRestorePurchases", function(result) {
  let { status, transactions = [] } = result
  logG($"onRestorePurchases status = {getStatusName(status)}")
  if (transactions.len() == 0) {
    onFinishRestore()
    return
  }

  if (restoreStatus.get() == RESTORE_NOT_STARTED) {
    logG("Change restore to silent on event restore purchases")
    restoreStatus.set(RESTORE_STARTED_SILENT)
  }
  pendingTransactions.mutate(@(v) v.extend(transactions))
  registerNextTransaction()
})

eventbus_subscribe("android.billing.googleplay.onConfirmPurchaseCallback", function(result) {
  let { status } = result
  purchaseInProgress.set(null)
  if (status == GP_OK) {
    logG("onConfirmPurchaseCallback success")
    startSeveralCheckPurchases()
  } else {
    logG($"onConfirmPurchaseCallback fail: status = {getStatusName(status)}")
    openFMsgBox({ text = loc("msg/errorAuthGoodsCheck") })
  }
  registerNextTransaction()
})

let showErrorMsg = @(text, wndOvr = {}) restoreStatus.get() == RESTORE_STARTED_SILENT ? null
  : openFMsgBox({ text, wndOvr })

eventbus_subscribe("auth.onRegisterGooglePurchase", function(result) {
  isRegisterInProgress.set(false)
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
  purchaseInProgress.set(null)
  logG($"register_googleplay_purchase error={getYu2CodeName(status)}")
  if (status == YU2_WRONG_PAYMENT)
    showErrorMsg(loc("msg/errorPaymentDelayed"))
  else if (status in yu2BadConnectionCodes) {
    lastYu2TimeoutErrorTime.set(get_time_msec())
    showErrorMsg(loc("msg/errorRegisterPaymentTimeout"), { size = [hdpx(1300), hdpx(700)] })
    if (restoreStatus.get() == RESTORE_STARTED || restoreStatus.get() == RESTORE_REQUIRE) {
      logG("Change restore to silent after auth error")
      restoreStatus.set(RESTORE_STARTED_SILENT)
    }
  }
  else
    showErrorMsg(loc("msg/errorWhileRegisteringPurchase"))
  registerNextTransaction()
})

function getSubsId(subsIdBySkuV, skuExt) {
  let values = skuExt.split(":")
  if (values.len() < 2)
    return null
  let [ sku, planId ] = values
  return subsIdBySkuV?[sku][planId]
}

let platformPurchaseInProgress = Computed(@() purchaseInProgress.get() == null ? null
  : purchaseInProgress.get() == "" ? ""
  : offerSku.get() == purchaseInProgress.get() ? activeOffers.get()?.id
  : (goodsIdBySku.get()?[purchaseInProgress.get()] ?? getSubsId(subsIdBySku.get(), purchaseInProgress.get())))

return {
  platformGoodsDebugInfo = skusInfo
  platformGoods
  platformOffer
  platformSubs
  buyPlatformGoods
  activatePlatfromSubscription = buyPlatformGoods
  changeSubscription
  platformPurchaseInProgress
  restorePurchases = @() restorePurchasesExt(false)
}