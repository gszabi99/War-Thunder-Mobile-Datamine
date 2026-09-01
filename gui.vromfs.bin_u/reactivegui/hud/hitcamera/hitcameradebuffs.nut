from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import SHIP, BOAT
from "%globalsDarg/fontScale.nut" import getScaledFont
from "%rGui/hud/hitCamera/hitCameraState.nut" import hcUnitType, hcInfo, hcDamageStatus
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudCoralRedColor, hudGoldColor


const iconSize = hdpxi(30)

const HIDDEN = -1
const HEALTHY = 0
const GOOD = 1
const CRITICAL = 2
const KILLED = 3
const OFF = 4

const defIconColor = 0xA0A0A0A0
let iconColor = {
  [KILLED] = hudCoralRedColor,
  [OFF] = 0x500C0E11,
}

let defTextColor = hudWhiteColor
let textColor = {
  [HEALTHY] = 0xFFA0A0A0,
  [CRITICAL] = hudGoldColor,
  [KILLED] = hudCoralRedColor,
  [OFF] = 0x500C0E11,
}

let stateByValue = @(cur, vMax, crit, vMin) cur < vMin ? KILLED
  : cur < crit ? CRITICAL
  : cur < vMax ? GOOD
  : HEALTHY

function mkCommonDebuff(icon, scale, textW, stateW) {
  let size = scaleEven(iconSize, scale)
  let font = getScaledFont(fontVeryTiny, scale)
  return @() {
    watch = stateW
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = stateW.get() == HIDDEN ? null
      : [
          {
            size = [size, size]
            rendObj = ROBJ_IMAGE
            image = Picture($"{icon}:{size}:{size}")
            color = iconColor?[stateW.get()] ?? defIconColor
          }
          @() {
            watch = textW
            rendObj = ROBJ_TEXT
            color = textColor?[stateW.get()] ?? defTextColor
            text = textW.get()
          }.__update(font)
        ]
  }
}

let shipDebuffs = [
  function(scale) {
    let buoyancy = Computed(@() hcDamageStatus.get()?.buoyancy ?? hcInfo.get()?.buoyancy ?? 1.0)
    return mkCommonDebuff("ui/gameuiskin#buoyancy_icon.svg", scale,
      Computed(@() $"{(100 * buoyancy.get() + 0.5).tointeger()}%"),
      Computed(@() buoyancy.get() > 0.995 ? HIDDEN
        : stateByValue(buoyancy.get(), 0.995, 0.505, 0.005)))
  }
]

let debuffsByType = {
  [SHIP] = shipDebuffs,
  [BOAT] = shipDebuffs,
}

let hitCameraDebuffs = @(scale) @() {
  watch = hcUnitType
  padding = hdpx(6)
  flow = FLOW_VERTICAL
  children = (debuffsByType?[hcUnitType.get()] ?? []).map(@(ctor) ctor(scale))
}

return hitCameraDebuffs