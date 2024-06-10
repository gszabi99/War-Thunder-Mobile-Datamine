from "%scripts/dagui_natives.nut" import set_mute_sound_in_flight_menu, in_flight_menu
from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { isMpStatisticsActive } = require("%appGlobals/clientState/clientState.nut")
let { locCurrentMissionName } = require("%scripts/missions/missionsUtils.nut")
let { registerRespondent } = require("scriptRespondent")

isMpStatisticsActive.subscribe(function(val) {
  in_flight_menu(val)
  if (val)
    set_mute_sound_in_flight_menu(false)
})

let cbOpenMpStatistics = @(_) isMpStatisticsActive.set(true)
eventbus_subscribe("gui_start_mpstatscreen_from_game", cbOpenMpStatistics) // called from client
eventbus_subscribe("gui_start_flight_menu_stat", cbOpenMpStatistics) // called from client

eventbus_subscribe("MpStatistics_CloseInDagui", @(_) isMpStatisticsActive(false))
eventbus_subscribe("MpStatistics_GetInitialData",
  @(_) eventbus_send("MpStatistics_InitialData", { missionName = locCurrentMissionName() }))

registerRespondent("is_mpstatscreen_active", @() isMpStatisticsActive.get())
