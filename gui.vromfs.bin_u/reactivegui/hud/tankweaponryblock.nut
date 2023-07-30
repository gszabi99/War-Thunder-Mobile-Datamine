from "%globalsDarg/darg_library.nut" import *
let { dfAnimBottomRight } = require("%rGui/style/unitDelayAnims.nut")
let { AB_PRIMARY_WEAPON, AB_SECONDARY_WEAPON, AB_SPECIAL_WEAPON, AB_MACHINE_GUN } = require("actionBar/actionType.nut")
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkCircleTankPrimaryGun, mkCircleTankSecondaryGun, mkCircleTankMachineGun, mkCircleZoom
} = require("buttons/circleTouchHudButtons.nut")
let { actionBarItems, curActionBarTypes } = require("actionBar/actionBarState.nut")
let { isUnitDelayed } = require("%rGui/hudState.nut")
let { bulletToggleButton, bulletHintRightAlign } = require("bullets/bulletToggleButton.nut")

let buttonsConfig = [
  {
    aType = AB_PRIMARY_WEAPON
    ctor = mkCircleTankPrimaryGun
    pos = [1.5 * touchButtonSize, 0]
  }
  {
    aType = AB_SECONDARY_WEAPON
    ctor = mkCircleTankSecondaryGun("ID_FIRE_GM_SECONDARY_GUN", "ui/gameuiskin#hud_main_weapon_fire.svg")
    pos = [3.2 * touchButtonSize, -touchButtonSize]
  }
  {
    aType = AB_SPECIAL_WEAPON
    ctor = mkCircleTankSecondaryGun("ID_FIRE_GM_SPECIAL_GUN", "ui/gameuiskin#icon_rocket_in_progress.svg")
    pos = [3.7 * touchButtonSize, 0.5 * touchButtonSize]
  }
  {
    aType = AB_MACHINE_GUN
    ctor = mkCircleTankMachineGun
    pos = [2.5 * touchButtonSize, 1.5 * touchButtonSize]
  }
  {
    ctor = mkCircleZoom
    pos = [0, 1.2 * touchButtonSize]
  }
]

let function mkButton(cfg) {
  let { ctor, aType = null, pos = null } = cfg
  let place = {
    size = [0, 0]
    pos
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  }
  if (aType == null)
    return place.__merge({ children = ctor() })

  let action = Computed(@() actionBarItems.value?[aType])
  return @() place.__merge({
    watch = action
    children = action.value == null ? null
      : ctor(action.value)
  })
}

return @() {
  watch = [isUnitDelayed, curActionBarTypes]
  size = [4.5 * touchButtonSize, 2.5 * touchButtonSize]
  margin = [touchButtonSize, 0]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = isUnitDelayed.value ? null
    : buttonsConfig.filter(@(cfg) "aType" not in cfg || cfg.aType in curActionBarTypes.value)
        .map(mkButton)
        .append({
          pos = [0, -2.0 * touchButtonSize]
          hplace = ALIGN_RIGHT
          flow = FLOW_HORIZONTAL
          gap = hdpx(10)
          children = [
            bulletHintRightAlign
            bulletToggleButton
          ]
        })
  transform = {}
  animations = dfAnimBottomRight
}