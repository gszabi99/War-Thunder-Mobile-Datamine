from "%globalsDarg/darg_library.nut" import *
let { currencyWndOpenCount, closeBuyEventCurrenciesWnd, bgImage
} = require("%rGui/event/buyEventCurrenciesState.nut")
let { registerScene, setSceneBgFallback, setSceneBg } = require("%rGui/navState.nut")
let { buyEventCurrenciesHeader, mkEventCurrenciesGoods, buyEventCurrenciesGamercard,
  buyEventCurrenciesDesc } = require("%rGui/event/buyEventCurrenciesComps.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { eventBgFallback } = require("%appGlobals/config/eventSeasonPresentation.nut")


let buyEventCurrenciesWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  rendObj = ROBJ_SOLID
  color = 0x80000000
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
registerScene("buyEventCurrenciesWnd", buyEventCurrenciesWnd, closeBuyEventCurrenciesWnd, currencyWndOpenCount)
setSceneBgFallback(sceneId, eventBgFallback)
setSceneBg(sceneId, bgImage.get())
bgImage.subscribe(@(v) setSceneBg(sceneId, v))
