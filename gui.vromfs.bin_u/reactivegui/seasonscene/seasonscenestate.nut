from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { getOPPresentation } = require("%appGlobals/config/passPresentation.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { openEventInfo, specialEvents, MAIN_EVENT_ID, curEvent, eventWndOpenCounter, subEventsList,
  specialEventsOrdered, isEventActive, getIsEventActive, getEventLootboxes, closeEventShellCleanup, closeEventWnd,
  getEventPresentationId, eventSeason, allSpecialEvents, specialEventsWithTree
} = require("%rGui/event/eventState.nut")
let shouldShowEventMechanics = require("%rGui/event/shouldShowEventMechanics.nut")
let { eventLootboxesRaw } = require("%rGui/event/eventLootboxes.nut")
let { openTreeEventWnd } = require("%rGui/event/treeEvent/treeEventState.nut")
let { separateEventModes } = require("%rGui/gameModes/gameModeState.nut")
let { eventsPassList } = require("%rGui/battlePass/eventPassState.nut")
let { bpProgressUnlock } = require("%rGui/battlePass/battlePassState.nut")
let { isOPSeasonActive, OP_EVENT_ID, OPCampaign } = require("%rGui/battlePass/operationPassState.nut")
let { playerSelectedScene, getVisibleTabs } = require("%rGui/battlePass/passState.nut")
let { tabIdToOpen, questsCfg, questsBySection } = require("%rGui/quests/questsState.nut")
let { openShopWndByGoods, getGoodsShopId, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop,
  personalGoodsByShop
} = require("%rGui/shop/shopState.nut")
let { getShopIdForEventId } = require("%rGui/shop/eventShopState.nut")
let { COMMON_TAB, EVENT_TAB, PERSONAL_TAB, ACHIEVEMENTS_TAB, PROMO_TAB } = require("%rGui/unlocks/unlocksConst.nut")


let PASS_SCENE = "pass_scene"
let QUESTS_TAB = "quests_tab"
let EVENT_SHOP_TAB = "event_shop_tab"
let LOOTBOX_TAB = "lootbox_tab"
let BATTLE_TAB = "battle"

let playerSelectedSeasonTab = mkWatched(persist, "playerSelectedSeasonTab", PASS_SCENE)
let seasonSceneOpenCounter = mkWatched(persist, "seasonSceneOpenCounter", 0)

let seasonTabs = [ BATTLE_TAB, PASS_SCENE, QUESTS_TAB, EVENT_SHOP_TAB, LOOTBOX_TAB ]

let questTabsByEventId = {
  [""] = [ ACHIEVEMENTS_TAB, PROMO_TAB ],
  [MAIN_EVENT_ID] = [ COMMON_TAB, EVENT_TAB, ACHIEVEMENTS_TAB, PROMO_TAB ],
  [OP_EVENT_ID] = [ PERSONAL_TAB ],
}

let seasonTabIdx = Computed(@() seasonTabs.indexof(playerSelectedSeasonTab.get()) ?? 0)
let seasonPageId = Computed(@() seasonTabs?[seasonTabIdx.get()])

let seasonShopId = Computed(@() getShopIdForEventId(curEvent.get(), specialEvents.get(),
  goodsByShop.get(), soonGoodsByShop.get(), soonPersonalGoodsByShop.get(), personalGoodsByShop.get()))

function isQuestsTabVisible(eventId, qCfg, qBySection) {
  let tabsList = questTabsByEventId?[eventId] ?? [eventId]
  foreach (tabId in tabsList)
    if (qCfg?[tabId].findindex(@(s) qBySection[s].len() > 0) != null)
      return true
  return false
}

let isShopTabVisible = @(sId, goodsByShopV, soonGoodsByShopV, soonPersonalGoodsByShopV, personalGoodsByShopV)
  sId != null
    && 0 < (goodsByShopV[sId].len() + soonGoodsByShopV[sId].len() + soonPersonalGoodsByShopV[sId].len()
      + personalGoodsByShopV[sId].len())

let isLootboxTabVisible = @(eventId, isEActive, isOActive, specEvents, lootboxesRaw)
  getIsEventActive(eventId, isEActive, isOActive, specEvents)
    && getEventLootboxes(eventId, lootboxesRaw).len() > 0

let isBattleVisible = @(eventId, separateEventModesV, specialEventsV)
  eventId in separateEventModesV || specialEventsV?[eventId].eventName in separateEventModesV

