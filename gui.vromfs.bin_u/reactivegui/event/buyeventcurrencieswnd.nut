from "%globalsDarg/darg_library.nut" import *
let { isBuyCurrencyWndOpen, closeBuyEventCurrenciesWnd } = require("buyEventCurrenciesState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { mkSmokeBg } = require("eventPkg.nut")
let { buyEventCurrenciesHeader, mkEventCurrenciesGoods, buyEventCurrenciesGamercard } = require("buyEventCurrenciesComps.nut")


let buyEventCurrenciesWnd = {
  key = {}
  size = flex()
  children = [
    mkSmokeBg(isBuyCurrencyWndOpen)
    {
      padding = saBordersRv
      flow = FLOW_VERTICAL
      children = [
        buyEventCurrenciesGamercard
        buyEventCurrenciesHeader
        mkEventCurrenciesGoods
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("buyEventCurrenciesWnd", buyEventCurrenciesWnd, closeBuyEventCurrenciesWnd, isBuyCurrencyWndOpen)
