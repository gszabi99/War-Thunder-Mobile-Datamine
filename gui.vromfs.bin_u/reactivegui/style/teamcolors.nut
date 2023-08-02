from "%globalsDarg/darg_library.nut" import *
let { TARGET_HUE_ALLY, TARGET_HUE_ENEMY, correctHueTarget, correctColorLightness
} = require("colorCorrector")

let teamBlueColor = correctHueTarget(Color(52, 176, 176), TARGET_HUE_ALLY)
let teamRedColor = correctHueTarget(Color(255,  90,  82), TARGET_HUE_ENEMY)

return {
  teamBlueColor
  teamBlueLightColor    = correctColorLightness(teamBlueColor, 50)

  teamRedColor
  teamRedLightColor     = correctColorLightness(teamRedColor, 50)
}
