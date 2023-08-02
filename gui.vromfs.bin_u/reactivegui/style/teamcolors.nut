from "%globalsDarg/darg_library.nut" import *
let { TARGET_HUE_ALLY, TARGET_HUE_ENEMY, TARGET_HUE_SQUAD, correctHueTarget, correctColorLightness
} = require("colorCorrector")

let teamBlueColor = correctHueTarget(Color(52, 176, 176), TARGET_HUE_ALLY)
let teamRedColor = correctHueTarget(Color(255,  90,  82), TARGET_HUE_ENEMY)
let mySquadColor = correctHueTarget(0xFF3E9E2F, TARGET_HUE_SQUAD)

return {
  teamBlueColor
  teamBlueLightColor    = correctColorLightness(teamBlueColor, 80)

  teamRedColor
  teamRedLightColor     = correctColorLightness(teamRedColor, 80)

  mySquadColor
  mySquadLightColor     = correctColorLightness(mySquadColor, 80)
}
