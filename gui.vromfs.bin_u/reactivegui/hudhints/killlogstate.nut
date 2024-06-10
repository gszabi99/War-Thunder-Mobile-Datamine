from "%globalsDarg/darg_library.nut" import *
from "hudMessages" import *
from "%appGlobals/unitConst.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { get_mplayer_by_id } = require("mission")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { localMPlayerTeam, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { teamBlueLightColor, teamRedLightColor, mySquadLightColor } = require("%rGui/style/teamColors.nut")
let hudMessagesUnitTypesMap = require("hudMessagesUnitTypesMap.nut")

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "killLogState"
  maxActiveEvents = 5
  defTtl = 10
  isEventsEqual = @(a, b) a?.text == b?.text
})
let { addEvent, clearEvents } = state

isInBattle.subscribe(@(_) clearEvents())

//todo: export from native code to darg
const MP_TEAM_NEUTRAL = 0

let localPlayerColor = 0xFFDDA339

let unitTypeSuffix = {
  [AIR]        = "_a",
  [TANK]       = "_t",
  [BOAT]       = "_s",
  [SHIP]       = "_s",
  [HELICOPTER] = "_a",
}

let getKillerUnitType = @(msg) hudMessagesUnitTypesMap?[msg.unitType] ?? getUnitType(msg.unitName)
let getVictimUnitType = @(msg) hudMessagesUnitTypesMap?[msg.victimUnitType] ?? getUnitType(msg.victimUnitName)
let getUnitTypeSuffix = @(unitType) unitTypeSuffix?[unitType] ?? unitTypeSuffix[SHIP]

let getTeamColor = @(team) team == MP_TEAM_NEUTRAL ? null
 : team == localMPlayerTeam.value ? teamBlueLightColor
 : teamRedLightColor

function getTargetName(player, unitNameLoc, team) {
  let color = (player?.isLocal ?? false) ? localPlayerColor
    : player?.isInHeroSquad ? mySquadLightColor
    : getTeamColor(team)
  let text = player == null ? unitNameLoc // AI
    : player.name //real player or bot
  return color == null ? text : colorize(color, text)
}

function getActionTextIconic(msg) {
  let { action } = msg
  local iconId = action == "kill"
      ? "".concat(action, getUnitTypeSuffix(getKillerUnitType(msg)), getUnitTypeSuffix(getVictimUnitType(msg)))
    : action == "crash" ? "".concat(action, getUnitTypeSuffix(getVictimUnitType(msg)))
    : action
  return loc($"icon/hud_msg_mp_dmg/{iconId}")
}

eventbus_subscribe("HudMessage", function(data) {
  if (data.type != HUD_MSG_MULTIPLAYER_DMG || !data.isKill)
    return

  let { action, playerId, victimPlayerId, unitNameLoc, victimUnitNameLoc, team, victimTeam } = data
  let killer = get_mplayer_by_id(playerId)
  let victim = get_mplayer_by_id(victimPlayerId)
  let what = getActionTextIconic(data)
  let whom = getTargetName(victim, victimUnitNameLoc, victimTeam)
  let text = action == "crash" || action == "exit"
    ? " ".concat(whom, what)
    : " ".concat(getTargetName(killer, unitNameLoc, team), what, whom)

  addEvent({ hType = "chatLogTextTiny", text })
})

return state