from "%globalsDarg/darg_library.nut" import *
let { localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { teamBlueLightColor, teamRedLightColor, mySquadLightColor } = require("%rGui/style/teamColors.nut")

let MP_TEAM_NEUTRAL = 0

let localPlayerColor = 0xFFDDA339
let systemMsgColor = 0xFFFFFF00

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
