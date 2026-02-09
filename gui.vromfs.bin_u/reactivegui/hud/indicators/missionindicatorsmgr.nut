from "%globalsDarg/darg_library.nut" import *
let logI = log_with_prefix("[INDICATORS] ")
let { eventbus_subscribe } = require("eventbus")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { addHudIndicator, removeHudIndicatorByParams, INDICATOR_TYPE } = require("%rGui/hud/indicators/hudIndicatorsState.nut")
let { PLAYER_MISSION_ICON } = INDICATOR_TYPE

eventbus_subscribe("addIconToUnit", function(params) {
  logI("addIconToUnit", params)
  let { playerId = -1, iconType = "", set = false, isEnemy = false } = params
  if (playerId == -1 || iconType == "")
    return
  if (set) {
    let icon = iconType
    let iconColor = isEnemy ? teamRedColor : teamBlueColor
    addHudIndicator(PLAYER_MISSION_ICON, { playerId, icon, iconColor })
  }
  else
    removeHudIndicatorByParams(PLAYER_MISSION_ICON, { playerId })
})
