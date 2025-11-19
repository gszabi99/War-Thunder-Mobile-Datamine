from "%globalsDarg/darg_library.nut" import *
let logG = log_with_prefix("[GOODS] ")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setTimeout, resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { YU2_OK, YU2_EXPIRED, YU2_WRONG_PAYMENT, registerApplePurchase } = require("auth_wt")
let { is_pc } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { parse_duration } = require("%sqstd/iso8601.nut")
let { getYu2CodeName, yu2BadConnectionCodes } = require("%appGlobals/yu2ErrCodes.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized, isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { startSeveralCheckPurchases } = require("%rGui/shop/checkPurchases.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { object_to_json_string, parse_json } = require("json")
let { logEvent } = require("appsFlyer")
let { showRestorePurchasesDoneMsg } = require("%rGui/shop/byPlatform/platformGoodsCommon.nut")

let getDebugPrice = @(id) 0.01 * (id.hash() % 100000)
let billingModule = require("ios.billing.appstore")
let { AS_OK, AS_CANCELED, AS_NOT_INITED, AS_FAILED, AS_CANT_BUY } = billingModule
let dbgPurchAnswers = [
  { status = AS_OK, id = "id1", data = "receipt_or_error" },
  { status = AS_OK, id = "id2", data = "transaction_data", transaction_id = "dbg_1" },
  { status = AS_OK, transactions =
    [
      { status = AS_OK, id = "id3", data = "data3", transaction_id = "trans3"},
      { status = AS_OK, id = "id4", data = "data4", transaction_id = "trans4"}
    ]
  }
]

local dbgCounter = 0
let { 
  initAndRequestData = function(list) {
    let result = {
      status = AS_OK
      value = list.map(@(id) {
        productId = id,
        title = $"{id} title",
        description = $"{id} description",
        price = getDebugPrice(id)
        price_currency = "RUB"
        subscriptionPeriod = "P1M"
      })
    }
    setTimeout(0.1, @() eventbus_send("ios.billing.onInitAndDataRequested", result))
  },
  startPurchaseAsync = @(_) setTimeout(1.0,
    @() eventbus_send("ios.billing.onPurchaseCallback",
      dbgPurchAnswers[dbgCounter++ % dbgPurchAnswers.len()])),
  confirmPurchase = @(_) setTimeout(1.0, @() eventbus_send("ios.billing.onConfirmPurchaseCallback",{status = true})),
  setSuspend = @(_) null
  restorePurchases = @(_) setTimeout(1.0,
    @() eventbus_send("ios.billing.onRestorePurchases", { status = AS_OK, transactions =
    [
      { status = AS_OK, id = "id3", data = "data3", transaction_id = "trans3"},
      { status = AS_OK, id = "id4", data = "data4", transaction_id = "trans4"}
    ]
  })),
} = !is_pc ? require("ios.billing.appstore") : {}
let register_apple_purchase = !is_pc ? registerApplePurchase
  : @(transaction_id, __, eventId) setTimeout(0.1,
      @() eventbus_send(eventId, { status = YU2_OK, transaction_id }))


const REPEAT_ON_ERROR_MSEC = 60000
const RESTORE_NOT_STARTED = 0
const RESTORE_STARTED = 1
const RESTORE_STARTED_SILENT = 2

let lastInitStatus = hardPersistWatched("goodsIos.lastInitStatus", AS_NOT_INITED)
let products = hardPersistWatched("goodsIos.products", {})
let pendingTransactions = hardPersistWatched("goodsIos.pendingTransactions", [])
let isRegisterInProgress = hardPersistWatched("goodsIos.isRegisterInProgress", false)
let lastYu2TimeoutErrorTime = hardPersistWatched("goodsIos.lastYu2TimeoutErrorTime", 0)
let purchaseInProgress = mkWatched(persist, "purchaseInProgress", null)
let restoreStatus = mkWatched(persist, "restoreStatus", RESTORE_NOT_STARTED)
let availablePrices = Computed(function() {
  let res = {}
  foreach (info in products.get()) {
    let { productId = null, price_currency = null, price = null, subscriptionPeriod = "" } = info
    if (productId == null || price == null || price_currency == null)
      continue
    let currencyId = price_currency.tolower()
    res[productId] <- {
      price
      currencyId
      priceText = getPriceExtStr(price, currencyId)
      billingPeriod = parse_duration(subscriptionPeriod)
    }
  }
  return res
})
let nextRefreshTime = Watched(-1)

let statusNames = {}
foreach(id, val in billingModule)
  if (type(val) == "integer" && id.startswith("AS_"))
    statusNames[val] <- id
let getStatusName = @(status) statusNames?[status] ?? status

lastInitStatus.subscribe(@(v) logG($"init status {v}"))
products.subscribe(@(v) logG($"available products: ", v.keys()))
isAuthorized.subscribe(function(v) {
  if (v)
    return
  lastInitStatus.set(AS_NOT_INITED)
  products.set({})
})

isLoggedIn.subscribe(function(v) {
  if (!v)
    setSuspend(true)
})

function sendLogPurchaseData(product_id,transaction_id) {
  
  local af = {
    af_order_id = transaction_id
    af_content_id = product_id
    af_revenue = availablePrices.get()?[product_id].price ?? -1
    af_price = availablePrices.get()?[product_id].price ?? -1
    af_currency = availablePrices.get()?[product_id].currencyId ?? "USD"
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
  let count = restorePurchases.getfuncinfos().native
    ? restorePurchases.getfuncinfos().paramscheck
    : restorePurchases.getfuncinfos().parameters.len()
  if (count == 2)
    restorePurchases(isSilent)
  else
    restorePurchases()
}

let needAutoRestore = keepref(Computed(@() isLoggedIn.get() && lastInitStatus.get() == AS_OK))
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
    if (restoreStatus.get() != RESTORE_NOT_STARTED)
      onFinishRestore()
    return
  }
  let { status, id, transaction_id = null, data } = pendingTransactions.get()[0]
  pendingTransactions.set(pendingTransactions.get().slice(1))
  if (status == AS_OK) {
    logG("registerApplePurchase ", id, transaction_id)
    isRegisterInProgress.set(true)
    register_apple_purchase(transaction_id, data, "ios.billing.onAuthPurchaseCallback")
    sendLogPurchaseData(id, transaction_id)
  } else {
    purchaseInProgress.set(null)
    if (status != AS_CANCELED) {
      local error_text = data ?? "fail"
      openFMsgBox({ text = loc($"msg/onApplePurchaseError/{error_text}") })
    }
    if (status == AS_FAILED || status == AS_CANT_BUY)
      logerr($"onIOSPurchaseCallback fail: status = {getStatusName(status)}")
    registerNextTransaction()
  }
}

