from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { AB_TORPEDO, AB_TOOLKIT, AB_EXTINGUISHER, AB_SMOKE_SCREEN, AB_SMOKE_GRENADE, AB_MEDICALKIT, AB_DEPTH_CHARGE,
  AB_MINE, AB_MORTAR, AB_ROCKET, AB_SUPPORT_PLANE, AB_SUPPORT_PLANE_2, AB_SUPPORT_PLANE_3, AB_SUPPORT_PLANE_4, AB_SUPPORT_PLANE_CHANGE,
  AB_SUPPORT_PLANE_GROUP_ATTACK, AB_DIVING_LOCK,
  AB_SPECIAL_FIGHTER, AB_SPECIAL_BOMBER, AB_ARTILLERY_TARGET
} = require("actionBar/actionType.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { HAPT_SHOOT_TORPEDO, HAPT_SHOOT_MINES, HAPT_REPAIR, HAPT_SMOKE
} = require("hudHaptic.nut")
let aircraftWeaponsItems = require("%rGui/hud/aircraftWeaponsItems.nut")

let function getActionBarShortcut(unitType, itemConfig) {
  let shortcutIdx = itemConfig.shortcutIdx
  if (shortcutIdx < 0)
    return ""

  return unitType == TANK ? $"ID_ACTION_BAR_ITEM_{shortcutIdx + 1}"
    : unitType == SUBMARINE ? $"ID_SUBMARINE_ACTION_BAR_ITEM_{shortcutIdx + 1}"
    : $"ID_SHIP_ACTION_BAR_ITEM_{shortcutIdx + 1}"
}

