from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/eventSeasonPresentation.nut" import eventBgFallback
from "%rGui/event/buyEventCurrenciesComps.nut" import mkEventCurrenciesGoods, buyEventCurrenciesGamercard,
  buyEventCurrenciesDesc
from "%rGui/event/buyEventCurrenciesState.nut" import currencyWndOpenCount, closeBuyEventCurrenciesWnd, bgImage
from "%rGui/navState.nut" import registerScene, setSceneBgFallback, setSceneBg
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let buyEventCurrenciesWnd = @() {
  key = {}
  size = FLEX
  padding = saBordersRv
  rendObj = ROBJ_SOLID
  color = 0x80000000
  flow = FLOW_VERTICAL
  children = [
    buyEventCurrenciesGamercard
    {
      size = FLEX
      flow = FLOW_VERTICAL
      valign = ALIGN_CENTER
      children = [
        mkEventCurrenciesGoods()
        buyEventCurrenciesDesc
      ]
    }
  ]
  animations = wndSwitchAnim
}

const sceneId = "buyEventCurrenciesWnd"
registerScene("buyEventCurrenciesWnd", buyEventCurrenciesWnd, closeBuyEventCurrenciesWnd, currencyWndOpenCount)
setSceneBgFallback(sceneId, eventBgFallback)
setSceneBg(sceneId, bgImage.get())
bgImage.subscribe(@(v) setSceneBg(sceneId, v))
