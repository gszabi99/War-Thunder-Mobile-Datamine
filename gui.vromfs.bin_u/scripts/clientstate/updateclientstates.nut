from "%scripts/dagui_library.nut" import *
let { loading_is_in_progress } = require("loading")
let { get_mp_session_id_int } = require("multiplayer")
let { isInBattle, isInLoadingScreen, localMPlayerId, localMPlayerTeam, battleSessionId,
  isInFlightMenu, isMpStatisticsActive, isInMpSession
} = require("%appGlobals/clientState/clientState.nut")
let { get_local_mplayer } = require("mission")
let { isInFlight } = require("gameplayBinding")

function updateStates() {
  isInBattle.set(isInFlight())
  isInLoadingScreen.set(loading_is_in_progress())
  isInFlightMenu.set(false)
  isMpStatisticsActive.set(false)
  let { id = -1, team = MP_TEAM_NEUTRAL } = isInFlight() ? get_local_mplayer() : null
  localMPlayerId.set(id)
  localMPlayerTeam.set(team)
}

isInBattle.subscribe(@(v) v ? battleSessionId.set(get_mp_session_id_int()) : null)

wlog(isInBattle, "[UI_STATES] isInBattle")
wlog(battleSessionId, "[UI_STATES] battleSessionId")
wlog(isInMpSession, "[UI_STATES] isInMpSession")
wlog(isInLoadingScreen, "[UI_STATES] isInLoadingScreen")
wlog(isInFlightMenu, "[UI_STATES] isInFlightMenu")
wlog(isMpStatisticsActive, "[UI_STATES] isMpStatisticsActive")

updateStates()

return updateStates