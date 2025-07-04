from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { SHIP, BOAT, TANK, SAILBOAT } = require("%appGlobals/unitConst.nut")
let { hcUnitType, hcDamageStatus, hcDmgPartsInfo, isHcUnitKilled, hcRelativeHealth
} = require("hitCameraState.nut")
let { hudUnitType } = require("%rGui/hudState.nut")
let { isTargetRepair, targetHp } = require("%rGui/hud/shipState.nut")

let iconBgSizeBase = evenPx(44)
let iconSizeBase = evenPx(30)
let bigIconSizeBase = evenPx(40)

let HIDDEN = -1
let NONE = 0
let MINOR = 1
let MODERATE = 2
let MAJOR = 3
let CRITICAL = 4
let FATAL = 5
let BROKEN = 6
let KILLED = 7

let colors = {
  [NONE] = 0xFF728188,
  [MINOR] = 0xFFE2AE00,
  [MODERATE] = 0xFFFF7F27,
  [MAJOR] = 0xFFFFFFFF,
  [CRITICAL] = 0xFFFF4338,
  [FATAL] = 0xFF000000,
  [BROKEN] = 0xFFFF4338,
  [KILLED] = 0xFFFF4338,
}

let currentTargetHp = Computed(@() targetHp.value < 0 ? hcRelativeHealth.value : targetHp.value)

let getStatusByHealth = @(health)
  health == null || health == 100 ? NONE
    : health >= 70  ? MINOR
    : health >= 40  ? MODERATE
    : health >= 10  ? MAJOR
    : health > 0    ? CRITICAL
    : health == 0   ? FATAL
    : NONE

let isDmPartKilled = @(dmPart) dmPart?.partKilled ?? false
let isDmPartBroken = @(dmPart) (dmPart?.partKilled ?? false) || (dmPart?.partDead ?? false)
  || (dmPart?.partHp ?? 1.0) <= 0

function getStateByBrokenDmAll(isUnitKilled, partsInfo, partsArray) {
  local isFound = false
  local isKilled = false
  foreach (partId in partsArray) {
    let dmParts = partsInfo?[partId]
    if (dmParts == null)
      continue
    if (isUnitKilled)
      return FATAL
    isFound = true
    foreach (dmPart in dmParts) {
      if (!isDmPartBroken(dmPart))
        return NONE
      if (isDmPartKilled(dmPart))
        isKilled = true
    }
  }
  return !isFound ? HIDDEN
    : isKilled ? KILLED
    : BROKEN
}

function getStateByBrokenDmAny(isUnitKilled, partsInfo, partsArray) {
  local isFound = false
  foreach (partId in partsArray) {
    let dmParts = partsInfo?[partId]
    if (dmParts == null)
      continue
    if (isUnitKilled)
      return FATAL
    isFound = true
    foreach (dmPart in dmParts) {
      if (isDmPartKilled(dmPart))
        return KILLED
      if (isDmPartBroken(dmPart))
        return BROKEN
    }
  }
  return isFound ? NONE : HIDDEN
}

function getStateByBrokenDmMain(isUnitKilled, partsInfo, partsArray, mainDmArray) {
  local isFound = false
  foreach (partId in partsArray) {
    let dmParts = partsInfo?[partId]
    if (dmParts == null)
      continue
    if (isUnitKilled)
      return FATAL
    isFound = true
    local hasMainParts = false
    foreach (dmPartId in mainDmArray)
      if (dmPartId in dmParts) {
        let dmPart = dmParts[dmPartId]
        if (isDmPartKilled(dmPart))
          return KILLED
        if (isDmPartBroken(dmPart))
          return BROKEN
        hasMainParts = true
      }
    if (!hasMainParts)
      foreach (dmPart in dmParts) {
        if (isDmPartKilled(dmPart))
          return KILLED
        if (isDmPartBroken(dmPart))
          return BROKEN
      }
  }
  return isFound ? NONE : HIDDEN
}

let iconAnim = {
  key = {}
  transform = { pivot = [0.5, 0.5] }
  animations = [
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 1.0, easing = CosineFull,
      play = true, loop = true }
  ]
}