eventbus_subscribe("ios.billing.onConfirmPurchaseCallback", function(result) {
  purchaseInProgress.set(null)
  if (result.status) {
    logG("onConfirmPurchaseCallback success")
    startSeveralCheckPurchases()
  }
  else {
    logG($"onConfirmPurchaseCallback fail: status = {getStatusName(result.status)}")
    openFMsgBox({ text = loc("msg/onApplePurchaseConfirmError") })
  }
  registerNextTransaction()
})

let showErrorMsg = @(text, wndOvr = {}) restoreStatus.get() == RESTORE_STARTED_SILENT ? null
  : openFMsgBox({ text, wndOvr })

eventbus_subscribe("ios.billing.onAuthPurchaseCallback", function(result) {
  isRegisterInProgress.set(false)
  let {status, purchase_transaction_id = null } = result

  if ((status == YU2_OK || status == YU2_EXPIRED) && purchase_transaction_id) {
    logG($"register_apple_purchase success")
    confirmPurchase(purchase_transaction_id)
    return
  }

  purchaseInProgress.set(null)
  logG($"register_apple_purchase error={getYu2CodeName(status)}")
  if (status == YU2_WRONG_PAYMENT)
    showErrorMsg(loc("msg/errorPaymentDelayed"))
  else if (status in yu2BadConnectionCodes) {
    lastYu2TimeoutErrorTime.set(get_time_msec())
    showErrorMsg(loc("msg/errorRegisterPaymentTimeout"), { size = const [hdpx(1300), hdpx(700)] })
    if (restoreStatus.get() == RESTORE_STARTED) {
      logG("Change restore to silent after auth error")
      restoreStatus.set(RESTORE_STARTED_SILENT)
    }
  }
  else
    showErrorMsg(loc("msg/onApplePurchaseAuthError" {error = status}))

  registerNextTransaction()
})

eventbus_subscribe("ios.billing.onPurchaseCallback", function(result) {
  let { status = null, id = null, data = null, transaction_id = null, transactions = null } = result

  let list =  transactions ?? [{ status, id, transaction_id, data }]
  pendingTransactions.mutate(@(v) v.extend(list))
  registerNextTransaction()
})

eventbus_subscribe("ios.billing.onRestorePurchases", function(result) {
  let { status = null, transactions = [] } = result
  logG($"onRestorePurchases status = {getStatusName(status)}")
  if (transactions.len() == 0) {
    onFinishRestore()
    return
  }

  if (restoreStatus.get() == RESTORE_NOT_STARTED) {
    logG("Set restore to silent on restore event")
    restoreStatus.set(RESTORE_STARTED_SILENT)
  }
  pendingTransactions.mutate(@(v) v.extend(transactions))
  registerNextTransaction()
})

eventbus_subscribe("ios.billing.onInitAndDataRequested", function(result) {
  let { status, value = null } = result
  lastInitStatus.set(status)
  if (status != AS_OK)
    return
  local items = value
  if (type(items) != "array") {
    items = parse_json(value)
    if (type(items) != "array") {
      logerr($"Bad format of ios.billing.onInitAndDataRequested: type of parsed value is {type(value)}")
      return
    }
  }
  products.mutate(@(allInfo) items.each(function(v) {
    let { productId = null } = v
    if (productId != null)
      allInfo[productId] <- v
  }))
})

let getProductId = @(goods) goods?.purchaseGuids.iOS.extId
let getPlanId = @(goods) goods?.purchaseGuids.iOS.planId
let getIosDiscount = @(goods) goods?.purchaseGuids.iOS.discountInPercent ?? 0

