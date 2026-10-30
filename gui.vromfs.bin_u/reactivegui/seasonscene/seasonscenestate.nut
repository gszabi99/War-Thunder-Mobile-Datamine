from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import isDataBlock, blk2SquirrelObjNoArrays
from "%appGlobals/clientState/initialState.nut" import isOfflineMenu
from "%appGlobals/config/collectionPresentation.nut" import getCollectionPresentation
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/config/passPresentation.nut" import getOPPresentation
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/permissions.nut" import has_leaderboard
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/battlePass/battlePassObsoleteState.nut" import bpProgressUnlock
from "%rGui/battlePass/battlePassState.nut" import activeBattlePassesCfg, curBpId
from "%rGui/battlePass/eventPassState.nut" import eventsPassList
from "%rGui/battlePass/operationPassState.nut" import isOPSeasonActive, OP_EVENT_ID, OPCampaign
from "%rGui/battlePass/passState.nut" import playerSelectedScene, getVisibleTabs
from "%rGui/collections/collectionsState.nut" import curCollectionId, activeCollectionsCfg
from "%rGui/event/eventLootboxes.nut" import eventLootboxesRaw
from "%rGui/event/eventState.nut" import openEventInfo, specialEvents, MAIN_EVENT_ID, curEvent, eventWndOpenCounter,
  subEventsList, specialEventsOrdered, isEventActive, getIsEventActive, getEventLootboxes, closeEventShellCleanup,
  closeEventWnd, getEventPresentationId, eventSeason, allSpecialEvents, specialEventsWithTree
from "%rGui/event/gmEventState.nut" import curGmList, getGameModePresentationByMode
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/event/treeEvent/treeEventState.nut" import hasTreeMap, openedTreeEventId
from "%rGui/gameModes/gameModeState.nut" import separateEventModes
from "%rGui/navState.nut" import scenesOrder
from "%rGui/quests/questsState.nut" import tabIdToOpen, questsCfg, questsBySection
from "%rGui/shop/eventShopState.nut" import getShopIdForEventId
from "%rGui/shop/shopState.nut" import openShopWndByGoods, getGoodsShopId, goodsByShop, soonGoodsByShop,
  soonPersonalGoodsByShop, personalGoodsByShop
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import isTutorialActive
from "%rGui/unlocks/unlocksConst.nut" import COMMON_TAB, EVENT_TAB, PERSONAL_TAB, ACHIEVEMENTS_TAB, PROMO_TAB


const PASS_SCENE = "pass_scene"
const PASS_OBSOLETE_SCENE = "pass_obsolete_scene"
const QUESTS_TAB = "quests_tab"
const EVENT_SHOP_TAB = "event_shop_tab"
const LOOTBOX_TAB = "lootbox_tab"
const MAP_TAB = "map_tab"
const BATTLE_TAB = "battle"
const BATTLE_TAB_2 = "battle_2"
const BATTLE_TAB_3 = "battle_3"
let BATTLE_TAB_MODE_IDX = {
  [BATTLE_TAB] = 0,
  [BATTLE_TAB_2] = 1,
  [BATTLE_TAB_3] = 2,
}
const LEADERBOARD_TAB = "leaderboard_tab"
const COLLECTION_TAB = "collection"

const SEASON_SCENE_ID = "seasonScene"

const SEASON_HELP_WND_SEEN_SAVE_ID = "seasonHelpWndSeen"
let seasonHelpWndSeen = Watched({})

let playerSelectedSeasonTab = mkWatched(persist, "playerSelectedSeasonTab", PASS_OBSOLETE_SCENE)
let seasonSceneOpenCounter = mkWatched(persist, "seasonSceneOpenCounter", 0)
let backToTab = mkWatched(persist, "backToTab", null)

let isSeasonSceneTop = Computed(@() scenesOrder.get()?[scenesOrder.get().len() - 1] == SEASON_SCENE_ID)

let seasonTabs = [ QUESTS_TAB, BATTLE_TAB, BATTLE_TAB_2, BATTLE_TAB_3, MAP_TAB, COLLECTION_TAB,
  PASS_SCENE, PASS_OBSOLETE_SCENE, LOOTBOX_TAB, LEADERBOARD_TAB, EVENT_SHOP_TAB
]
let seasonTabPriority = [ PASS_SCENE, PASS_OBSOLETE_SCENE, QUESTS_TAB, BATTLE_TAB, BATTLE_TAB_2, BATTLE_TAB_3,
  MAP_TAB, COLLECTION_TAB, LOOTBOX_TAB, LEADERBOARD_TAB, EVENT_SHOP_TAB
]

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

function isBattleModeTabVisible(eventId, tabId, separateEventModesV, specialEventsV) {
  let eventName = eventId in separateEventModesV ? eventId : specialEventsV?[eventId].eventName
  let modes = separateEventModesV?[eventName] ?? []
  return modes.len() > BATTLE_TAB_MODE_IDX[tabId]
}

