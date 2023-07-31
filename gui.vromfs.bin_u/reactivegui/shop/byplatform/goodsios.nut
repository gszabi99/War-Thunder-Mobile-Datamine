from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { setTimeout, resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { doesLocTextExist } = require("dagor.localize")
let logG = log_with_prefix("[GOODS] ")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { startSeveralCheckPurchases } = require("%rGui/shop/checkPurchases.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let getDebugPrice = @(id) 0.01 * (id.hash() % 100000)

let {
  YU2_OK = 0,
  registerApplePurchase = @(_, eventId) setTimeout(0.1,
    @() send(eventId, { status = 0, transaction_id = "id" }))
} = require("auth_wt")

let { //defaults only to allow test this module on PC
  AS_OK = 0,
  AS_CANCELED = -1,
  AS_NOT_INITED = -12,
  initAndRequestData = function(list) {
    let result = {
      status = 0 //AS_OK
      value = list.map(@(id) {
        productId = id,
        title = $"{id} title",
        description = $"{id} description",
        price = getDebugPrice(id)
        price_currency = "RUB"
      })
    }
    setTimeout(0.1, @() send("ios.billing.onInitAndDataRequested", result))
  },
  startPurchaseAsync = @(_) setTimeout(1.0,
    @() send("ios.billing.onPurchaseCallback", { status = 0, data = "receipt_or_error" })),
  confirmPurchase = @(_) setTimeout(1.0, @() send("ios.billing.onConfirmPurchaseCallback",{status = true}))
} = require("ios.billing.appstore")

const REPEAT_ON_ERROR_MSEC = 60000
let lastInitStatus = mkHardWatched("goodsIos.lastInitStatus", AS_NOT_INITED)
let products = mkHardWatched("goodsIos.products", {})
let purchaseInProgress = mkWatched(persist, "purchaseInProgress", null)
let availablePrices = Computed(function() {
  let res = {}
  foreach (info in products.value) {
    let { productId = null, price_currency = null, price = null } = info
    if (productId == null || price == null || price_currency == null)
      continue
    let currencyId = price_currency.tolower()
    let locId = $"priceText/{currencyId}"
    res[productId] <- {
      price
      currencyId
      priceText = doesLocTextExist(locId) ? loc(locId, { price }) : $"{price} {price_currency}"
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

subscribe("ios.billing.onConfirmPurchaseCallback", function(result) {
  purchaseInProgress(null)
  if (result.status) {
    startSeveralCheckPurchases()
    return
  }
  openFMsgBox({ text = loc("msg/onApplePurchaseConfirmError") })
})

subscribe("ios.billing.onAuthPurchaseCallback", function(result) {
  let {status, transaction_id = null } = result

  if (status == YU2_OK && transaction_id) {
    logG($"register_apple_purchase success")
    confirmPurchase(transaction_id)
    return
  }
  purchaseInProgress(null)
  logG($"register_apple_purchase error={status}")
  openFMsgBox({ text = loc("msg/onApplePurchaseAuthError" {error = status}) })
})

subscribe("ios.billing.onPurchaseCallback", function(result) {
  let { status, data = null } = result
  logG("onPurchaseCallback status = ", status)
  if (status == AS_OK && data) {
    registerApplePurchase(data,"ios.billing.onAuthPurchaseCallback")
  } else {
    purchaseInProgress(null)
    if (status != AS_CANCELED) {
      local error_text = data ?? "fail"
      openFMsgBox({ text = loc($"msg/onApplePurchaseError/{error_text}") })
    }
  }
})

subscribe("ios.billing.onInitAndDataRequested", function(result) {
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

let goodsIdByProductId = Computed(function() {
  let res = {}
  foreach (id, goods in campConfigs.value?.allGoods ?? {})
    if (can_debug_shop.value || !goods.isShowDebugOnly) {
      let productId = goods?.purchaseIds.android
      if (productId != null)
        res[productId] <- id
    }
  return res
})

let offerProductId = Computed(@() activeOffers.value?.purchaseIds.android)

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

let function refreshAvailableProducts() {
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

let function startRefreshTimer() {
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
  foreach (productId, priceExt in availablePrices.value) { //todo: need to divide price and currency here to 2 fields
    let goodsId = productToGoodsId?[productId]
    let goods = allGoods?[goodsId]
    if (goods != null)
      res[goodsId] <- goods.__merge({ priceExt }) //warning disable: -potentially-nulled-index
  }
  return res
})

let platformOffer = Computed(function() {
  let priceExt = availablePrices.value?[activeOffers.value?.purchaseIds.android]
  return priceExt == null || activeOffers.value == null ? null
    : activeOffers.value.__merge({ priceExt })
})

let function buyPlatformGoods(goodsOrId) {
  let productId = (platformGoods.value?[goodsOrId] ?? goodsOrId).purchaseIds.android
  if (productId == null)
    return
  startPurchaseAsync(productId)
  purchaseInProgress(productId)
}


let platformPurchaseInProgress = Computed(@() offerProductId.value == purchaseInProgress.value ? activeOffers.value?.id
  : goodsIdByProductId.value?[purchaseInProgress.value])

return {
  platformGoodsDebugInfo = products
  platformGoods
  platformOffer
  buyPlatformGoods
  platformPurchaseInProgress
}
