from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { curEventBg, openEventInfo, specialEvents, MAIN_EVENT_ID, curEvent, eventWndOpenCounter,
  shouldShowEventMechanics, specialEventsOrdered
} = require("%rGui/event/eventState.nut")
let { playerSelectedScene } = require("%rGui/battlePass/passState.nut")
let { sceneBg } = require("%rGui/battlePass/passScene.nut")
let { tabIdToOpen, questsCfg } = require("%rGui/quests/questsState.nut")


let PASS_SCENE = "pass_scene"
let QUESTS_TAB = "quests_tab"
let LOOTBOX_TAB = "lootbox_tab"

let playerSelectedSeasonTab = mkWatched(persist, "playerSelectedSeasonTab", PASS_SCENE)
let seasonSceneOpenCounter = mkWatched(persist, "seasonSceneOpenCounter", 0)

let seasonTabs = [ PASS_SCENE, QUESTS_TAB, LOOTBOX_TAB ]

let seasonTabIdx = Computed(@() seasonTabs.indexof(playerSelectedSeasonTab.get()) ?? 0)
let seasonPageId = Computed(@() seasonTabs?[seasonTabIdx.get()])

let bgScene = Computed(function() {
  let id = seasonPageId.get()
  if (id == PASS_SCENE)
    return sceneBg.get()
  if ( id == LOOTBOX_TAB || id == QUESTS_TAB)
    return curEventBg.get()
  return null
})


let openSeasonTab = @(id) playerSelectedSeasonTab.set(id)

let seasonTabCloseHandlers = {}

function registerSeasonTabClose(tabId, fn) {
  seasonTabCloseHandlers[tabId] <- fn
}

function openSeasonScene(eventName, id, subId = null) {
  eventName = specialEvents.get().findvalue(@(v) v.eventName == eventName)?.eventId ?? eventName
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return null
  }
  if (!shouldShowEventMechanics.get() && id != QUESTS_TAB && eventName != "")
    return null

  openEventInfo.set({
    eventName
    counter = curEvent.get() == eventName ? eventWndOpenCounter.get() + 1 : 1
  })

  seasonSceneOpenCounter.set(seasonSceneOpenCounter.get() + 1)
  openSeasonTab(id)
  if (id == PASS_SCENE && subId != null) {
    playerSelectedScene.set(subId)
  }
}

let openMainSeasonScene = @(id, subId = null) openSeasonScene(MAIN_EVENT_ID, id, subId)

function closeSeasonScene() {
  let id = playerSelectedSeasonTab.get()
  seasonTabCloseHandlers?[id]()
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


return {
  PASS_SCENE
  QUESTS_TAB
  LOOTBOX_TAB
  playerSelectedSeasonTab
  seasonSceneOpenCounter
  seasonTabs
  seasonTabIdx
  seasonPageId
  openSeasonTab
  openSeasonScene
  openMainSeasonScene
  closeSeasonScene
  openQuestsWndOnTab
  registerSeasonTabClose
  bgScene
}