let mkBattleModeTabVisible = @(tabId) {
  calcByEventId = @(id) shouldShowEventMechanics.get()
    && isBattleModeTabVisible(id, tabId, separateEventModes.get(), specialEvents.get())
  watched = Computed(@() shouldShowEventMechanics.get()
    && isBattleModeTabVisible(curEvent.get(), tabId, separateEventModes.get(), specialEvents.get()))
}

let isLeaderboardTabVisible = @(eventId, isEActive, isOActive, specEvents)
  eventId == MAIN_EVENT_ID && getIsEventActive(eventId, isEActive, isOActive, specEvents)

let isSeasonTabVisible = {
  [MAP_TAB] = {
    calcByEventId = @(id) shouldShowEventMechanics.get() && hasTreeMap(id)
    watched = Computed(@() shouldShowEventMechanics.get() && openedTreeEventId.get() != null)
  },
  [PASS_SCENE] = {
    function calcByEventId(id) {
      let eventName = specialEvents.get()?[id].eventName ?? id
      return shouldShowEventMechanics.get()
        && null != activeBattlePassesCfg.get().findvalue(@(c) c.meta?.event_id == eventName)
    }
    watched = Computed(@() shouldShowEventMechanics.get() && curBpId.get() != null)
  },
  [PASS_OBSOLETE_SCENE] = {
    calcByEventId = @(id) shouldShowEventMechanics.get()
      && getVisibleTabs(id, bpProgressUnlock.get(), eventsPassList.get(), subEventsList.get()).len() > 0
    watched = Computed(@() shouldShowEventMechanics.get()
      && getVisibleTabs(curEvent.get(), bpProgressUnlock.get(), eventsPassList.get(), subEventsList.get()).len() > 0)
  },
  [QUESTS_TAB] = {
    calcByEventId = @(id) isQuestsTabVisible(id, questsCfg.get(), questsBySection.get()),
    watched = Computed(@() isQuestsTabVisible(curEvent.get(), questsCfg.get(), questsBySection.get()))
  },
  [COLLECTION_TAB] = {
    function calcByEventId(id) {
      let eventName = specialEvents.get()?[id].eventName ?? id
      return shouldShowEventMechanics.get()
        && null != activeCollectionsCfg.get().findvalue(@(c) c.meta?.event_id == eventName)
    }
    watched = Computed(@() shouldShowEventMechanics.get() && curCollectionId.get() != null)
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
  [BATTLE_TAB] = mkBattleModeTabVisible(BATTLE_TAB),
  [BATTLE_TAB_2] = mkBattleModeTabVisible(BATTLE_TAB_2),
  [BATTLE_TAB_3] = mkBattleModeTabVisible(BATTLE_TAB_3),
  [LEADERBOARD_TAB] = {
    calcByEventId = @(id) shouldShowEventMechanics.get() && has_leaderboard.get()
      && isLeaderboardTabVisible(id, isEventActive.get(), isOPSeasonActive.get(), specialEvents.get())
    watched = Computed(@() shouldShowEventMechanics.get() && has_leaderboard.get()
      && isLeaderboardTabVisible(curEvent.get(), isEventActive.get(), isOPSeasonActive.get(), specialEvents.get()))
  },
}

let curBattleModePresentation = Computed(function() {
  let modeIdx = BATTLE_TAB_MODE_IDX?[seasonPageId.get()]
  if (modeIdx == null)
    return null
  return getGameModePresentationByMode(curGmList.get()?[modeIdx])
})

let bgUnits = Computed(@() seasonPageId.get() not in BATTLE_TAB_MODE_IDX ? null
  : getEventPresentation(curEvent.get()).bgUnits)

let bgScene = Computed(function() {
  let eventId = curEvent.get()
  let isMapTab = seasonPageId.get() == MAP_TAB
  let isBattleTab = seasonPageId.get() in BATTLE_TAB_MODE_IDX
  let mapTabPresentation = getEventPresentation(openedTreeEventId.get())

  if (isMapTab && mapTabPresentation?.mapSceneBg != null)
    return mapTabPresentation.__merge({ bg = mapTabPresentation.mapSceneBg })
  if (seasonPageId.get() == COLLECTION_TAB
      || (seasonPageId.get() == EVENT_SHOP_TAB
        && shouldShowEventMechanics.get()
        && isSeasonTabVisible[COLLECTION_TAB].calcByEventId(eventId)))
    return getCollectionPresentation(curCollectionId.get())
  if (isBattleTab && curBattleModePresentation.get().bg != null)
    return curBattleModePresentation.get()
  if (eventId == OP_EVENT_ID)
    return getOPPresentation(OPCampaign.get())
  if (eventId == "")
    return getEventPresentation(getEventPresentationId(MAIN_EVENT_ID, eventSeason.get(), allSpecialEvents.get()))

  let eventPresentation = getEventPresentation(getEventPresentationId(eventId, eventSeason.get(), allSpecialEvents.get()))

  if (isBattleTab && eventPresentation != null)
    return { ...eventPresentation, bgColor = null }
  if (seasonPageId.get() == LOOTBOX_TAB && eventPresentation != null)
    return { ...eventPresentation, dimColor = null }

  return eventPresentation
})

let hasBattleTab = isSeasonTabVisible[BATTLE_TAB].watched
let newsTag = Computed(@() (hasBattleTab.get() || seasonPageId.get() == MAP_TAB) ? curEvent.get() : null)

let openSeasonTab = @(id) playerSelectedSeasonTab.set(id)

let seasonTabCloseHandlers = {}

function registerSeasonTabClose(tabId, fn) {
  seasonTabCloseHandlers[tabId] <- fn
}

function markSeasonHelpWndSeen(id) {
  if (seasonHelpWndSeen.get()?[id])
    return
  seasonHelpWndSeen.mutate(@(v) v[id] <- true)
  let blk = get_local_custom_settings_blk()
  blk.addBlock(SEASON_HELP_WND_SEEN_SAVE_ID)[id] = true
  eventbus_send("saveProfile", {})
}

function loadSeasonHelpWndSeen() {
  if (!isOnlineSettingsAvailable.get()) {
    seasonHelpWndSeen.set({})
    return
  }
  let blk = get_local_custom_settings_blk()?[SEASON_HELP_WND_SEEN_SAVE_ID]
  seasonHelpWndSeen.set(isDataBlock(blk) ? blk2SquirrelObjNoArrays(blk) : {})
}

loadSeasonHelpWndSeen()
isOnlineSettingsAvailable.subscribe(@(_) loadSeasonHelpWndSeen())

function shouldAutoOpenHelpWnd(sId) {
  return sId != null
    && !isTutorialActive.get()
    && !seasonHelpWndSeen.get()?[sId]
}

function openHelpWndIfUnseen(sId, openFunc) {
  if (shouldAutoOpenHelpWnd(sId)) {
    deferOnce(openFunc)
    markSeasonHelpWndSeen(sId)
  }
}

function openSeasonScene(eventName, tabIdRaw = null, subId = null) {
  eventName = specialEvents.get().findvalue(@(v) v.eventName == eventName)?.eventId ?? eventName
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return null
  }

  let prevTab = playerSelectedSeasonTab.get()
  local tabId = isSeasonTabVisible?[tabIdRaw].calcByEventId(eventName) ? tabIdRaw
    : isSeasonTabVisible?[prevTab].calcByEventId(eventName) ? prevTab
    : seasonTabPriority.findvalue(@(v) isSeasonTabVisible[v].calcByEventId(eventName))

  if (tabId == null) {
    logerr("Try to open season scene when all tabs are not visible")
    return null
  }

  if (tabIdRaw == null)
    if (shouldAutoOpenHelpWnd(activeCollectionsCfg.get().findindex(@(c) c.meta?.event_id == eventName))
        && isSeasonTabVisible[COLLECTION_TAB].calcByEventId(eventName))
      tabId = COLLECTION_TAB
    else if (shouldAutoOpenHelpWnd(activeBattlePassesCfg.get().findindex(@(c) c.meta?.event_id == eventName))
        && isSeasonTabVisible[PASS_SCENE].calcByEventId(eventName)) {
      tabId = PASS_SCENE
  }

  openEventInfo.set({
    eventName
    counter = curEvent.get() == eventName ? eventWndOpenCounter.get() + 1 : 1
  })
  seasonSceneOpenCounter.set(seasonSceneOpenCounter.get() + 1)
  openSeasonTab(tabId)
  if (tabId == PASS_OBSOLETE_SCENE && subId != null)
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
    return openSeasonScene(eventId, MAP_TAB)
  openSeasonScene(eventName)
}

