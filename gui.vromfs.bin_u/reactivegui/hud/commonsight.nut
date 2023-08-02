from "%globalsDarg/darg_library.nut" import *
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")

let crosshairColor = Color(255, 255, 255)
let crosshairNoPenetrationColor = 0xFFFF0000
let crosshairPropablePenetrationColor = 0xFFFFCC00
let crosshairPenetrationColor = 0xFF04F803

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