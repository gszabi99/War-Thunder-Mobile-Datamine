from "%globalsDarg/darg_library.nut" import *
let { separateEventModes } = require("%rGui/gameModes/gameModeState.nut")
let { campProfile } = require("%appGlobals/pServer/campaign.nut")
let { activeBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { specialEventsWithTree } = require("%rGui/event/eventState.nut")
let { openTreeEventWnd } = require("%rGui/event/treeEvent/treeEventState.nut")
let { eventsPassList, curEventId } = require("%rGui/battlePass/eventPassState.nut")


let mustHasFinishedBattle = {
  event_april_2025 = true
}

let openedGmEventId = mkWatched(persist, "openedGmEventId")
let openedGMEvenPasstId = mkWatched(persist, "openedGMEvenPasstId")
let curGmList = Computed(@() separateEventModes.get()?[openedGmEventId.get()] ?? separateEventModes.get()?[openedGMEvenPasstId.get()] ?? [])
let reqBattleMods = Computed(@() curGmList.get()?[0].reqBattleMod.split(";") ?? [])
let hasAccessCurGmEvent = Computed(@() reqBattleMods.get().len() == 0
  || null != reqBattleMods.get().findindex(@(bm) !!activeBattleMods.get()?[bm]))

let hasFinishedFirstBattle = Computed(@()
  (campProfile.get()?.lastReceivedFirstBattlesRewardIds ?? []).reduce(@(res, v) max(v, res), -1) >= 0)

let closeGmEventWnd = @() openedGmEventId.set(null)
let closeGmEPWnd = @() openedGMEvenPasstId.set(null)

let canOpenGmEventWnd = @(eventId, finishedFirstBattle) !mustHasFinishedBattle?[eventId] || finishedFirstBattle

function openGmEventWnd(eventId) {
  if (!canOpenGmEventWnd(eventId, hasFinishedFirstBattle.get()))
    return
  if (eventId not in separateEventModes.get())
    return
  if (specialEventsWithTree.get().findindex(@(event) event.eventName == eventId) != null)
    return openTreeEventWnd(eventId)
  if (eventsPassList.get().findvalue(@(v) v.eventName == eventId)) {
    openedGMEvenPasstId.set(eventId)
    curEventId.set(eventId)
    return
  }
  openedGmEventId.set(eventId)
}

curGmList.subscribe(function(v) {
  if (v.len() == 0 && (openedGmEventId.get() != null || openedGMEvenPasstId.get() != null)) {
    closeGmEventWnd()
    closeGmEPWnd()
  }
})

return {
  openedGmEventId
  openedGMEvenPasstId
  isGmEventWndOpened = Computed(@() openedGmEventId.get() != null)
  isGmEventWndEPOpened = Computed(@() openedGMEvenPasstId.get() != null)
  closeGmEventWnd
  closeGmEPWnd
  openGmEventWnd

  gmEventsList = separateEventModes
  curGmList
  reqBattleMods
  hasAccessCurGmEvent
  canOpenGmEventWnd
  hasFinishedFirstBattle
}