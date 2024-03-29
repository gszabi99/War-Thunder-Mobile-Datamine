from "%scripts/dagui_natives.nut" import set_mute_sound_in_flight_menu, in_flight_menu
from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { isMpStatisticsActive } = require("%appGlobals/clientState/clientState.nut")
let { locCurrentMissionName } = require("%scripts/missions/missionsUtils.nut")
let { registerRespondent } = require("%appGlobals/scriptRespondents.nut")

isMpStatisticsActive.subscribe(function(val) {
  in_flight_menu(val)
  if (val)
    set_mute_sound_in_flight_menu(false)
})

function openMpStatistics() {
  isMpStatisticsActive(true)
}

eventbus_subscribe("toggleMpstatscreen", @(_) !isMpStatisticsActive.value
  ? openMpStatistics()
  : isMpStatisticsActive(false))
eventbus_subscribe("MpStatistics_CloseInDagui", @(_) isMpStatisticsActive(false))
eventbus_subscribe("MpStatistics_GetInitialData",
  @(_) eventbus_send("MpStatistics_InitialData", { missionName = locCurrentMissionName() }))

registerRespondent("is_mpstatscreen_active", @() isMpStatisticsActive.get())
