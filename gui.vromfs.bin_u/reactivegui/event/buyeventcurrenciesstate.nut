from "%globalsDarg/darg_library.nut" import *
let { sortByCurrencyId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { allShopGoods, finishedGoodsByTime, inactiveGoodsByTime } = require("%rGui/shop/shopState.nut")
let { getEventPresentationId, getEventLoc, eventSeason, allSpecialEvents, MAIN_EVENT_ID, isEventActive
} = require("%rGui/event/eventState.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { G_CURRENCY } = require("%appGlobals/rewardType.nut")
let { activeUnlocks, allUnlocksDesc, hasUnlockReward } = require("%rGui/unlocks/unlocks.nut")
let { eventLootboxesRaw } = require("eventLootboxes.nut")


let currencyIdToOpen = mkWatched(persist, "currencyIdToOpen", null)

let parentEventName = Computed(function() {
  let cId = currencyIdToOpen.get()
  foreach(lbox in eventLootboxesRaw.get())
    if (lbox.currencyId == cId)
      return lbox?.meta.event_id ?? MAIN_EVENT_ID

  let rewards = (serverConfigs.get()?.userstatRewards ?? {})
    .filter(@(list) null != list.findvalue(@(g) g.id == cId && g.gType == G_CURRENCY))
  let isFit = @(rId) rId in rewards
  let activeUnlocksV = activeUnlocks.get()
  
  foreach(u in activeUnlocksV) {
    let { event_id = null } = u?.meta
    if (event_id != null && hasUnlockReward(u, isFit))
      return event_id
  }
  
  foreach(name, u in allUnlocksDesc.get()) {
    if (name in activeUnlocksV)
      continue
    let { event_id = null } = u?.meta
    if (event_id != null && hasUnlockReward(u, isFit))
      return event_id
  }
  return null
})

let parentEventId = Computed(function() {
  let name = parentEventName.get()
  return name == null ? null
    : name == MAIN_EVENT_ID ? MAIN_EVENT_ID
    : allSpecialEvents.get().findindex(@(e) e.eventName == name)
})
let isParentEventActive = Computed(@() parentEventId.get() == MAIN_EVENT_ID ? isEventActive.get()
  : parentEventId.get() != null)
let currencyId = Computed(@() (parentEventName.get() == null || isParentEventActive.get()) ? currencyIdToOpen.get() : null)
let currencyWndOpenCount = Computed(function(prev) {
  if (currencyId.get() == null)
    return 0
  return type(prev) == "integer" ? prev + 1 : 1
})

let isGoodsFit = @(goods, cId) (goods.currencies?[cId] ?? 0) > 0
  && goods.currencies.len() == 1
  && goods.units.len() == 0
  && goods.unitUpgrades.len() == 0
  && goods.items.len() == 0

let eventCurrenciesGoods = Computed(function() {
  if (currencyId.get() == null)
    return {}
  let cId = currencyId.get()
  let exclude = finishedGoodsByTime.get()
  let notStarted = inactiveGoodsByTime.get()
  return allShopGoods.get().filter(@(g, id) isGoodsFit(g, cId) && id not in exclude
    && (!!g.meta?.isNeedPrew || g.id not in notStarted))
})

let buyCurrencyWndGamercardCurrencies = Computed(function() {
  let priceCurrencies = eventCurrenciesGoods.get()
    .reduce(@(res, v) res.$rawset(v.price.currencyId, true), {})
    .keys()
  priceCurrencies.sort(@(a, b) sortByCurrencyId(b, a)) 
  return [ currencyId.get() ].extend(priceCurrencies)
})

let bgImage = Computed(@()
  getEventPresentation(
    getEventPresentationId(parentEventId.get(), eventSeason.get(), allSpecialEvents.get()) ?? currencyId.get()
  ).bg)
let parentEventLoc = Computed(@() getEventLoc(parentEventId.get(), eventSeason.get(), allSpecialEvents.get()))

function openBuyEventCurrenciesWnd(id) {
  if (isOfflineMenu)
    openFMsgBox({ text = "Not supported in the offline mode" })
  else
    currencyIdToOpen.set(id)
}

return {
  currencyWndOpenCount
  closeBuyEventCurrenciesWnd = @() currencyIdToOpen.set(null)
  openBuyEventCurrenciesWnd
  currencyId
  parentEventId

  eventCurrenciesGoods
  buyCurrencyWndGamercardCurrencies

  bgImage
  parentEventLoc
}
