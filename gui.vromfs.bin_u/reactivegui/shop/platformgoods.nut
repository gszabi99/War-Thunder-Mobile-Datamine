from "%globalsDarg/darg_library.nut" import *
let { is_android, is_ios } = require("%sqstd/platform.nut")
let { isDownloadedFromGooglePlay = @() false } = require("android.platform")
let { isGuestLogin, renewGuestRegistrationTags } = require("%rGui/account/emailRegistrationState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { allow_online_purchases } = require("%appGlobals/permissions.nut")
let { platformGoods, platformOffer, platformGoodsDebugInfo, buyPlatformGoods,
  platformPurchaseInProgress = Watched(null)
} = is_android && isDownloadedFromGooglePlay() ? require("byPlatform/goodsAndroid.nut")
  : is_ios ? require("byPlatform/goodsIos.nut")
  : require("byPlatform/goodsGaijin.nut")

let function buyPlatformGoodsExt(goodsOrId) {
  if (isGuestLogin.value) {
    renewGuestRegistrationTags()
    openFMsgBox({
      text = loc("msg/needRegistrationBeforePurchase")
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "linkEmail", eventId = "openGuestEmailRegistration", styleId = "PRIMARY", isDefault = true }
      ]
    })
    return
  }

  if (!allow_online_purchases.value) {
    openFMsgBox({ text = loc("msg/purchasesDisabledDuringTest") })
    return
  }

  buyPlatformGoods(goodsOrId)
}

return {
  platformGoods
  platformOffer
  platformGoodsDebugInfo
  buyPlatformGoods = buyPlatformGoodsExt
  platformPurchaseInProgress
}
