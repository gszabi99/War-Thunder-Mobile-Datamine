from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/initialState.nut" import isOfflineMenu
from "%appGlobals/config/currencyPresentation.nut" import getBaseCurrency
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/seasonCurrencies.nut" import sortByCurrencyId
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_CURRENCY
from "%rGui/event/eventLocName.nut" import mkEventLocComp
from "%rGui/event/eventLootboxes.nut" import eventLootboxesRaw
from "%rGui/event/eventState.nut" import getEventPresentationId, eventSeason, allSpecialEvents, MAIN_EVENT_ID,
  isEventActive
from "%rGui/shop/shopState.nut" import allShopGoods, finishedGoodsByTime, inactiveGoodsByTime, soonGoodsByTime,
  shopGoods
from "%rGui/unlocks/unlocks.nut" import activeUnlocks, allUnlocksDesc, hasUnlockReward
from "types" import Integer


let currencyIdToOpen = mkWatched(persist, "currencyIdToOpen", null)

let parentEventName = Computed(function() {
  let cId = currencyIdToOpen.get()
  if (cId == null)
    return null

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
  
  foreach (s in shopGoods.get())
    if ("event_id" in s.meta
        && (s.price.currencyId == cId || null != s.rewards.findvalue(@(g) g.id == cId && g.gType == G_CURRENCY)))
      return s.meta.event_id

  
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

let currencyId = Computed(@() (parentEventName.get() != null || isParentEventActive.get()) ? currencyIdToOpen.get() : null)
let currencyWndOpenCount = Computed(function(prev) {
  if (currencyId.get() == null)
    return 0
  return prev instanceof Integer ? prev + 1 : 1
})

let isGoodsFit = @(goods, cId)
  goods.rewards.len() == 1 && goods.rewards[0].gType == G_CURRENCY && goods.rewards[0].id == cId

let eventCurrenciesGoods = Computed(function() {
  if (currencyId.get() == null)
    return {}
  let cId = currencyId.get()
  let exclude = finishedGoodsByTime.get()
  let notStarted = inactiveGoodsByTime.get()
  let soon = soonGoodsByTime.get()
  return allShopGoods.get().filter(@(g, id) isGoodsFit(g, cId) && id not in exclude
    && (g.id not in notStarted || g.id in soon))
})

let buyCurrencyWndGamercardCurrencies = Computed(function() {
  let priceCurrencies = eventCurrenciesGoods.get()
    .reduce(@(res, v) res.$rawset(v.price.currencyId, true), {})
    .keys()
  priceCurrencies.sort(@(a, b) sortByCurrencyId(b, a)) 
  return (currencyId.get() == null ? [] : [ currencyId.get() ]).extend(priceCurrencies)
})

let bgImage = Computed(@()
  getEventPresentation(
    getEventPresentationId(parentEventId.get(), eventSeason.get(), allSpecialEvents.get()) ?? parentEventName.get() ?? currencyId.get()
  ).bg)
let parentEventLoc = mkEventLocComp(parentEventId)

function openBuyEventCurrenciesWnd(id) {
  if (isOfflineMenu)
    openFMsgBox({ text = "Not supported in the offline mode" })
  else
    currencyIdToOpen.set(getBaseCurrency(id))
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
