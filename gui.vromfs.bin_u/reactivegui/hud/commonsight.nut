from "%globalsDarg/darg_library.nut" import *
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")
let { hudWhiteColor, hudRedColor, hudGoldColor, hudLimeColor } = require("%rGui/style/hudColors.nut")

let crosshairColor = hudWhiteColor
let crosshairNoPenetrationColor = hudRedColor
let crosshairPropablePenetrationColor = hudGoldColor
let crosshairPenetrationColor = hudLimeColor

let crosshairSimpleSize = evenPx(20)
let reductionCoefficientSightSize = 0.85
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