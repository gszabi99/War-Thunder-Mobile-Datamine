from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { isDownloadedFromGooglePlay = @() false } = require("android.platform")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { msgBoxBg, msgBoxHeaderWithClose, msgBoxText, mkMsgBoxBtnsSet, wndWidthDefault, wndHeight
} = require("%rGui/components/msgBox.nut")

let INGAME_PURCHASES_IN_RUSSIA_URL = "auto_local auto_login https://wtmobile.com/premium-webmagazin"
let paymentDisabledInRussiaCurrencies = [ "rub", "byn" ]

const WND_UID = "inAppPurchasesRussiaWnd"
let close = @() removeModalWindow(WND_UID)

let function getPlatformGoodsRealCurrencyId(goodsOrId, platformGoodsVal) {
  let goods = type(goodsOrId) == "table" ? goodsOrId : platformGoodsVal?[goodsOrId]
  return goods?.priceExt.currencyId.tolower() ?? ""
}

let isForbiddenPlatformPurchaseFromRussia = isDownloadedFromGooglePlay()
  ? @(goodsOrId, platformGoodsVal)
      paymentDisabledInRussiaCurrencies.contains(getPlatformGoodsRealCurrencyId(goodsOrId, platformGoodsVal))
  : @(...) false

let openReadMoreUrl = @() send("openUrl", { baseUrl = INGAME_PURCHASES_IN_RUSSIA_URL })

let wndComp = bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = @() null
  animations = wndSwitchAnim
  children = msgBoxBg.__merge({
    size = [ wndWidthDefault, wndHeight ]
    flow = FLOW_VERTICAL
    children = [
      msgBoxHeaderWithClose(null, close)
      {
        size = flex()
        flow = FLOW_VERTICAL
        padding = [ 0, buttonsHGap, buttonsHGap, buttonsHGap ]
        children = [
          msgBoxText(loc("msg/inAppPurchasesInRussia"))
          {
            size = [ flex(), SIZE_TO_CONTENT ]
            halign = ALIGN_CENTER
            children = mkMsgBoxBtnsSet(WND_UID, [{
                id = "readMoreOnline"
                cb = openReadMoreUrl
                styleId = "PRIMARY"
                isDefault = true
              }])
          }
        ]
      }
    ]
  })
})

let function openMsgBoxInAppPurchasesFromRussia() {
  close()
  addModalWindow(wndComp)
  return WND_UID
}

return {
  isForbiddenPlatformPurchaseFromRussia
  openMsgBoxInAppPurchasesFromRussia
}
