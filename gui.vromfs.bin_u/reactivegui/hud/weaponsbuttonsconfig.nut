from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { AB_TORPEDO, AB_TOOLKIT, AB_EXTINGUISHER, AB_SMOKE_SCREEN, AB_SMOKE_GRENADE, AB_MEDICALKIT, AB_DEPTH_CHARGE,
  AB_MINE, AB_MORTAR, AB_ROCKET, AB_ROCKET_SECONDARY,
  AB_SPECIAL_FIGHTER, AB_SPECIAL_BOMBER, AB_ARTILLERY_TARGET, AB_IRCM, AB_ELECTRONIC_WARFARE
} = require("actionBar/actionType.nut")
let { HAPT_SHOOT_TORPEDO, HAPT_SHOOT_MINES, HAPT_REPAIR, HAPT_SMOKE, HAPT_IRCM } = require("hudHaptic.nut")

function getActionBarShortcut(unitType, itemConfig) {
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
    getImage = @(_) "ui/gameuiskin#hud_torpedo.svg"
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
    getImage = @(_) "ui/gameuiskin#hud_consumable_repair.svg"
    actionType = AB_TOOLKIT
    mkButtonFunction = "mkRepairActionItem"
    haptPatternId = HAPT_REPAIR
    getAnimationKey = @(unitType) unitType == TANK ? "tank_tool_kit_expendable" : "ship_tool_kit"
  },
  EII_EXTINGUISHER = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "ui/gameuiskin#fire_indicator.svg"
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
      ? "!ui/gameuiskin#hud_smoke_grenade_tank.svg"
      : "!ui/gameuiskin#hud_consumable_smoke.svg"
    actionType = AB_SMOKE_SCREEN
    mkButtonFunction = "mkActionItem"
    haptPatternId = HAPT_SMOKE
    sound = "smoke"
    getAnimationKey = @(_) "ship_smoke_screen_system_mod"
  },
  EII_IRCM = {
    getShortcut = @(_, __) "ID_IRCM_SWITCH_SHIP"
    getImage = @(_) "ui/gameuiskin#icon_ircm.svg"
    actionType = AB_IRCM
    mkButtonFunction = "mkCountermeasureItem"
    haptPatternId = HAPT_IRCM
  }
  EII_ELECTRONIC_WARFARE = {
    getShortcut = @(_, __) "ID_ELECTRONIC_WARFARE"
    getImage = @(_) "ui/gameuiskin#icon_capture_blocker.svg"
    alternativeImage = @(_) "ui/gameuiskin#icon_rocket_blocker.svg"
    actionType = AB_ELECTRONIC_WARFARE
    mkButtonFunction = "mkCountermeasureItem"
    haptPatternId = HAPT_IRCM
  }
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
    getImage = @(_) "ui/gameuiskin#hud_consumable_repair.svg"
    actionType = AB_MEDICALKIT
    mkButtonFunction = "mkRepairActionItem"
  },
  EII_DEPTH_CHARGE = {
    getShortcut = @(unitType, __) unitType == SUBMARINE ? "ID_SUBMARINE_WEAPON_DEPTH_CHARGE" : "ID_SHIP_WEAPON_DEPTH_CHARGE"
    getImage = @(_) "ui/gameuiskin#hud_depth_charge.svg"
    actionType = AB_DEPTH_CHARGE
    mkButtonFunction = "mkWeaponryItem"
    hasAimingMode = false
    canShipLowerCamera = true
  },
  EII_MINE = {
    getShortcut = @(_, __) "ID_SHIP_WEAPON_MINE"
    getImage = @(_) "ui/gameuiskin#hud_naval_mine.svg"
    actionType = AB_MINE
    mkButtonFunction = "mkWeaponryItem"
    hasAimingMode = false
    haptPatternId = HAPT_SHOOT_MINES
    canShipLowerCamera = true
  },
  EII_MORTAR = {
    getShortcut = @(_, __) "ID_SHIP_WEAPON_MORTAR"
    getImage = @(_) "ui/gameuiskin#hud_depth_charge.svg"
    alternativeImage = "ui/gameuiskin#hud_ship_mortar.svg"
    actionType = AB_MORTAR
    mkButtonFunction = "mkWeaponryItem"
    canShipLowerCamera = true
  },
  EII_ROCKET = {
    getShortcut = @(unitType, __) unitType == SUBMARINE ? "ID_SUBMARINE_WEAPON_ROCKETS" : "ID_SHIP_WEAPON_ROCKETS"
    getImage = @(_) "ui/gameuiskin#hud_missile_anti_ship.svg"
    actionType = AB_ROCKET
    mkButtonFunction = "mkSubmarineWeaponryItem"
    hasAim = true
    needCheckRocket = true
    relImageSize = 0.85
  },
  EII_ROCKET_SECONDARY = {
    getShortcut = @(_, __) "ID_SHIP_WEAPON_ROCKETS_SECONDARY"
    getImage = @(_) "ui/gameuiskin#hud_missile_ship_secondary.svg"
    actionType = AB_ROCKET_SECONDARY
    mkButtonFunction = "mkSubmarineWeaponryItem"
    hasAim = true
    needCheckRocket = true
    relImageSize = 0.85
  },
  EII_SPECIAL_UNIT = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "ui/gameuiskin#hud_aircraft_fighter.svg"
    actionType = AB_SPECIAL_FIGHTER
    mkButtonFunction = "mkActionItem"
  },
  EII_SPECIAL_UNIT_2 = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "ui/gameuiskin#hud_aircraft_bomber.svg"
    actionType = AB_SPECIAL_BOMBER
    mkButtonFunction = "mkActionItem"
  }
  EII_ARTILLERY_TARGET = {
    getShortcut = getActionBarShortcut
    getImage = @(_) "ui/gameuiskin#hud_artillery_fire.svg"
    actionType = AB_ARTILLERY_TARGET
    mkButtonFunction = "mkActionItem"
  }
}.map(@(cfg, key) cfg.__update({ key }))

return actionBarItemsConfig
