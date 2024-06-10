from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setTimeout, resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let logG = log_with_prefix("[GOODS] ")
let { is_pc } = require("%sqstd/platform.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized, isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { startSeveralCheckPurchases } = require("%rGui/shop/checkPurchases.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { object_to_json_string } = require("json")
let { logEvent } = require("appsFlyer")
let getDebugPrice = @(id) 0.01 * (id.hash() % 100000)

let {
  YU2_OK = 0,
  registerApplePurchase = @(_, __, eventId) setTimeout(0.1,
    @() eventbus_send(eventId, { status = 0, transaction_id = "id" }))
} = require("auth_wt")

let billingModule = require("ios.billing.appstore")
let { AS_OK = 0, AS_CANCELED = -1, AS_NOT_INITED = -12 } = billingModule
let { //defaults only to allow test this module on PC
  initAndRequestData = function(list) {
    let result = {
      status = AS_OK
      value = list.map(@(id) {
        productId = id,
        title = $"{id} title",
        description = $"{id} description",
        price = getDebugPrice(id)
        price_currency = "RUB"
      })
    }
    setTimeout(0.1, @() eventbus_send("ios.billing.onInitAndDataRequested", result))
  },
  startPurchaseAsync = @(_) setTimeout(1.0,
    @() eventbus_send("ios.billing.onPurchaseCallback", { status = AS_OK, data = "receipt_or_error" })),
  confirmPurchase = @(_) setTimeout(1.0, @() eventbus_send("ios.billing.onConfirmPurchaseCallback",{status = true})),
  setSuspend = @(_) null
} = !is_pc ? require("ios.billing.appstore") : {}

const REPEAT_ON_ERROR_MSEC = 60000
let lastInitStatus = hardPersistWatched("goodsIos.lastInitStatus", AS_NOT_INITED)
let products = hardPersistWatched("goodsIos.products", {})
let purchaseInProgress = mkWatched(persist, "purchaseInProgress", null)
let availablePrices = Computed(function() {
  let res = {}
  foreach (info in products.value) {
    let { productId = null, price_currency = null, price = null } = info
    if (productId == null || price == null || price_currency == null)
      continue
    let currencyId = price_currency.tolower()
    res[productId] <- {
      price
      currencyId
      priceText = getPriceExtStr(price, currencyId)
    }
  }
  return res
})
let nextRefreshTime = Watched(-1)

lastInitStatus.subscribe(@(v) logG($"init status {v}"))
products.subscribe(@(v) logG($"available products: ", v.keys()))
isAuthorized.subscribe(function(v) {
  if (v)
    return
  lastInitStatus(AS_NOT_INITED)
  products({})
})

eventbus_subscribe("ios.billing.onConfirmPurchaseCallback", function(result) {
  purchaseInProgress(null)
  if (result.status) {
    startSeveralCheckPurchases()
    return
  }
  openFMsgBox({ text = loc("msg/onApplePurchaseConfirmError") })
})

eventbus_subscribe("ios.billing.onAuthPurchaseCallback", function(result) {
  let {status, purchase_transaction_id = null } = result

  if (status == YU2_OK && purchase_transaction_id) {
    logG($"register_apple_purchase success")
    confirmPurchase(purchase_transaction_id)
    return
  }
  purchaseInProgress(null)
  logG($"register_apple_purchase error={status}")
  openFMsgBox({ text = loc("msg/onApplePurchaseAuthError" {error = status}) })
})

isLoggedIn.subscribe(function(v) {
  if (!v)
    setSuspend(true)
})

function sendLogPurchaseData(product_id,transaction_id) {
  //see more here: https://support.appsflyer.com/hc/en-us/articles/4410481112081
  local af = {
    af_order_id = transaction_id
    af_content_id = product_id
    af_revenue = availablePrices.value?[product_id].price ?? -1
    af_price = availablePrices.value?[product_id].price ?? -1
    af_currency = availablePrices.value?[product_id].currencyId ?? "USD"
  }
  logEvent("af_purchase", object_to_json_string(af, true))
}

eventbus_subscribe("ios.billing.onPurchaseCallback", function(result) {
  let { status, id = null, data = null, transaction_id = null } = result
  logG("onPurchaseCallback status = ", status)
  if (status == AS_OK && id && data && transaction_id) {
    registerApplePurchase(transaction_id, data, "ios.billing.onAuthPurchaseCallback")
    sendLogPurchaseData(id,transaction_id)
  } else {
    purchaseInProgress(null)
    if (status != AS_CANCELED) {
      local error_text = data ?? "fail"
      openFMsgBox({ text = loc($"msg/onApplePurchaseError/{error_text}") })
    }
  }
})

eventbus_subscribe("ios.billing.onInitAndDataRequested", function(result) {
  let { status, value = null } = result
  lastInitStatus(status)
  if (status != AS_OK)
    return
  if (type(value) != "array") {
    logerr($"Bad format of ios.billing.onInitAndDataRequested: type of parsed value is {type(value)}")
    return
  }
  products.mutate(@(allInfo) value.each(function(v) {
    let { productId = null } = v
    if (productId != null)
      allInfo[productId] <- v
  }))
})

let getProductId = @(goods) goods?.purchaseGuids.iOS.extId

let goodsIdByProductId = Computed(function() {
  let res = {}
  foreach (id, goods in campConfigs.value?.allGoods ?? {})
    if (can_debug_shop.value || !goods.isShowDebugOnly) {
      let productId = getProductId(goods)
      if (productId != null)
        res[productId] <- id
    }
  return res
})

let offerProductId = Computed(@() getProductId(activeOffers.value))

let productsForRequest = keepref(Computed(function(prev) {
  if (!isAuthorized.value)
    return []
  let res = goodsIdByProductId.value.filter(@(_, id) id not in products.value)
    .keys()
  let offerId = offerProductId.value
  if (offerId != null && (offerId not in products.value))
    res.append(offerId)
  return isEqual(prev, res) ? prev : res
}))

function refreshAvailableProducts() {
  if (productsForRequest.value.len() == 0)
    return
  if (lastInitStatus.value != AS_OK)
    lastInitStatus(AS_NOT_INITED) //remove error status by request
  logG("initAndRequestData: ", productsForRequest.value)
  initAndRequestData(productsForRequest.value)
}

productsForRequest.subscribe(@(_) refreshAvailableProducts())
if (lastInitStatus.value == AS_NOT_INITED)
  refreshAvailableProducts()

let updateNextRefreshTime = @(status)
  nextRefreshTime(status == AS_NOT_INITED || status == AS_OK ? -1 : get_time_msec() + REPEAT_ON_ERROR_MSEC)
updateNextRefreshTime(lastInitStatus.value)
lastInitStatus.subscribe(updateNextRefreshTime)

function startRefreshTimer() {
  if (isInBattle.value || nextRefreshTime.value <= 0)
    clearTimer(refreshAvailableProducts)
  else
    resetTimeout(max(0.1, 0.001 * (nextRefreshTime.value - get_time_msec())), refreshAvailableProducts)
}
startRefreshTimer()
nextRefreshTime.subscribe(@(_) startRefreshTimer())
isInBattle.subscribe(@(_) startRefreshTimer())

let platformGoods = Computed(function() {
  let allGoods = campConfigs.value?.allGoods ?? {}
  let productToGoodsId = goodsIdByProductId.value
  let res = {}
  foreach (productId, priceExt in availablePrices.value) {
    let goodsId = productToGoodsId?[productId]
    let goods = allGoods?[goodsId]
    if (goods != null)
      res[goodsId] <- goods.__merge({ priceExt }) //warning disable: -potentially-nulled-index
  }
  return res
})

let platformOffer = Computed(function() {
  let priceExt = availablePrices.value?[getProductId(activeOffers.value)]
  return priceExt == null || activeOffers.value == null ? null
    : activeOffers.value.__merge({ priceExt })
})

function buyPlatformGoods(goodsOrId) {
  let productId = getProductId(platformGoods.value?[goodsOrId] ?? goodsOrId)
  if (productId == null)
    return
  startPurchaseAsync(productId)
  purchaseInProgress(productId)
}


let platformPurchaseInProgress = Computed(@() offerProductId.get() == null ? null
  : offerProductId.get() == purchaseInProgress.get() ? activeOffers.get()?.id
  : goodsIdByProductId.get()?[purchaseInProgress.get()])

return {
  platformGoodsDebugInfo = products
  platformGoods
  platformOffer
  buyPlatformGoods
  platformPurchaseInProgress
}
