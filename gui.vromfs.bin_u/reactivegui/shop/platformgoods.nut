from "%globalsDarg/darg_library.nut" import *
let { is_android, is_ios, is_nswitch } = require("%sqstd/platform.nut")
let { isDownloadedFromGooglePlay = @() false, getBuildMarket = @() "googleplay" } = require("android.platform")
let { isGuestLogin, renewGuestRegistrationTags } = require("%rGui/account/emailRegistrationState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let isHuaweiBuild = getBuildMarket() == "appgallery"
let { platformGoods, platformOffer, platformSubs, platformGoodsDebugInfo, buyPlatformGoods,
  activatePlatfromSubscription = @(_) null,
  platformPurchaseInProgress = Watched(null)
  changeSubscription = null 
  restorePurchases = null
} = is_android && isHuaweiBuild ? require("byPlatform/goodsHuawei.nut")
  : is_android && isDownloadedFromGooglePlay() ? require("byPlatform/goodsAndroid.nut")
  : is_ios ? require("byPlatform/goodsIos.nut")
  : is_nswitch ? require("byPlatform/goodsNSwitch.nut")
  : require("byPlatform/goodsGaijin.nut")
let { platformGoodsFromRussia = Watched(null) } = is_android && isDownloadedFromGooglePlay() ? require("byPlatform/goodsGaijin.nut") : null
let { isForbiddenPlatformPurchaseFromRussia, openMsgBoxInAppPurchasesFromRussia } = require("inAppPurchasesFromRussia.nut")
let { has_payments_blocked_web_page } = require("%appGlobals/permissions.nut")
let { eventbus_send } = require("eventbus")

if (is_android)
  log("isDownloadedFromGooglePlay = ", isDownloadedFromGooglePlay())

let wasGoodsLogged = mkWatched(persist, "wasGoodsLogged", false)
platformGoods.subscribe(function(list) {
  if (wasGoodsLogged.get())
    return
  let goods = list.findvalue(@(g) (g?.priceExt.price ?? 0) > 0)
  if (goods == null)
    return
  log("[GOODS] platform goods example: ", goods)
  wasGoodsLogged.set(true)
})

subscribeFMsgBtns({
  buyPlatformGoods = function(context) {
    let { goodsOrId } = context
    buyPlatformGoods(goodsOrId)
  }
})

function buyPlatformGoodsExt(goodsOrId) {
  if (isGuestLogin.value) {
    renewGuestRegistrationTags()
    openFMsgBox({
      text = "".concat(loc("msg/needRegistrationBeforePurchase"), "\n", loc("mainmenu/desc/link_to_gaijin_account"))
      buttons = is_ios ? [
          { id = "cancel", isCancel = true }
          { id = "purchaseAsGuest", eventId = "buyPlatformGoods", styleId = "PURCHASE" context = { goodsOrId } }
          { id = "linkEmail", eventId = "openGuestEmailRegistration", styleId = "PRIMARY", isDefault = true }
        ]
        : [
          { id = "cancel", isCancel = true }
          { id = "linkEmail", eventId = "openGuestEmailRegistration", styleId = "PRIMARY", isDefault = true }
        ]
    })
    return
  }
  let goods = type(goodsOrId) == "table" ? goodsOrId : platformGoods.value?[goodsOrId]
  if (is_android && !isHuaweiBuild && isForbiddenPlatformPurchaseFromRussia(goods)) {
    if(has_payments_blocked_web_page.get())
      openMsgBoxInAppPurchasesFromRussia(goods)
    else{
      local goodsRuss = platformGoodsFromRussia.value?[goodsOrId] ??
        platformGoodsFromRussia.value?[goods.relatedGaijinId]
      local baseUrl = goodsRuss?.purchaseUrl
      if (baseUrl == null)
        return
      baseUrl = " ".concat("auto_local", "auto_login", baseUrl)
      eventbus_send("openUrl", { baseUrl, onCloseUrl = "https://store.gaijin.net/success_payment.php" })
    }
    return
  }

  buyPlatformGoods(goodsOrId)
}

let isGoodsOnlyInternalPurchase = @(goods) (goods?.purchaseGuids.len() ?? 0) == 0
let changeSubscriptionExt = changeSubscription ?? @(subsTo, _subsFrom) activatePlatfromSubscription(subsTo)

return {
  platformGoods
  platformOffer
  platformSubs
  platformGoodsDebugInfo
  buyPlatformGoods = buyPlatformGoodsExt
  changeSubscription = changeSubscriptionExt
  activatePlatfromSubscription
  platformPurchaseInProgress
  isGoodsOnlyInternalPurchase
  hasRestorePurchases = restorePurchases != null
  restorePurchases = restorePurchases ?? @() null
}
