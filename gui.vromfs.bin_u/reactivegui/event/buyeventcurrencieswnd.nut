from "%globalsDarg/darg_library.nut" import *
let { isBuyCurrencyWndOpen, closeBuyEventCurrenciesWnd, isParentEventActive, bgImage, bgFallback
} = require("buyEventCurrenciesState.nut")
let { registerScene, setSceneBgFallback, setSceneBg } = require("%rGui/navState.nut")
let { buyEventCurrenciesHeader, mkEventCurrenciesGoods, buyEventCurrenciesGamercard,
  buyEventCurrenciesDesc } = require("buyEventCurrenciesComps.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")


isParentEventActive.subscribe(@(isActive) isActive ? null : closeBuyEventCurrenciesWnd())

let buyEventCurrenciesWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    buyEventCurrenciesGamercard
    {
      size = flex()
      flow = FLOW_VERTICAL
      valign = ALIGN_CENTER
      children = [
        buyEventCurrenciesHeader
        mkEventCurrenciesGoods
        buyEventCurrenciesDesc
      ]
    }
  ]
  animations = wndSwitchAnim
}

let sceneId = "buyEventCurrenciesWnd"
registerScene("buyEventCurrenciesWnd", buyEventCurrenciesWnd, closeBuyEventCurrenciesWnd, isBuyCurrencyWndOpen)
setSceneBgFallback(sceneId, bgFallback)
setSceneBg(sceneId, bgImage.get())
bgImage.subscribe(@(v) setSceneBg(sceneId, v))