let goodsIdByProductId = Computed(function() {
  let res = {}
  foreach (id, goods in campConfigs.get()?.allGoods ?? {})
    if (can_debug_shop.get() || !goods.isShowDebugOnly) {
      let productId = getProductId(goods)
      if (productId != null)
        res[productId] <- id
    }
  return res
})

let subsIdByProductId = Computed(function() {
  let res = {}
  foreach (id, subs in campConfigs.get()?.subscriptionsCfg ?? {}) {
    let productId = getPlanId(subs)
    if (productId != null)
      res[productId] <- id
  }
  return res
})

let offerProductId = Computed(@() getProductId(activeOffers.get()))

let productsForRequest = keepref(Computed(function(prev) {
  if (!isAuthorized.get())
    return []
  let received = products.get()
  let res = goodsIdByProductId.get().filter(@(_, id) id not in received)
    .keys()
  let offerId = offerProductId.get()
  if (offerId != null && (offerId not in received))
    res.append(offerId)
  res.extend(subsIdByProductId.get().filter(@(_, id) id not in received)
    .keys())
  return isEqual(prev, res) ? prev : res
}))

function refreshAvailableProducts() {
  if (productsForRequest.get().len() == 0)
    return
  if (lastInitStatus.get() != AS_OK)
    lastInitStatus.set(AS_NOT_INITED) 
  logG("initAndRequestData: ", productsForRequest.get())
  initAndRequestData(productsForRequest.get())
}

productsForRequest.subscribe(@(_) refreshAvailableProducts())
if (lastInitStatus.get() == AS_NOT_INITED)
  refreshAvailableProducts()

let updateNextRefreshTime = @(status)
  nextRefreshTime.set(status == AS_NOT_INITED || status == AS_OK ? -1 : get_time_msec() + REPEAT_ON_ERROR_MSEC)
updateNextRefreshTime(lastInitStatus.get())
lastInitStatus.subscribe(updateNextRefreshTime)

function startRefreshTimer() {
  if (isInBattle.get() || nextRefreshTime.get() <= 0)
    clearTimer(refreshAvailableProducts)
  else
    resetTimeout(max(0.1, 0.001 * (nextRefreshTime.get() - get_time_msec())), refreshAvailableProducts)
}
startRefreshTimer()
nextRefreshTime.subscribe(@(_) startRefreshTimer())
isInBattle.subscribe(@(_) startRefreshTimer())

let platformGoods = Computed(function() {
  let allGoods = campConfigs.get()?.allGoods ?? {}
  let productToGoodsId = goodsIdByProductId.get()
  let res = {}
  foreach (productId, priceExt in availablePrices.get()) {
    let goodsId = productToGoodsId?[productId]
    let goods = allGoods?[goodsId]
    if (goods != null) {
      let platformDiscount = getIosDiscount(goods)
      let discountInPercent = platformDiscount != 0 ? platformDiscount : (goods?.discountInPercent ?? 0)
      res[goodsId] <- goods.__merge({ priceExt, discountInPercent }) 
    }
  }
  return res
})

let platformSubs = Computed(function() {
  let { subscriptionsCfg = {} } = campConfigs.get()
  let prices = availablePrices.get()
  let res = {}
  foreach (productId, subsId in subsIdByProductId.get()) {
    let priceExt = prices?[productId]
    let subs = subscriptionsCfg?[subsId]
    if (priceExt != null && subs != null)
      res[subsId] <- subs.__merge({ priceExt, billingPeriod = priceExt.billingPeriod })
  }
  return res
})

let platformOffer = Computed(function() {
  let offer = activeOffers.get()
  let priceExt = availablePrices.get()?[getProductId(offer)]
  if (priceExt == null || offer == null)
    return null
  let platformDiscount = getIosDiscount(offer)
  return offer.__merge({
    priceExt
    discountInPercent = platformDiscount != 0 ? platformDiscount : (offer?.discountInPercent ?? 0)
  })
})

function buyPlatformGoods(goodsOrId) {
  let productId = getPlanId(platformSubs.get()?[goodsOrId] ?? goodsOrId)
    ?? getProductId(platformGoods.get()?[goodsOrId] ?? goodsOrId)
  if (productId == null)
    return
  logG($"Buy {productId}")
  startPurchaseAsync(productId)
  purchaseInProgress.set(productId)
}

function changeSubscription(subsOrId, _) {
  buyPlatformGoods(subsOrId)
}

let platformPurchaseInProgress = Computed(@() purchaseInProgress.get() == null ? null
  : purchaseInProgress.get() == "" ? ""
  : offerProductId.get() == purchaseInProgress.get() ? activeOffers.get()?.id
  : (goodsIdByProductId.get()?[purchaseInProgress.get()] ?? subsIdByProductId.get()?[purchaseInProgress.get()]))

return {
  platformGoodsDebugInfo = products
  platformGoods
  platformOffer
  platformSubs
  buyPlatformGoods
  activatePlatfromSubscription = buyPlatformGoods
  changeSubscription
  platformPurchaseInProgress
  restorePurchases = @() restorePurchasesExt(false)
}
