from "%globalsDarg/darg_library.nut" import *
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { allShopGoods } = require("%rGui/shop/shopState.nut")
let { getEventBg, getEventLoc, eventSeason, specialEvents, MAIN_EVENT_ID, isEventActive
} = require("%rGui/event/eventState.nut")


let currencyId = mkWatched(persist, "currencyId", null)
let parentEventId = mkWatched(persist, "parentEventId", null)
let isBuyCurrencyWndOpen = Computed(@() currencyId.get() != null)

let isParentEventActive = Computed(@() parentEventId.get() == MAIN_EVENT_ID ? isEventActive.get()
  : parentEventId.get() in specialEvents.get())

let isGoodsFit = @(goods, cId) (goods.currencies?[cId] ?? 0) > 0
  && goods.currencies.len() == 1
  && goods.units.len() == 0
  && goods.unitUpgrades.len() == 0
  && goods.items.len() == 0

let eventCurrenciesGoods = Computed(@() allShopGoods.get().filter(@(g) isGoodsFit(g, currencyId.get())))

let buyCurrencyWndGamercardCurrencies = Computed(function() {
  let priceCurrencies = eventCurrenciesGoods.get()
    .reduce(@(res, v) res.$rawset(v.price.currencyId, true), {})
    .keys()
  priceCurrencies.sort(@(a, b) (orderByCurrency?[b] ?? 0) <=> (orderByCurrency?[a] ?? 0))
  return [ currencyId.get() ].extend(priceCurrencies)
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
  buyCurrencyWndGamercardCurrencies

  bgFallback
  bgImage
  parentEventLoc
}
