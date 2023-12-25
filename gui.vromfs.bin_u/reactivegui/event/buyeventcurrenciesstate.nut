from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { getEventBg, getEventLoc, eventSeason, specialEvents } = require("%rGui/event/eventState.nut")


let currencyId = mkWatched(persist, "currencyId", null)
let parentEventId = mkWatched(persist, "parentEventId", null)
let isBuyCurrencyWndOpen = Computed(@() currencyId.value != null)

let eventCurrenciesGoods = Computed(@() shopGoods.value?.filter(@(v) (v?[currencyId.value] ?? 0) > 0) ?? {})

let bgFallback = "ui/images/event_bg.avif"
let bgImage = Computed(@() getEventBg(parentEventId.get(), eventSeason.get(), specialEvents.get(), bgFallback))
let parentEventLoc = Computed(@() getEventLoc(parentEventId.get(), eventSeason.get(), specialEvents.get()))

let function openBuyEventCurrenciesWnd(id, eventId) {
  if (isOfflineMenu)
    openFMsgBox({ text = "Not supported in the offline mode" })
  else {
    currencyId.set(id)
    parentEventId.set(eventId)
  }
}

return {
  isBuyCurrencyWndOpen
  closeBuyEventCurrenciesWnd = @() currencyId(null)
  openBuyEventCurrenciesWnd
  currencyId
  parentEventId

  eventCurrenciesGoods

  bgFallback
  bgImage
  parentEventLoc
}
