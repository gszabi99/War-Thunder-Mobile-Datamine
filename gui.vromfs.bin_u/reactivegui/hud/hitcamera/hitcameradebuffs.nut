from "%globalsDarg/darg_library.nut" import *
let { SHIP, BOAT } = require("%appGlobals/unitConst.nut")
let { hcUnitType, hcInfo, hcDamageStatus } = require("hitCameraState.nut")

let iconSize = hdpxi(30)

let HIDDEN = -1
let HEALTHY = 0
let GOOD = 1
let CRITICAL = 2
let KILLED = 3
let OFF = 4

let defIconColor = 0xA0A0A0A0
let iconColor = {
  [KILLED] = 0xFFFF4040,
  [OFF] = 0x500C0E11,
}

let defTextColor = 0xFFFFFFFF
let textColor = {
  [HEALTHY] = 0xFFA0A0A0,
  [CRITICAL] = 0xFFFFC000,
  [KILLED] = 0XFFFF4040,
  [OFF] = 0x500C0E11,
}

let stateByValue = @(cur, vMax, crit, vMin) cur < vMin ? KILLED
  : cur < crit ? CRITICAL
  : cur < vMax ? GOOD
  : HEALTHY

let mkCommonDebuff = @(icon, textW, stateW) @() {
  watch = stateW
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = stateW.value == HIDDEN ? null
    : [
        {
          size = [iconSize, iconSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"{icon}:{iconSize}:{iconSize}")
          color = iconColor?[stateW.value] ?? defIconColor
        }
        @() {
          watch = textW
          rendObj = ROBJ_TEXT
          color = textColor?[stateW.value] ?? defTextColor
          text = textW.value
        }.__update(fontVeryTiny)
      ]
}

let shipDebuffs = [
  function() {
    let buoyancy = Computed(@() hcDamageStatus.value?.buoyancy ?? hcInfo.value?.buoyancy ?? 1.0)
    return mkCommonDebuff("ui/gameuiskin#buoyancy_icon.svg",
      Computed(@() $"{(100 * buoyancy.value + 0.5).tointeger()}%"),
      Computed(@() buoyancy.value > 0.995 ? HIDDEN
        : stateByValue(buoyancy.value, 0.995, 0.505, 0.005)))
  }
]

let debuffsByType = {
  [SHIP] = shipDebuffs,
  [BOAT] = shipDebuffs,
}

let hitCameraDebuffs = @() {
  watch = hcUnitType
  padding = hdpx(6)
  flow = FLOW_VERTICAL
  children = (debuffsByType?[hcUnitType.value] ?? []).map(@(ctor) ctor())
}

return hitCameraDebuffs