let isSeasonTabVisible = {
  [PASS_SCENE] = {
    calcByEventId = @(id) shouldShowEventMechanics.get()
      && getVisibleTabs(id, bpProgressUnlock.get(), eventsPassList.get(), subEventsList.get()).len() > 0
    watched = Computed(@() shouldShowEventMechanics.get()
      && getVisibleTabs(curEvent.get(), bpProgressUnlock.get(), eventsPassList.get(), subEventsList.get()).len() > 0)
  },
  [QUESTS_TAB] = {
    calcByEventId = @(id) isQuestsTabVisible(id, questsCfg.get(), questsBySection.get()),
    watched = Computed(@() isQuestsTabVisible(curEvent.get(), questsCfg.get(), questsBySection.get()))
  },
  [EVENT_SHOP_TAB] = {
    calcByEventId = @(id) shouldShowEventMechanics.get()
      && isShopTabVisible(
        getShopIdForEventId(id, specialEvents.get(), goodsByShop.get(), soonGoodsByShop.get(),
          soonPersonalGoodsByShop.get(), personalGoodsByShop.get()),
        goodsByShop.get(), soonGoodsByShop.get(),
        soonPersonalGoodsByShop.get(), personalGoodsByShop.get())
    watched = Computed(@() shouldShowEventMechanics.get()
      && isShopTabVisible(seasonShopId.get(), goodsByShop.get(), soonGoodsByShop.get(),
        soonPersonalGoodsByShop.get(), personalGoodsByShop.get()))
  },
  [LOOTBOX_TAB] = {
    calcByEventId = @(id) shouldShowEventMechanics.get()
      && isLootboxTabVisible(id, isEventActive.get(), isOPSeasonActive.get(), specialEvents.get(),
        eventLootboxesRaw.get()),
    watched = Computed(@() shouldShowEventMechanics.get()
      && isLootboxTabVisible(curEvent.get(), isEventActive.get(), isOPSeasonActive.get(), specialEvents.get(),
        eventLootboxesRaw.get()))
  },
  [BATTLE_TAB] = {
    calcByEventId = @(id) shouldShowEventMechanics.get()
      && isBattleVisible(id, separateEventModes.get(), specialEvents.get())
    watched = Computed(@() shouldShowEventMechanics.get()
      && isBattleVisible(curEvent.get(), separateEventModes.get(), specialEvents.get()))
  }
}

let bgUnits = Computed(@() seasonPageId.get() != BATTLE_TAB ? null
  : getEventPresentation(curEvent.get()).bgUnits)

let bgScene = Computed(function() {
  let eventId = curEvent.get()
  if (eventId == OP_EVENT_ID)
    return getOPPresentation(OPCampaign.get())
  if (eventId == "")
    return getEventPresentation(getEventPresentationId(MAIN_EVENT_ID, eventSeason.get(), allSpecialEvents.get()))
  return getEventPresentation(getEventPresentationId(eventId, eventSeason.get(), allSpecialEvents.get()))
})

let hasBattleTab = isSeasonTabVisible[BATTLE_TAB].watched
let newsTag = Computed(@() hasBattleTab.get() ? curEvent.get() : null)

let openSeasonTab = @(id) playerSelectedSeasonTab.set(id)

let seasonTabCloseHandlers = {}

function registerSeasonTabClose(tabId, fn) {
  seasonTabCloseHandlers[tabId] <- fn
}

function openSeasonScene(eventName, tabIdRaw = null, subId = null) {
  eventName = specialEvents.get().findvalue(@(v) v.eventName == eventName)?.eventId ?? eventName
  let prevTab = playerSelectedSeasonTab.get()
  let tabId = isSeasonTabVisible?[tabIdRaw].calcByEventId(eventName) ? tabIdRaw
    : isSeasonTabVisible?[prevTab].calcByEventId(eventName) ? prevTab
    : seasonTabs.findvalue(@(v) isSeasonTabVisible[v].calcByEventId(eventName))
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return null
  }
  if (tabId == null) {
    logerr("Try to open season scene when all tabs are not visible")
    return null
  }

  openEventInfo.set({
    eventName
    counter = curEvent.get() == eventName ? eventWndOpenCounter.get() + 1 : 1
  })

  seasonSceneOpenCounter.set(seasonSceneOpenCounter.get() + 1)
  openSeasonTab(tabId)
  if (tabId == PASS_SCENE && subId != null)
    playerSelectedScene.set(subId)
}

let openMainSeasonScene = @(id = null, subId = null) openSeasonScene(MAIN_EVENT_ID, id, subId)

function closeSeasonScene() {
  let id = playerSelectedSeasonTab.get()
  seasonTabCloseHandlers?[id]()
  closeEventShellCleanup()
  closeEventWnd()
  seasonSceneOpenCounter.set(0)
}

function openQuestsWndOnTab(tabId) {
  let tabToOpen = tabId in questsCfg.get() ? tabId
    : (specialEvents.get().findindex(@(s) s.eventName == tabId) ?? tabId)

  local eventName = tabToOpen
  if (tabToOpen == null || specialEventsOrdered.get().findvalue(@(item) item.eventId == tabToOpen) == null)
    eventName = MAIN_EVENT_ID
  tabIdToOpen.set(tabToOpen)
  openSeasonScene(eventName, QUESTS_TAB)
}

let openEventShopWnd = @(eventName) openSeasonScene(eventName, EVENT_SHOP_TAB)

function openShopByGoods(goods) {
  if (getGoodsShopId(goods) == "common")
    return openShopWndByGoods(goods)
  let eventId = goods?.meta?.event_id
  if (eventId == null) {
    logerr("openShopByGoods: goods classified into an event shop bucket but have no meta.event_id")
    return
  }
  openEventShopWnd(eventId)
}

function openGmEventWnd(eventName) {
  if (eventName not in separateEventModes.get())
    return
  let eventId = specialEventsWithTree.get().findindex(@(event) event.eventName == eventName)
  if (eventId != null)
    return openTreeEventWnd(eventId)
  openSeasonScene(eventName)
}

return {
  BATTLE_TAB
  PASS_SCENE
  QUESTS_TAB
  EVENT_SHOP_TAB
  LOOTBOX_TAB
  questTabsByEventId
  isSeasonTabVisible
  playerSelectedSeasonTab
  seasonSceneOpenCounter
  seasonTabs
  seasonTabIdx
  seasonPageId
  seasonShopId

  openSeasonTab
  openSeasonScene
  openMainSeasonScene
  closeSeasonScene
  openQuestsWndOnTab
  openEventShopWnd
  openShopByGoods
  openGmEventWnd
  registerSeasonTabClose
  bgScene
  bgUnits
  newsTag
  isQuestsTabVisible
}
