
from "%scripts/dagui_library.nut" import *
let { loading_is_in_progress } = require("loading")
let { get_mp_session_id_int } = require("multiplayer")
let { isInBattle, isInLoadingScreen, localMPlayerId, localMPlayerTeam, battleSessionId,
  isInFlightMenu, isMpStatisticsActive, isInMpSession
} = require("%appGlobals/clientState/clientState.nut")
let { missionProgressType } = require("%appGlobals/clientState/missionState.nut")
let { get_local_mplayer } = require("mission")

let function updateStates() {
  let isInFlight = ::is_in_flight()
  isInBattle.update(isInFlight)
  isInLoadingScreen.update(loading_is_in_progress())
  isInFlightMenu(false)
  isMpStatisticsActive(false)
  let { id = -1, team = MP_TEAM_NEUTRAL } = isInFlight ? get_local_mplayer() : null
  localMPlayerId(id)
  localMPlayerTeam(team)
}

isInBattle.subscribe(@(v) v ? battleSessionId(get_mp_session_id_int()) : null)

wlog(isInBattle, "[UI_STATES] isInBattle")
wlog(battleSessionId, "[UI_STATES] battleSessionId")
wlog(isInMpSession, "[UI_STATES] isInMpSession")
wlog(isInLoadingScreen, "[UI_STATES] isInLoadingScreen")
wlog(isInFlightMenu, "[UI_STATES] isInFlightMenu")
wlog(isMpStatisticsActive, "[UI_STATES] isMpStatisticsActive")

updateStates()

let updateMissionState = @()
  missionProgressType(::get_current_mission_info_cached()?.missionProgressType ?? "")

let shouldUpdateMisson = keepref(Computed(@() isInBattle.value && !isInLoadingScreen.value))
if (shouldUpdateMisson.value)
  updateMissionState()
shouldUpdateMisson.subscribe(@(v) v ? updateMissionState() : null)

return updateStates