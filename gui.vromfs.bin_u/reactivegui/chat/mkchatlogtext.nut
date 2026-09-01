from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import localMPlayerTeam
from "%rGui/style/teamColors.nut" import teamBlueLightColor, teamRedLightColor, mySquadLightColor


const MP_TEAM_NEUTRAL = 0

const localPlayerColor = 0xFFDDA339
const systemMsgColor = 0xFFFFFF00

let getTeamColor = @(team) team == MP_TEAM_NEUTRAL ? null
  : team == localMPlayerTeam.get() ? teamBlueLightColor
  : teamRedLightColor

function mkChatLogText(message) {
  let { sender, msg, isAutomatic, isMyself, isMySquad, team } = message
  local name = sender
  if (name != "") {
    let color = isMyself ? localPlayerColor
      : isMySquad ? mySquadLightColor
      : getTeamColor(team)
    name = colorize(color, name)
  }
  let text = isAutomatic ? colorize(systemMsgColor, msg) : msg
  return colon.join([ name, text ], true)
}

return mkChatLogText
