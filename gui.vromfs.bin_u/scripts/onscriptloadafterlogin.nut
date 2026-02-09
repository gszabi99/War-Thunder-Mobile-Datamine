from "%scripts/dagui_library.nut" import *
let { get_settings_blk } = require("blkGetters")

require("topMenuButtonsActions.nut")

require("%scripts/missions/missionsUtils.nut")
require("%scripts/matchingRooms/sessionLobby.nut")
require("%scripts/matchingRooms/roomInfo.nut")
require("%scripts/flightMenu.nut")
require("%scripts/respawn.nut")

require("%scripts/debriefing/debriefingModal.nut")
require("%scripts/hud/hudEventManager.nut")

require("%scripts/clientState/updateClientStates.nut")
require("%scripts/matching/webRpcMessages.nut")
require("%scripts/battleData/battleData.nut") 
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
