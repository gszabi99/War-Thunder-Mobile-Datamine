from "%globalsDarg/darg_library.nut" import *
from "colorCorrector" import TARGET_HUE_ALLY, TARGET_HUE_ENEMY, TARGET_HUE_SQUAD, correctHueTarget,
  correctColorLightness
from "string" import format
from "%rGui/style/hudColors.nut" import hudBlueColor, hudCoralRedColor, hudGreenColor


let teamBlueColor = correctHueTarget(hudBlueColor, TARGET_HUE_ALLY)
let teamRedColor = correctHueTarget(hudCoralRedColor, TARGET_HUE_ENEMY)
let mySquadColor = correctHueTarget(hudGreenColor, TARGET_HUE_SQUAD)

log($"teamRedColor corrected by TARGET_HUE_ENEMY from 0x{format("%X", hudCoralRedColor)} to 0x{format("%X", teamRedColor)}")

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
