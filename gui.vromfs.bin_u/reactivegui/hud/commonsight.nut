from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/hudConfigParameters.nut" import getHudConfigParameter
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudRedColor, hudGoldColor, hudLimeColor


let crosshairColor = hudWhiteColor
let crosshairNoPenetrationColor = hudRedColor
let crosshairPropablePenetrationColor = hudGoldColor
let crosshairPenetrationColor = hudLimeColor

let crosshairSimpleSize = evenPx(20)
const reductionCoefficientSightSize = 0.85
let targetSelectionRelativeSize = (100 * getHudConfigParameter("targetSelectionRelativeSize")).tointeger()
let scopeSize = [sw(targetSelectionRelativeSize) * reductionCoefficientSightSize, sh(targetSelectionRelativeSize) * reductionCoefficientSightSize]

return {
  crosshairColor,
  crosshairNoPenetrationColor,
  crosshairPropablePenetrationColor,
  crosshairPenetrationColor,
  crosshairSimpleSize,
  scopeSize
}