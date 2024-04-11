from "%globalsDarg/darg_library.nut" import *
let { separateEventModes } = require("%rGui/gameModes/gameModeState.nut")
let { activeBattleMods } = require("%appGlobals/pServer/battleMods.nut")


let openedGmEventId = mkWatched(persist, "openedGmEventId")
let curGmList = Computed(@() separateEventModes.get()?[openedGmEventId.get()] ?? [])
let reqBattleMods = Computed(@() curGmList.get()?[0].reqBattleMod.split(";") ?? [])
let hasAccessCurGmEvent = Computed(@() reqBattleMods.get().len() == 0
  || null != reqBattleMods.get().findindex(@(bm) !!activeBattleMods.get()?[bm]))

let closeGmEventWnd = @() openedGmEventId(null)

function openGmEventWnd(eventId) {
  if (eventId in separateEventModes.get())
    openedGmEventId(eventId)
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
}