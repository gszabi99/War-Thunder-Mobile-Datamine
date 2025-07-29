from "%globalsDarg/darg_library.nut" import *

let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { register_command } = require("console")
let { isDownloadedFromGooglePlay = @() false } = require("android.platform")
let { toIntegerSafe } = require("%sqstd/string.nut")
let { openFMsgBox, subscribeFMsgBtns } = require("%appGlobals/openForeignMsgBox.nut")
let { addGoodsInfoGuids, goodsInfo } = require("byPlatform/gaijinGoodsInfo.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { severalCheckPurchasesOnActivate } = require("%rGui/shop/checkPurchases.nut")
let { addWaitbox, removeWaitbox, waitboxes } = require("%rGui/notifications/waitBox.nut")

let INGAME_PURCHASES_IN_RUSSIA_URL
  = "auto_login https://wtmobile.com/premium-webmagazin?skin_lang=ru"
let INGAME_PURCHASES_IN_RUSSIA_URL_GOODS_ID
  = "auto_login https://wtmobile.com/premium-webmagazin?id={id}&skin_lang=ru" 

let paymentDisabledInRussiaCurrencies = [ "rub", "byn" ].reduce(@(res, v) res.rawset(v, true), {})
let isDebugDisabledCurrency = mkWatched(persist, "isDebugDisabledCurrency", false)

const WND_UID = "inAppPurchasesRussiaWnd"

let getPlatformGoodsRealCurrencyId = @(goods) goods?.priceExt.currencyId.tolower() ?? ""

let isDisabledCurrency = @(goods) getPlatformGoodsRealCurrencyId(goods) in paymentDisabledInRussiaCurrencies
let isForbiddenPlatformPurchaseFromRussia = isDownloadedFromGooglePlay() ? isDisabledCurrency
  : @(goods) isDebugDisabledCurrency.value && isDisabledCurrency(goods)

function getGoodsWebId(guid) {
  let { url = "" } = goodsInfo.get()?[guid]
  if (url == "")
    return null
  let parts = url.split_by_chars("?&")
  let idPart = parts.findvalue(@(v) v.startswith("id="))
  if (idPart == null)
    return null
  let strId = idPart.slice(3)
  return toIntegerSafe(strId, null)
}

function openPurchaseByGuids(guids) {
  local id = null
  foreach(guid in guids) {
    id = getGoodsWebId(guid)
    if (id != null)
      break
  }
  if (id == null)
    return false

  eventbus_send("openUrl", { baseUrl = INGAME_PURCHASES_IN_RUSSIA_URL_GOODS_ID.subst({ id }) })
  severalCheckPurchasesOnActivate()
  return true
}

function openDefaultPurchase() {
  eventbus_send("openUrl", { baseUrl = INGAME_PURCHASES_IN_RUSSIA_URL })
  severalCheckPurchasesOnActivate()
}

subscribeFMsgBtns({
  function openRussiaInAppPurchase(guids) {
    if (!openPurchaseByGuids(guids))
      addWaitbox({
        uid = WND_UID
        text = loc("msgbox/please_wait")
        time = 10
        eventId = "openRussiaInAppPurchase.timeout"
        context = guids
      })
  }
})

eventbus_subscribe("openRussiaInAppPurchase.timeout", function(guids) {
  if (!openPurchaseByGuids(guids))
    openDefaultPurchase()
})

goodsInfo.subscribe(function(_) {
  let wbox = waitboxes.get().findvalue(@(w) w.uid == WND_UID)
  if (wbox == null)
    return
  if (openPurchaseByGuids(wbox.context))
    removeWaitbox(WND_UID)
})

function openMsgBoxInAppPurchasesFromRussia(goods) {
  let { purchaseGuids = {}, relatedGaijinId = "" } = goods
  let relatedGoodsGuid = campConfigs.value?.allGoods[relatedGaijinId].purchaseGuids.gaijin.guid
  let guids = [
    relatedGoodsGuid
    purchaseGuids?.gaijin.guid
    purchaseGuids?.android.guid
  ].filter(@(v) v != null)
  foreach(info in purchaseGuids)
    if (!guids.contains(info.guid))
      guids.append(info.guid)

  addGoodsInfoGuids(guids)

  openFMsgBox({
    uid = WND_UID
    text = loc("msg/inAppPurchasesInRussia")
    viewType = "withWndClose"
    buttons = [{
      id = "readMoreOnline"
      eventId = "openRussiaInAppPurchase"
      context = guids
      styleId = "PRIMARY"
      isDefault = true
    }]
  })
}

register_command(function() {
  isDebugDisabledCurrency(!isDebugDisabledCurrency.value)
  console_print("isDebugDisabledCurrency = ", isDebugDisabledCurrency.value) 
}, "ui.debug.shopDisabledCurrency")

return {
  isForbiddenPlatformPurchaseFromRussia
  openMsgBoxInAppPurchasesFromRussia
}
