from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setTimeout } = require("dagor.workcycle")
let logG = log_with_prefix("[GOODS] eshop:")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { campConfigs, activeOffers } = require("%appGlobals/pServer/campaign.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { can_debug_shop } = require("%appGlobals/permissions.nut")
let { startSeveralCheckPurchases } = require("%rGui/shop/checkPurchases.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")

let {
  REQUEST_FINISHED = 0,
  REQUEST_TIMEOUT = -1,
  REQUEST_NETWORK_ERROR = 2,
  initialize = @() setTimeout(0.1,  @() eventbus_send("nswitch.eshop.onItemsRequested", { status = 0 })),
  getIncTaxMessage = @() "",
  getItemId = @(_) "WTM000",
  getItemNsUid = @(_) "000",
  getItemPrice = @(_) "0 $",
  getItemRawPrice = @(_) "0",
  getItemGroupNsUid = @(_) "111",
  getItemCurrency = @(_) "USD",
  getItemsCount = @() 1,
  getItemName = @(_) "dummy",
  getRequestConsumableGroupErrorCode = @() {group = 0, code = 0},
  updateGroupAndItemsAsync = @() setTimeout(0.1,  @() eventbus_send("nswitch.eshop.onItemsRequested", { status = 0 })),
  showShopConsumableItemDetail = @(_,__) null,
  showErrorWithCode = @(_) null
} = require("nswitch.eshop")

let { getNsaToken, getNickname} = require("nswitch.account")
let { get_user_info, login_nswitch_async } = require("auth_wt")

let products = hardPersistWatched("goodsNSwitch.products", {})
let purchaseInProgress = mkWatched(persist, "purchaseInProgress", null)

let max_request_number = 5;
local request_number = 0;

let vatMsg = Watched("")

function extractEshopError() {
  let r = {}
  let result = get_user_info()
  r.eshop_error <- result?.eshop_error
  r.eshop_msg <- result?.eshop_msg
  return r
}


function requestEshopState(event_callback) {
  login_nswitch_async(getNickname(), getNsaToken(), event_callback)
}

function canOpenEshop() {
  let r = extractEshopError()
  return ((r?.eshop_error ?? 0) == 0)
}

function showErrorWithSystemDialog() {
  let r = extractEshopError()
  let eshop_error = r?.eshop_error ?? 0

  if (eshop_error != 0)
    showErrorWithCode(eshop_error)
}

eventbus_subscribe("goodsNSwitch_checkPurchasesState",function(_result) {
  if (!canOpenEshop()) {
    showErrorWithSystemDialog()
  }
  startSeveralCheckPurchases()
  purchaseInProgress(null)
})

function handlePurchase(product_id) {
  let nintendoId = getItemNsUid(product_id)
  let groupId = getItemGroupNsUid(product_id)

  if (groupId.len() == 0) {
    logG("cant groupId for product_id", product_id, nintendoId)
    purchaseInProgress(null)
    return
  }

  showShopConsumableItemDetail(groupId, nintendoId)
  requestEshopState("goodsNSwitch_checkPurchasesState")
}

let availablePrices = Computed(function() {
  let res = {}
  foreach (info in products.value) {
    let { productId = null, formatted_price = null, raw_price = 0, currency_price = ""} = info
    if (productId == null || formatted_price == null)
      continue
    res[productId] <- {
      price = raw_price
      currencyId = currency_price.tolower()
      priceText = formatted_price
    }
  }
  return res
})

products.subscribe(@(v) logG($"available products: ", v.keys()))

isAuthorized.subscribe(function(v) {
  if (v)
    return
  products({})
})

//currently checking only EU, but need to add other regions
let getProductId = @(goods) goods?.purchaseGuids?.switch_EU.extId

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

eventbus_subscribe("goodsNSwitch_buyPlatformGoods",function(_result) {
  if (!canOpenEshop()) {
    purchaseInProgress(null)
    showErrorWithSystemDialog()
    return
  }
  if (purchaseInProgress.value)
    handlePurchase(purchaseInProgress.value)
})

function buyPlatformGoods(goodsOrId) {
  let productId = getProductId(platformGoods.value?[goodsOrId] ?? goodsOrId)
  if (productId == null)
    return
  purchaseInProgress(productId)
  requestEshopState("goodsNSwitch_buyPlatformGoods")
}

let platformPurchaseInProgress = Computed(@() offerProductId.get() == null ? null
  : offerProductId.get() == purchaseInProgress.get() ? activeOffers.get()?.id
  : goodsIdByProductId.get()?[purchaseInProgress.get()])

function fillItems() {
  let count = getItemsCount()
  let items = {}
  for (local i=0; i < count; i++) {
    let itemId = getItemId(i)
    let nsUid = getItemNsUid(itemId)
    let groupNsUid = getItemGroupNsUid(itemId)
    let price = getItemPrice(itemId)
    let name = getItemName(itemId)
    let raw_price = getItemRawPrice(itemId).tointeger()
    let currency_price = getItemCurrency(itemId)
    items[itemId] <- {
      productId = itemId
      name = name,
      nsUid = nsUid,
      groupNsUid = groupNsUid,
      formatted_price = price
      raw_price
      currency_price
    }
    logG("show_eshop_items:", itemId, nsUid, groupNsUid)
  }

  products(items)
}

eventbus_subscribe("nswitch.eshop.onItemsRequested", function(val) {
  let status = val.status
  log($"onItemsRequested {status}")
  log(status)
  if (status == REQUEST_FINISHED) {
    fillItems()
    vatMsg(getIncTaxMessage())
    request_number = 0
  } else if(status == REQUEST_TIMEOUT && request_number < max_request_number) {
    request_number = request_number + 1
    logG("item request failed. Retry.")
    updateGroupAndItemsAsync()
  } else {
    let err = getRequestConsumableGroupErrorCode()
    if (err.group == 2308 && err.code == 2006) {
      openFMsgBox({ text = loc("nswitch/restricted_eshop_in_region") })
    } else if(status != REQUEST_TIMEOUT && status != REQUEST_NETWORK_ERROR) {
      logerr($"nswitch: eshop: error occur: group={err.group}, code={err.code}, status={status}")
    }
  }
})

//on initialize it will request items list and send it to nswitch.eshop.onItemsRequested
initialize()

return {
  platformGoodsDebugInfo = products
  platformGoods
  platformOffer
  platformSubs = Watched({})
  buyPlatformGoods
  platformPurchaseInProgress
  vatMsg
}
