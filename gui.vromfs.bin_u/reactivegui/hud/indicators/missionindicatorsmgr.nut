from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%rGui/hud/indicators/hudIndicatorsState.nut" import addHudIndicator, removeHudIndicatorByParams, INDICATOR_TYPE
from "%rGui/style/teamColors.nut" import teamBlueColor, teamRedColor


let logI = log_with_prefix("[INDICATORS] ")
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