let actionBarItemsConfig = {
  EII_TORPEDO = {
    getShortcut = @(unitType, __) unitType == SUBMARINE ? "ID_SUBMARINE_WEAPON_TORPEDOES" : "ID_SHIP_WEAPON_TORPEDOES"
    getImage = @(_) "!ui/gameuiskin#hud_torpedo.svg"
    relImageSize = 0.85
    actionType = AB_TORPEDO
    mkButtonFunction = "mkSubmarineWeaponryItem"
    canShootWithoutTarget = true
    needCheckTargetReachable = true
    hasAim = true
    haptPatternId = HAPT_SHOOT_TORPEDO
  },
  EII_TOOLKIT = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "!ui/gameuiskin#hud_consumable_repair.svg"
    actionType = AB_TOOLKIT
    mkButtonFunction = "mkRepairActionItem"
    haptPatternId = HAPT_REPAIR
    getAnimationKey = @(unitType) unitType == TANK ? "tank_tool_kit_expendable" : "ship_tool_kit"
  },
  EII_EXTINGUISHER = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "!ui/gameuiskin#fire_indicator.svg"
    actionType = AB_EXTINGUISHER
    mkButtonFunction = "mkRepairActionItem"
    haptPatternId = HAPT_REPAIR
    actionKey = "btn_extinguisher"
    getAnimationKey = @(_) "tank_extinguisher"
  },
  EII_SMOKE_SCREEN = {
    getShortcut = @(unitType, __) unitType == SUBMARINE ? "ID_SUBMARINE_ACOUSTIC_COUNTERMEASURES"
      : unitType == TANK ? "ID_SMOKE_SCREEN_GENERATOR"
      : "ID_SHIP_SMOKE_SCREEN_GENERATOR"
    getImage = @(unitType) unitType == TANK
      ? "!ui/gameuiskin#hud_consumable_smoke_tank.svg"
      : "!ui/gameuiskin#hud_consumable_smoke.svg"
    actionType = AB_SMOKE_SCREEN
    mkButtonFunction = "mkActionItem"
    haptPatternId = HAPT_SMOKE
    sound = "smoke"
    getAnimationKey = @(_) "ship_smoke_screen_system_mod"
  },
  EII_SMOKE_GRENADE = {
    getShortcut = @(unitType, __) unitType == TANK ? "ID_SMOKE_SCREEN" : "ID_SHIP_SMOKE_GRENADE"
    getImage = @(unitType) unitType == TANK
      ? "!ui/gameuiskin#hud_smoke_grenade_tank.svg"
      : "!ui/gameuiskin#hud_consumable_smoke.svg"
    actionType = AB_SMOKE_GRENADE
    mkButtonFunction = "mkActionItem"
    haptPatternId = HAPT_SMOKE
  }
  EII_MEDICALKIT = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "!ui/gameuiskin#hud_consumable_repair.svg"
    actionType = AB_MEDICALKIT
    mkButtonFunction = "mkRepairActionItem"
  },
  EII_DEPTH_CHARGE = {
    getShortcut = @(unitType, __) unitType == SUBMARINE ? "ID_SUBMARINE_WEAPON_DEPTH_CHARGE" : "ID_SHIP_WEAPON_DEPTH_CHARGE"
    getImage = @(_) "!ui/gameuiskin#hud_depth_charge.svg"
    actionType = AB_DEPTH_CHARGE
    mkButtonFunction = "mkWeaponryItem"
    hasAimingMode = false
  },
  EII_MINE = {
    getShortcut = @(_, __) "ID_SHIP_WEAPON_MINE"
    getImage = @(_) "!ui/gameuiskin#hud_naval_mine.svg"
    actionType = AB_MINE
    mkButtonFunction = "mkWeaponryItem"
    hasAimingMode = false
    haptPatternId = HAPT_SHOOT_MINES
  },
  EII_MORTAR = {
    getShortcut = @(_, __) "ID_SHIP_WEAPON_MORTAR"
    getImage = @(_) "!ui/gameuiskin#hud_ship_mortar.svg"
    actionType = AB_MORTAR
    mkButtonFunction = "mkWeaponryItem"
  },
  EII_ROCKET = {
    getShortcut = @(unitType, __) unitType == SUBMARINE ? "ID_SUBMARINE_WEAPON_ROCKETS" : "ID_SHIP_WEAPON_ROCKETS"
    getImage = @(_) "!ui/gameuiskin#hud_missile_anti_ship.svg"
    actionType = AB_ROCKET
    mkButtonFunction = "mkWeaponryItem"
  },
  EII_SUPPORT_PLANE = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT"
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_fighter.svg"
    getAlternativeImage = @() "!ui/gameuiskin#hud_aircraft_fighter_in_air.svg"
    actionType = AB_SUPPORT_PLANE
    weaponPlacePosIdx = 7
    mkButtonFunction = "mkWeaponryItem"
    getWeaponLocText = @(weaponName) $"{loc("mainmenu/type_air")} {loc(getUnitLocId(weaponName))}"
  },
  EII_SUPPORT_PLANE_2 = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT_2"
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_fighter.svg"
    getAlternativeImage = @() "!ui/gameuiskin#hud_aircraft_fighter_in_air.svg"
    actionType = AB_SUPPORT_PLANE_2
    weaponPlacePosIdx = 5
    mkButtonFunction = "mkWeaponryItem"
    getWeaponLocText = @(weaponName) $"{loc("mainmenu/type_air")} {loc(getUnitLocId(weaponName))}"
  },
  EII_SUPPORT_PLANE_3 = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT_3"
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_fighter.svg"
    getAlternativeImage = @() "!ui/gameuiskin#hud_aircraft_fighter_in_air.svg"
    actionType = AB_SUPPORT_PLANE_3
    weaponPlacePosIdx = 4
    mkButtonFunction = "mkWeaponryItem"
    getWeaponLocText = @(weaponName) $"{loc("mainmenu/type_air")} {loc(getUnitLocId(weaponName))}"
  },
  EII_SUPPORT_PLANE_4 = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT_4"
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_fighter.svg"
    getAlternativeImage = @() "!ui/gameuiskin#hud_aircraft_fighter_in_air.svg"
    actionType = AB_SUPPORT_PLANE_4
    weaponPlacePosIdx = 8
    mkButtonFunction = "mkWeaponryItem"
    getWeaponLocText = @(weaponName) $"{loc("mainmenu/type_air")} {loc(getUnitLocId(weaponName))}"
  },
  ID_WTM_AIRCRAFT_CHANGE = {
    getShortcut = @(_, __) "ID_WTM_AIRCRAFT_CHANGE"
    image = "!ui/gameuiskin#hud_aircraft_fighter.svg"
    mkButtonFunction = "mkSimpleButton"
    actionType = AB_SUPPORT_PLANE_CHANGE
    weaponPlacePosIdx = 6
  },
  ID_WTM_AIRCRAFT_GROUP_ATTACK = {
    getShortcut = @(_, __) "ID_WTM_AIRCRAFT_GROUP_ATTACK"
    mkButtonFunction = "mkGroupAttackButton"
    actionType = AB_SUPPORT_PLANE_GROUP_ATTACK
    weaponPlacePosIdx = 6
  },
  EII_DIVING_LOCK = {
    getShortcut = @(_, __) "ID_DIVING_LOCK"
    actionType = AB_DIVING_LOCK
    weaponPlacePosIdx = 7
    mkButtonFunction = "mkDivingLockButton"
  },
  ID_WTM_RETURN_TO_SHIP = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT"
    image = "!ui/gameuiskin#hud_ship_selection.svg"
    mkButtonFunction = "mkSimpleButton"
    actionType = AB_SUPPORT_PLANE
    weaponPlacePosIdx = 4
  },
  ID_WTM_RETURN_TO_SHIP_2 = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT_2"
    image = "!ui/gameuiskin#hud_ship_selection.svg"
    mkButtonFunction = "mkSimpleButton"
    actionType = AB_SUPPORT_PLANE_2
    weaponPlacePosIdx = 4
  },
  ID_WTM_RETURN_TO_SHIP_3 = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT_3"
    image = "!ui/gameuiskin#hud_ship_selection.svg"
    mkButtonFunction = "mkSimpleButton"
    actionType = AB_SUPPORT_PLANE_3
    weaponPlacePosIdx = 4
  },
  ID_WTM_RETURN_TO_SHIP_4 = {
    getShortcut = @(_, __) "ID_WTM_LAUNCH_AIRCRAFT_4"
    image = "!ui/gameuiskin#hud_ship_selection.svg"
    mkButtonFunction = "mkSimpleButton"
    actionType = AB_SUPPORT_PLANE_4
    weaponPlacePosIdx = 4
  },
  ID_LOCK_TARGET = {
    getShortcut = @(_, __) "ID_LOCK_TARGET"
    mkButtonFunction = "mkLockButton"
    weaponPlacePosIdx = 7
    isAlwaysVisible = true
  },
  ID_ZOOM = {
    getShortcut = @(_, __) "ID_ZOOM_TOGGLE"
    mkButtonFunction = "mkZoomButton"
    weaponPlacePosIdx = 0
    isAlwaysVisible = true
  },
  ID_FIRE_CANNONS = {
    flag = AirParamsMain.CANNON_1
    getShortcut = @(_, __) "ID_FIRE_CANNONS"
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_canons.svg"
    mkButtonFunction = "mkWeaponryContinuousSelfAction"
    itemComputed = aircraftWeaponsItems.cannon
    weaponPlacePosIdx = 3
    additionalShortcutId = "ID_FIRE_MGUNS"
  },
  ID_FIRE_MGUNS = {
    flag = AirParamsMain.MACHINE_GUNS_1
    getShortcut = @(_, __) "ID_FIRE_MGUNS"
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_machine_gun.svg"
    mkButtonFunction = "mkWeaponryContinuousSelfAction"
    hasAim = true
    itemComputed = aircraftWeaponsItems.mGun
    hasCrosshair = true
    weaponPlacePosIdx = 2
    additionalShortcutId = "ID_FIRE_CANNONS"
    drawChain = true
  },
  ID_BOMBS = {
    flag = AirParamsMain.BOMBS
    getShortcut = @(_, __) "ID_BOMBS"
    getImage = @(_) "!ui/gameuiskin#hud_bomb.svg"
    mkButtonFunction = "mkWeaponryItemSelfAction"
    itemComputed = aircraftWeaponsItems.bomb
    canLowerCamera = true
  },
  ID_TORPEDOES = {
    flag = AirParamsMain.TORPEDO
    getShortcut = @(_, __) "ID_BOMBS"
    getImage = @(_) "!ui/gameuiskin#hud_torpedo.svg"
    mkButtonFunction = "mkWeaponryItemSelfAction"
    itemComputed = aircraftWeaponsItems.torpedo
    canLowerCamera = true
  },
  ID_ROCKETS = {
    flag = AirParamsMain.ROCKET
    getShortcut = @(_, __) "ID_ROCKETS"
    getImage = @(_) "!ui/gameuiskin#hud_rb_rocket.svg"
    relImageSize = 0.8
    mkButtonFunction = "mkWeaponryItemSelfAction"
    weaponPlacePosIdx = 5
    hasAim = true
    itemComputed = aircraftWeaponsItems.rocket
    hasCrosshair = true
  },
  EII_SPECIAL_UNIT = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_fighter.svg"
    actionType = AB_SPECIAL_FIGHTER
    mkButtonFunction = "mkActionItem"
  },
  EII_SPECIAL_UNIT_2 = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "!ui/gameuiskin#hud_aircraft_bomber.svg"
    actionType = AB_SPECIAL_BOMBER
    mkButtonFunction = "mkActionItem"
  }
  EII_ARTILLERY_TARGET = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "!ui/gameuiskin#hud_artillery_fire.svg"
    actionType = AB_ARTILLERY_TARGET
    mkButtonFunction = "mkActionItem"
  }
}.map(@(cfg, key) cfg.__update({ key }))

return actionBarItemsConfig
