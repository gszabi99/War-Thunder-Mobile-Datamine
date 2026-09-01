from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe, eventbus_send
from "gameplayBinding" import inFlightMenu, setMuteSoundInFlightMenu
from "scriptRespondent" import registerRespondent
from "%appGlobals/clientState/clientState.nut" import isMpStatisticsActive
from "%rGui/missions/missionsUtils.nut" import locCurrentMissionName


isMpStatisticsActive.subscribe(function(val) {
  if (val)
    setMuteSoundInFlightMenu(false)
  inFlightMenu(val)
})

let cbOpenMpStatistics = @(_) isMpStatisticsActive.set(true)
eventbus_subscribe("gui_start_mpstatscreen_from_game", cbOpenMpStatistics) 
eventbus_subscribe("gui_start_flight_menu_stat", cbOpenMpStatistics) 

eventbus_subscribe("toggleMpstatscreen", @(_) isMpStatisticsActive.set(!isMpStatisticsActive.get()))

eventbus_subscribe("MpStatistics_CloseInDagui", @(_) isMpStatisticsActive.set(false))
eventbus_subscribe("MpStatistics_GetInitialData",
  @(_) eventbus_send("MpStatistics_InitialData", { missionName = locCurrentMissionName() }))

registerRespondent("is_mpstatscreen_active", @() isMpStatisticsActive.get())
