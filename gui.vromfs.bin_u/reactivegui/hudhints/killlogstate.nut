from "%globalsDarg/darg_library.nut" import *
from "hudMessages" import *
from "%appGlobals/unitConst.nut" import *
let { subscribe } = require("eventbus")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
let { localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { rqPlayersAndDo } = require("rqPlayersAndDo.nut")
let hudMessagesUnitTypesMap = require("hudMessagesUnitTypesMap.nut")

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "killLogState"
  maxActiveEvents = 5
  defTtl = 10
  isEventsEqual = @(a, b) a?.text == b?.text
})
let { addEvent } = state

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
 : team == localMPlayerTeam.value ? teamBlueColor
 : teamRedColor

let function getTargetName(player, unitNameLoc, team) {
  let color = (player?.isLocal ?? false) ? localPlayerColor
    : getTeamColor(team)
  let text = player == null ? unitNameLoc // AI
    : getPlayerName(player.name, myUserRealName.value, myUserName.value) //real player or bot
  return color == null ? text : colorize(color, text)
}

let function getActionTextIconic(msg) {
  let { action } = msg
  local iconId = action == "kill"
      ? "".concat(action, getUnitTypeSuffix(getKillerUnitType(msg)), getUnitTypeSuffix(getVictimUnitType(msg)))
    : action == "crash" ? "".concat(action, getUnitTypeSuffix(getVictimUnitType(msg)))
    : action
  return loc($"icon/hud_msg_mp_dmg/{iconId}")
}

subscribe("HudMessage", function(data) {
  if (data.type != HUD_MSG_MULTIPLAYER_DMG || !data.isKill)
    return

  let { playerId, victimPlayerId } = data
  rqPlayersAndDo({ killer = playerId, victim = victimPlayerId },
    function(players) {
      let { action, unitNameLoc, victimUnitNameLoc, team, victimTeam } = data
      let { killer, victim } = players

      let what = getActionTextIconic(data)
      let whom = getTargetName(victim, victimUnitNameLoc, victimTeam)
      let text = action == "crash" || action == "exit"
        ? " ".concat(whom, what)
        : " ".concat(getTargetName(killer, unitNameLoc, team), what, whom)

      addEvent({ hType = "simpleText", text })
    })
})

return state