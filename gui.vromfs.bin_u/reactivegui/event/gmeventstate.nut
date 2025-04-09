from "%globalsDarg/darg_library.nut" import *
let { separateEventModes } = require("%rGui/gameModes/gameModeState.nut")
let { campProfile } = require("%appGlobals/pServer/campaign.nut")
let { activeBattleMods } = require("%appGlobals/pServer/battleMods.nut")
let { specialEventsWithTree } = require("eventState.nut")
let { openTreeEventWnd } = require("treeEvent/treeEventState.nut")


let mustHasFinishedBattle = {
  event_april_2025 = true
}

let openedGmEventId = mkWatched(persist, "openedGmEventId")
let curGmList = Computed(@() separateEventModes.get()?[openedGmEventId.get()] ?? [])
let reqBattleMods = Computed(@() curGmList.get()?[0].reqBattleMod.split(";") ?? [])
let hasAccessCurGmEvent = Computed(@() reqBattleMods.get().len() == 0
  || null != reqBattleMods.get().findindex(@(bm) !!activeBattleMods.get()?[bm]))

let hasFinishedFirstBattle = Computed(@()
  (campProfile.get()?.lastReceivedFirstBattlesRewardIds ?? []).reduce(@(res, v) max(v, res), -1) >= 0)

let closeGmEventWnd = @() openedGmEventId(null)

let canOpenGmEventWnd = @(eventId, finishedFirstBattle) !mustHasFinishedBattle?[eventId] || finishedFirstBattle

function openGmEventWnd(eventId) {
  if (!canOpenGmEventWnd(eventId, hasFinishedFirstBattle.get()))
    return
  if (eventId not in separateEventModes.get())
    return
  if (specialEventsWithTree.get().findindex(@(event) event.eventName == eventId) != null)
    return openTreeEventWnd(eventId)
  else
    openedGmEventId.set(eventId)
}

curGmList.subscribe(function(v) {
  if (v.len() == 0 && openedGmEventId.get() != null)
    closeGmEventWnd()
})

return {
  openedGmEventId
  isGmEventWndOpened = Computed(@() openedGmEventId.get() != null)
  closeGmEventWnd
  openGmEventWnd

  gmEventsList = Computed(@() separateEventModes.get().keys())
  curGmList
  reqBattleMods
  hasAccessCurGmEvent
  canOpenGmEventWnd
  hasFinishedFirstBattle
}