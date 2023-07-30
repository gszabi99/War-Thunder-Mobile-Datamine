from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

require("topMenuButtonsActions.nut")

foreach (fn in [
  "%scripts/missions/missionsUtils.nut"
  "%scripts/missions/misListType.nut"

  "%scripts/matchingRooms/sessionLobby.nut"

  "%scripts/flightMenu.nut"
  "%scripts/respawn.nut"

  "%scripts/debriefing/debriefingModal.nut"

  "%scripts/hud/hudEventManager.nut"

  "%scripts/matchingRooms/mrooms.nut"
]) {
  ::g_script_reloader.loadOnce(fn)
}

require("%scripts/clientState/updateClientStates.nut")
require("%scripts/matching/webRpcMessages.nut")
require("%scripts/battleData/battleData.nut") //required to send battleData to the dedicated
require("%scripts/battleData/genDefaultBattleData.nut")
require("%scripts/pServer/profileRefresh.nut")
require("%scripts/mpStatisticsHandler.nut")
require("%scripts/missions/missionStart.nut")
require("%scripts/debriefing/battleResultBq.nut")
require("%scripts/matching/queueToGameMode.nut")
require("%scripts/matching/queuesClient.nut")
require("%scripts/matching/queueStats.nut")
require("%scripts/hud/hud.nut")
require("userstat.nut")