from "%globalScripts/logs.nut" import *
from "%globalScripts/mpTeamConsts.nut" import *
from "eventbus" import eventbus_subscribe
from "gameplayBinding" import isInFlight, getIsInFlightMenu
from "loading" import loading_is_in_progress
from "mission" import get_local_mplayer
from "multiplayer" import get_mp_session_id_int
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInLoadingScreen, localMPlayerId, localMPlayerTeam,
  battleSessionId, isInFlightMenu, isMpStatisticsActive, isInMpSession


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




eventbus_subscribe("hangar.onEnter", @(_) updateStates())
eventbus_subscribe("gui_start_empty_screen", @(_) updateStates())
eventbus_subscribe("gui_start_loading", @(_) updateStates())

wlog(isInBattle, "[UI_STATES] isInBattle")
wlog(battleSessionId, "[UI_STATES] battleSessionId")
wlog(isInMpSession, "[UI_STATES] isInMpSession")
wlog(isInLoadingScreen, "[UI_STATES] isInLoadingScreen")
wlog(isInFlightMenu, "[UI_STATES] isInFlightMenu")
wlog(isMpStatisticsActive, "[UI_STATES] isMpStatisticsActive")

updateStates()



isInFlightMenu.set(getIsInFlightMenu())

return updateStates
