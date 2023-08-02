
from "%scripts/dagui_library.nut" import *
let eventbus = require("eventbus")
let { isMpStatisticsActive } = require("%appGlobals/clientState/clientState.nut")
let { get_mplayers_list, get_mplayer_by_id } = require("mission")

let function getTeamsList() {
  let mplayersList = get_mplayers_list(GET_MPLAYERS_LIST, true)
  let teamsOrder = ::get_mp_local_team() == 2 ? [ 2, 1 ] : [ 1, 2 ]
  return teamsOrder.map(@(team) mplayersList.filter(@(v) v.team == team))
}

isMpStatisticsActive.subscribe(function(val) {
  ::in_flight_menu(val)
  if (val)
    ::set_mute_sound_in_flight_menu(false)
})

let function openMpStatistics() {
  isMpStatisticsActive(true)
}

eventbus.subscribe("toggleMpstatscreen", @(_) !isMpStatisticsActive.value
  ? openMpStatistics()
  : isMpStatisticsActive(false))
eventbus.subscribe("MpStatistics_CloseInDagui", @(_) isMpStatisticsActive(false))
eventbus.subscribe("MpStatistics_GetInitialData",
  @(_) eventbus.send("MpStatistics_InitialData", { missionName = ::loc_current_mission_name() }))
eventbus.subscribe("MpStatistics_GetTeamsList",
  @(_) eventbus.send("MpStatistics_TeamsList", { data = getTeamsList() }))

eventbus.subscribe("get_mplayer_by_id",
  @(p) eventbus.send("get_mplayer_by_id_result", { id = p.id, player = get_mplayer_by_id(p.id) }))

eventbus.subscribe("get_mplayers_by_ids",
  @(p) eventbus.send("get_mplayers_by_ids_result", { uid = p.uid, players = p.players.map(@(pId) get_mplayer_by_id(pId)) }))

::is_mpstatscreen_active <- @() isMpStatisticsActive.value //called from the native code
