from "%globalsDarg/darg_library.nut" import *
let { TARGET_HUE_ALLY, TARGET_HUE_ENEMY, TARGET_HUE_SQUAD, correctHueTarget, correctColorLightness
} = require("colorCorrector")
let { format } =  require("string")

let teamRedColorBase = 0xFFFF5A52
let teamBlueColor = correctHueTarget(0xFF34B0B0, TARGET_HUE_ALLY)
let teamRedColor = correctHueTarget(teamRedColorBase, TARGET_HUE_ENEMY)
let mySquadColor = correctHueTarget(0xFF3E9E2F, TARGET_HUE_SQUAD)

log($"teamRedColor corrected by TARGET_HUE_ENEMY from 0x{format("%X", teamRedColorBase)} to 0x{format("%X", teamRedColor)}")

return {
  teamBlueColor
  teamBlueLightColor    = correctColorLightness(teamBlueColor, 0.69)
  teamBlueDarkColor     = correctColorLightness(teamBlueColor, 0.4)

  teamRedColor
  teamRedLightColor     = correctColorLightness(teamRedColor, 0.69)
  teamRedDarkColor      = correctColorLightness(teamRedColor, 0.4)

  mySquadColor
  mySquadLightColor     = correctColorLightness(mySquadColor, 0.69)
}
