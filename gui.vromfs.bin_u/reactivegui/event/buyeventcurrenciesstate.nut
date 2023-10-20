from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { scenesOrder } = require("%rGui/navState.nut")
let { WARBOND, EVENT_KEY } = require("%appGlobals/currenciesState.nut")


let openParams = mkWatched(persist, "openParams", null)
let currencyId = Computed(@() openParams.value?.currencyId)
let isBuyCurrencyWndOpen = Computed(@() openParams.value?.isEmbedded == false)
let isEmbeddedBuyCurrencyWndOpen = Computed(@() openParams.value?.isEmbedded == true)

let eventCurrenciesGoods = Computed(@() shopGoods.value?.filter(@(v) (v?[currencyId.value] ?? 0) > 0) ?? {})

let function openBuyEventCurrenciesWnd(id) {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  openParams({
    currencyId = id,
    isEmbedded = scenesOrder.value.findindex(@(v) v == "eventWnd") == (scenesOrder.value.len() - 1)
  })
}

return {
  isBuyCurrencyWndOpen
  isEmbeddedBuyCurrencyWndOpen
  closeBuyEventCurrenciesWnd = @() openParams(null)
  openBuyWarbondsWnd = @() openBuyEventCurrenciesWnd(WARBOND)
  openBuyEventKeysWnd = @() openBuyEventCurrenciesWnd(EVENT_KEY)
  currencyId

  eventCurrenciesGoods
}
