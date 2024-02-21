from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { getEventBg, getEventLoc, eventSeason, specialEvents, MAIN_EVENT_ID, isEventActive, isMiniEventActive
} = require("%rGui/event/eventState.nut")


let currencyId = mkWatched(persist, "currencyId", null)
let parentEventId = mkWatched(persist, "parentEventId", null)
let isBuyCurrencyWndOpen = Computed(@() currencyId.value != null)

let isParentEventActive = Computed(@() parentEventId.get() == MAIN_EVENT_ID
    ? isEventActive.get()
  : isMiniEventActive.get())

let isGoodsFit = @(goods, cId) (goods.currencies?[cId] ?? 0) > 0
  && goods.currencies.len() == 1
  && goods.units.len() == 0
  && goods.unitUpgrades.len() == 0
  && goods.items.len() == 0

let isGoodsFitOld = @(goods, cId) (goods?[cId] ?? 0) > 0

let eventCurrenciesGoods = Computed(function() {
  let c = currencyId.get()
  return shopGoods.get().filter(
    @(g) "currencies" in g ? isGoodsFit(g, c) : isGoodsFitOld(g, c)) //compatibility with format before 2024.01.23
})

let bgFallback = "ui/images/event_bg.avif"
let bgImage = Computed(@() getEventBg(parentEventId.get(), eventSeason.get(), specialEvents.get(), bgFallback))
let parentEventLoc = Computed(@() getEventLoc(parentEventId.get(), eventSeason.get(), specialEvents.get()))

function openBuyEventCurrenciesWnd(id, eventId) {
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
  isParentEventActive

  eventCurrenciesGoods

  bgFallback
  bgImage
  parentEventLoc
}