function mkTextPart(icon, iconRepair, scale, textW, colorW, isRepairW) {
  let bigIconSize = scaleEven(bigIconSizeBase, scale)
  let iconBgSize = scaleEven(iconBgSizeBase, scale)
  let font = getScaledFont(fontTiny, scale)
  return @() {
    watch = colorW
    size = [flex(2), iconBgSize]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      @() {
        watch = isRepairW
        size = [bigIconSize, bigIconSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"{isRepairW.value ? iconRepair : icon}:{bigIconSize}:{bigIconSize}:P")
        color = colorW.value
      }
      @() {
        watch = textW
        rendObj = ROBJ_TEXT
        color = colorW.value
        text = textW.value
      }.__update(font)
    ]
  }
}

function mkDmgPart(icon, iconSize, iconBgSize, status) {
  let picture = Picture($"{icon}:{iconSize}:{iconSize}")
  return function() {
    let res = { watch = status }
    return status.value == HIDDEN ? res : res.__update({
        size = [flex(), iconBgSize]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          {
            size = [iconBgSize, iconBgSize]
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#dmg_ship_status_bg.svg:{iconBgSize}:{iconBgSize}:P")
            color = status.value == NONE ? 0x33000000
              : status.value == KILLED ? 0XFF541613
              : 0xAA000000
          }
          {
            size = [iconSize, iconSize]
            rendObj = ROBJ_IMAGE
            image = picture
            color = colors?[status.value] ?? 0xFFFFFFFF
          }
        ]
      },
      status.value == KILLED ? iconAnim : {}
    )
  }
}

function sailboatDmgPanelChildrenCtor(scale) {
  let iconSize = scaleEven(iconSizeBase, scale)
  let iconBgSize = scaleEven(iconBgSizeBase, scale)
  return [
    mkDmgPart("ui/gameuiskin#hud_debuff_sail_weapon.svg", iconSize, iconBgSize,
      Computed(@() getStatusByHealth(hcDamageStatus.value?.artilleryHealth)))
    mkDmgPart("ui/gameuiskin#dmg_ship_fire.svg", iconSize, iconBgSize,
      Computed(@() (hcDamageStatus.value?.hasFire ?? false) ? CRITICAL : NONE))
    mkDmgPart("ui/gameuiskin#hud_debuff_sail_control.svg", iconSize, iconBgSize,
      Computed(@() getStatusByHealth(hcDamageStatus.value?.engineHealth)))
    mkDmgPart("ui/gameuiskin#dmg_ship_rudders.svg", iconSize, iconBgSize,
      Computed(@() getStatusByHealth(hcDamageStatus.value?.ruddersHealth)))
    mkDmgPart("ui/gameuiskin#dmg_ship_breach.svg", iconSize, iconBgSize,
      Computed(@() (hcDamageStatus.value?.hasBreach ?? false) ? CRITICAL : NONE))
    mkTextPart("ui/gameuiskin#ship_crew.svg","ui/gameuiskin#hud_crew_wounded.svg", scale,
      Computed(@() $"{(100 * currentTargetHp.value + 0.5).tointeger()}%"),
      Computed(@() currentTargetHp.value > 0.505 ? 0xFFFFFFFF
        : currentTargetHp.value > 0.005 ? 0xFFFFC000
        : 0XFFFF4040), isTargetRepair)
  ]
}

