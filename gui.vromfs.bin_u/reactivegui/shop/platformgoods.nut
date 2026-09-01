from "%globalsDarg/darg_library.nut" import *
from "auth_wt" import getCountryCode
from "console" import register_command
from "eventbus" import eventbus_send
from "%sqstd/platform.nut" import is_android, is_ios, is_nswitch
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/permissions.nut" import can_use_alternative_payment_ios_usa
from "%rGui/account/emailRegistrationState.nut" import isGuestLogin, renewGuestRegistrationTags
from "%rGui/account/linkEmailForGaijinLogin.nut" import canLinkEmailForGaijinLogin, openLinkEmailForGaijinLogin
from "%rGui/shop/inAppPurchasesFromRussia.nut" import isForbiddenPlatformPurchaseFromRussia,
  needShowMsgBoxInAppPurchasesRussia, openMsgBoxInAppPurchasesFromRussia
import "%rGui/shop/platformGoodsSpecialWnd.nut" as goodsToPaySpecialWnd
from "types" import Table


let { isDownloadedFromGooglePlay = @() false, getBuildMarket = @() "googleplay" } = require("android.platform")
let isHuaweiBuild = getBuildMarket() == "appgallery"
let { platformGoods, platformOffer, platformSubs, platformGoodsDebugInfo, buyPlatformGoods,
  activatePlatfromSubscription = @(_) null,
  platformPurchaseInProgress = Watched(null)
  changeSubscription = null 
  restorePurchases = null
  checkSubscriptionsDebug = @() null
} = is_android && isHuaweiBuild ? require("%rGui/shop/byPlatform/goodsHuawei.nut")
  : is_android && isDownloadedFromGooglePlay() ? require("%rGui/shop/byPlatform/goodsAndroid.nut")
  : is_ios ? require("%rGui/shop/byPlatform/goodsIos.nut")
  : is_nswitch ? require("%rGui/shop/byPlatform/goodsNSwitch.nut")
  : require("%rGui/shop/byPlatform/goodsGaijin.nut")
let { platformGoodsFromRussia = Watched(null) } = is_android && isDownloadedFromGooglePlay() ? require("%rGui/shop/byPlatform/goodsGaijin.nut") : null

let listSpecialWndCountry = ["US"]

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

function buyFromRussia(goods){
  if(needShowMsgBoxInAppPurchasesRussia.get())
    openMsgBoxInAppPurchasesFromRussia(goods)
  else{
    local goodsRuss = platformGoodsFromRussia.get()?[goods.id] ??
      platformGoodsFromRussia.get()?[goods.relatedGaijinId]
    local baseUrl = goodsRuss?.purchaseUrl
    if (baseUrl == null)
      return

    if (canLinkEmailForGaijinLogin.get()) {
      openFMsgBox({
        text = "".concat(loc("mainmenu/ru_google_play_link_email"), "\n", loc("mainmenu/desc/link_to_gaijin_account"))
        buttons = [
          { id = "cancel", isCancel = true }
          { id = "linkEmail", eventId = "openLinkEmailForGaijinLogin", styleId = "PRIMARY", isDefault = true }
        ]
      })
      return
    }
    baseUrl = " ".concat("auto_local", "auto_login", baseUrl)
    eventbus_send("openUrl", { baseUrl, onCloseUrl = "https://store.gaijin.net/success_payment.php" })
  }
}

function buyGoods(goodsOrId) {
  let goods = goodsOrId instanceof Table ? goodsOrId : platformGoods.get()?[goodsOrId]
  if (is_android && !isHuaweiBuild && isForbiddenPlatformPurchaseFromRussia(goods))
    buyFromRussia(goods)
  else if (can_use_alternative_payment_ios_usa.get()
      && is_ios
      && listSpecialWndCountry.contains(getCountryCode())
      && campConfigs.get()?.allGoods[goodsOrId].needShowAlternativePurchase)
    goodsToPaySpecialWnd.set(goodsOrId)
  else
    buyPlatformGoods(goodsOrId)
}

subscribeFMsgBtns({
  buyPlatformGoods = @(context) buyGoods(context.goodsOrId),
  openLinkEmailForGaijinLogin = @(_) openLinkEmailForGaijinLogin()
})

function buyPlatformGoodsExt(goodsOrId) {
  if (isGuestLogin.get()) {
    renewGuestRegistrationTags()
    openFMsgBox({
      text = "".concat(loc("msg/needRegistrationBeforePurchase"), "\n", loc("mainmenu/desc/link_to_gaijin_account"))
      buttons = is_ios || is_android
        ? [
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

  buyGoods(goodsOrId)
}

let isGoodsOnlyInternalPurchase = @(goods) (goods?.purchaseGuids.len() ?? 0) == 0
let changeSubscriptionExt = changeSubscription ?? @(subsTo, _subsFrom) activatePlatfromSubscription(subsTo)

register_command(@() checkSubscriptionsDebug(), "goods.validate_subs")

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
  checkSubscriptionsDebug
}