function resetAllSeasonHelpWndSeen() {
  if (seasonHelpWndSeen.get().len() == 0)
    return

  seasonHelpWndSeen.set({})
  get_local_custom_settings_blk().removeBlock(SEASON_HELP_WND_SEEN_SAVE_ID)
  eventbus_send("saveProfile", {})
}

subscribeResetProfile(resetAllSeasonHelpWndSeen)
register_command(resetAllSeasonHelpWndSeen, "debug.reset_all_season_help_wnd_seen")
register_command(@() console_print(seasonHelpWndSeen.get()), "debug.show_seen_season_help_wnd") 

return {
  BATTLE_TAB
  BATTLE_TAB_2
  BATTLE_TAB_3
  BATTLE_TAB_MODE_IDX
  PASS_SCENE
  PASS_OBSOLETE_SCENE
  QUESTS_TAB
  EVENT_SHOP_TAB
  LOOTBOX_TAB
  MAP_TAB
  LEADERBOARD_TAB
  COLLECTION_TAB
  SEASON_SCENE_ID
  questTabsByEventId
  isSeasonTabVisible
  playerSelectedSeasonTab
  seasonSceneOpenCounter
  isSeasonSceneTop
  seasonTabs
  seasonTabIdx
  seasonPageId
  seasonShopId
  backToTab

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
  openHelpWndIfUnseen
}
