from "%globalsDarg/darg_library.nut" import *
let { is_android, is_ios } = require("%sqstd/platform.nut")
let { isDownloadedFromGooglePlay = @() false } = require("android.platform")
let { isGuestLogin, renewGuestRegistrationTags } = require("%rGui/account/emailRegistrationState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { platformGoods, platformOffer, platformGoodsDebugInfo, buyPlatformGoods,
  platformPurchaseInProgress = Watched(null)
} = is_android && isDownloadedFromGooglePlay() ? require("byPlatform/goodsAndroid.nut")
  : is_ios ? require("byPlatform/goodsIos.nut")
  : require("byPlatform/goodsGaijin.nut")
let { isForbiddenPlatformPurchaseFromRussia, openMsgBoxInAppPurchasesFromRussia } = require("inAppPurchasesFromRussia.nut")

if (is_android)
  log("isDownloadedFromGooglePlay = ", isDownloadedFromGooglePlay())

subscribeFMsgBtns({
  buyPlatformGoods = function(context) {
    let { goodsOrId } = context
    buyPlatformGoods(goodsOrId)
  }
})

let function buyPlatformGoodsExt(goodsOrId) {
  if (isGuestLogin.value) {
    renewGuestRegistrationTags()
    openFMsgBox({
      text = loc("msg/needRegistrationBeforePurchase")
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
  if (isForbiddenPlatformPurchaseFromRussia(goods)) {
    openMsgBoxInAppPurchasesFromRussia(goods)
    return
  }

  buyPlatformGoods(goodsOrId)
}

let isGoodsOnlyInternalPurchase = @(goods) (goods?.purchaseGuids.len() ?? 0) == 0
  && (goods?.purchaseGuid ?? "") == "" //compatibility with pserver 0.0.8.x  2023.05.16

return {
  platformGoods
  platformOffer
  platformGoodsDebugInfo
  buyPlatformGoods = buyPlatformGoodsExt
  platformPurchaseInProgress
  isGoodsOnlyInternalPurchase
}