function shipDmgPanelChildrenCtor(scale) {
  let iconSize = scaleEven(iconSizeBase, scale)
  let iconBgSize = scaleEven(iconBgSizeBase, scale)
  return [
    mkDmgPart("ui/gameuiskin#dmg_ship_artillery.svg", iconSize, iconBgSize,
      Computed(@() getStatusByHealth(hcDamageStatus.value?.artilleryHealth)))
    mkDmgPart("ui/gameuiskin#dmg_ship_fire.svg", iconSize, iconBgSize,
      Computed(@() (hcDamageStatus.value?.hasFire ?? false) ? CRITICAL : NONE))
    mkDmgPart("ui/gameuiskin#dmg_ship_engine.svg", iconSize, iconBgSize,
      Computed(@() getStatusByHealth(hcDamageStatus.value?.engineHealth)))
    mkDmgPart("ui/gameuiskin#dmg_ship_torpedo_tubes.svg", iconSize, iconBgSize,
      Computed(@() getStatusByHealth(hcDamageStatus.value?.torpedoTubesHealth)))
    mkDmgPart("ui/gameuiskin#dmg_ship_rudders.svg", iconSize, iconBgSize,
      Computed(@() getStatusByHealth(hcDamageStatus.value?.ruddersHealth)))
    mkDmgPart("ui/gameuiskin#dmg_ship_breach.svg", iconSize, iconBgSize,
      Computed(@() (hcDamageStatus.value?.hasBreach ?? false) ? CRITICAL : NONE))
    mkTextPart("ui/gameuiskin#ship_crew.svg","ui/gameuiskin#hud_crew_wounded.svg", scale,
      Computed(@() $"{(100 * currentTargetHp.value + 0.5).tointeger()}%"),
      Computed(@() currentTargetHp.value > 0.505 ? 0xFFFFFFFF
        : currentTargetHp.value > 0.005 ? 0xFFFFC000
        : 0XFFFF4040), isTargetRepair)
  ]
}

function tankDmgPanelChildrenCtor(scale) {
  let iconSize = scaleEven(iconSizeBase, scale)
  let iconBgSize = scaleEven(iconBgSizeBase, scale)
  return [
    mkDmgPart("ui/gameuiskin#engine_state_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmAny(isHcUnitKilled.value, hcDmgPartsInfo.value,
        ["tank_engine", "tank_transmission"])))
    mkDmgPart("ui/gameuiskin#gun_state_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmMain(isHcUnitKilled.value, hcDmgPartsInfo.value,
        ["tank_gun_barrel", "tank_cannon_breech"],
        ["gun_barrel_dm", "gun_barrel_01_dm", "cannon_breech_dm", "cannon_breech_01_dm"])))
    mkDmgPart("ui/gameuiskin#turret_gear_state_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmMain(isHcUnitKilled.value, hcDmgPartsInfo.value,
        ["tank_drive_turret_h", "tank_drive_turret_v"],
        ["drive_turret_h_dm", "drive_turret_h_01_dm", "drive_turret_v_dm", "drive_turret_v_01_dm"])))
    mkDmgPart("ui/gameuiskin#track_state_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmAny(isHcUnitKilled.value, hcDmgPartsInfo.value, ["tank_track"])))

    { size = [iconSize, iconSize] }

    mkDmgPart("ui/gameuiskin#crew_gunner_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmAll(isHcUnitKilled.value, hcDmgPartsInfo.value, ["tank_gunner"])))
    mkDmgPart("ui/gameuiskin#crew_driver_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmAll(isHcUnitKilled.value, hcDmgPartsInfo.value, ["tank_driver"])))
    mkDmgPart("ui/gameuiskin#crew_commander_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmAll(isHcUnitKilled.value, hcDmgPartsInfo.value, ["tank_commander"])))
    mkDmgPart("ui/gameuiskin#crew_loader_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmAll(isHcUnitKilled.value, hcDmgPartsInfo.value, ["tank_loader"])))
    mkDmgPart("ui/gameuiskin#crew_machine_gunner_indicator.svg", iconSize, iconBgSize,
      Computed(@() getStateByBrokenDmAll(isHcUnitKilled.value, hcDmgPartsInfo.value, ["tank_machine_gunner"])))
  ]
}

let panelChildrenCtorByType = {
  [SHIP] = shipDmgPanelChildrenCtor,
  [BOAT] = shipDmgPanelChildrenCtor,
  [TANK] = tankDmgPanelChildrenCtor,
  [SAILBOAT] = sailboatDmgPanelChildrenCtor,
}

let hitCameraDmgPanel = @(scale) @() {
  watch = [hcUnitType, hudUnitType]
  size = FLEX_H
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  padding = [round(hdpx(6) * scale), 0]
  children = panelChildrenCtorByType?[hudUnitType.get() == SAILBOAT ? SAILBOAT : hcUnitType.get()](scale)
}

return hitCameraDmgPanel