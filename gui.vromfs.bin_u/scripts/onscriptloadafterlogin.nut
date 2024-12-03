from "%scripts/dagui_library.nut" import *
let { get_settings_blk } = require("blkGetters")

let { loadOnce } = require("%sqStdLibs/scriptReloader/scriptReloader.nut")
require("topMenuButtonsActions.nut")

foreach (fn in [
  "%scripts/missions/missionsUtils.nut"

  "%scripts/matchingRooms/sessionLobby.nut"
  "%scripts/matchingRooms/roomInfo.nut"

  "%scripts/flightMenu.nut"
  "%scripts/respawn.nut"

  "%scripts/debriefing/debriefingModal.nut"

  "%scripts/hud/hudEventManager.nut"

]) {
  loadOnce(fn)
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
if (!(get_settings_blk()?.debug.skipPopups ?? false))
  require("%scripts/matchingRooms/sessionReconnect.nut")
require("%scripts/hud/hud.nut")
require("userstat.nut")
