from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
import "%sqstd/ecs.nut" as ecs
let { EventOnSupportUnitSpawn } = require("dasevents")
let { setTimeout, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { actionBarItems } = require("actionBar/actionBarState.nut")
let { unitType } = require("%rGui/hudState.nut")
let { MainMask } = require("%rGui/hud/airState.nut")
let { selectActionBarAction } = require("hudActionBar")
let weaponsButtonsConfig = require("%rGui/hud/weaponsButtonsConfig.nut")
let { playHapticPattern, HAPT_WEAP_SELECT } = require("hudHaptic.nut")
let { playSound } = require("sound_wt")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")


const REPAY_TIME = 0.3

let shipWeaponsList = [
  "ID_ZOOM"
  "EII_ROCKET"
//


  "EII_TORPEDO"
  "EII_MINE"
  "EII_DEPTH_CHARGE"
  "EII_MORTAR"
  "EII_SUPPORT_PLANE"
  "EII_SUPPORT_PLANE_2"
  "EII_SUPPORT_PLANE_3"
  "EII_SUPPORT_PLANE_4"
  "EII_DIVING_LOCK"
  "EII_STRATEGY_MODE"
]

let shipGunInsertIdx = 1
let shipGunTriggers = [
  TRIGGER_GROUP_PRIMARY
  TRIGGER_GROUP_SECONDARY
  TRIGGER_GROUP_EXTRA_GUN_1
  TRIGGER_GROUP_EXTRA_GUN_2
  TRIGGER_GROUP_EXTRA_GUN_3
  TRIGGER_GROUP_EXTRA_GUN_4
]

let aircraftWeaponsList = [
  "ID_ZOOM"
  "ID_BOMBS"
  "ID_TORPEDOES"
  "ID_ROCKETS"
  "ID_FIRE_MGUNS"
  "ID_WTM_RETURN_TO_SHIP"
  "ID_WTM_RETURN_TO_SHIP_2"
  "ID_WTM_RETURN_TO_SHIP_3"
  "ID_WTM_RETURN_TO_SHIP_4"
  "ID_WTM_AIRCRAFT_CHANGE"
  "ID_WTM_AIRCRAFT_GROUP_ATTACK"
  "ID_WTM_AIRCRAFT_RETURN"
  "ID_LOCK_TARGET"
  "ID_FIRE_CANNONS"
]

let shipSelectShortcuts = {
  [TRIGGER_GROUP_PRIMARY] = "ID_SHIP_WEAPON_PRIMARY",
  [TRIGGER_GROUP_SECONDARY] = "ID_SHIP_WEAPON_SECONDARY",
  [TRIGGER_GROUP_MACHINE_GUN] = "ID_SHIP_WEAPON_MACHINEGUN",
  [TRIGGER_GROUP_EXTRA_GUN_1] = "ID_SHIP_WEAPON_EXTRA_GUN_1",
  [TRIGGER_GROUP_EXTRA_GUN_2] = "ID_SHIP_WEAPON_EXTRA_GUN_2",
  [TRIGGER_GROUP_EXTRA_GUN_3] = "ID_SHIP_WEAPON_EXTRA_GUN_3",
  [TRIGGER_GROUP_EXTRA_GUN_4] = "ID_SHIP_WEAPON_EXTRA_GUN_4",
}

let fixedPositionWeapons = [
  "ID_ZOOM",
  "EII_SUPPORT_PLANE",
  "EII_SUPPORT_PLANE_2",
  "EII_SUPPORT_PLANE_3",
  "EII_DIVING_LOCK",
  "EII_STRATEGY_MODE"
].reduce(@(res, v) res.__update({ [v] = true }), {})

let weaponsList = Computed(@() unitType.value == AIR ? aircraftWeaponsList
  : unitType.value == TANK ? []
  : shipWeaponsList)

let gunsList = Computed(function() {
  if (unitType.value == AIR || unitType.value == TANK)
    return null

  let actionsByTriggers = {}
  foreach (a in actionBarItems.value)
    actionsByTriggers[a?.triggerGroupNo ?? ""] <- a

  let calibers = {}
  foreach (trigger in shipGunTriggers) {
    let caliber = actionsByTriggers?[trigger].caliber
    if (caliber != null)
      calibers[caliber] <- (calibers?[caliber] ?? 0) + 1
  }

  let counts = {}
  let ordered = calibers.keys().sort(@(a, b) b <=> a)
  ordered.each(@(c, idx) counts[c] <- { total = calibers[c], last = -1, sizeOrder = idx })

  let guns = shipGunTriggers
    .map(function(trigger) {
      let actionItem = actionsByTriggers?[trigger]
      if (actionItem == null || "caliber" not in actionItem)
        return null
      counts[actionItem.caliber].last++
      let { total, last, sizeOrder } = counts[actionItem.caliber]
      return {
        id = trigger
        actionItem
        viewCfg = {
          trigger
          sizeOrder
          number = total == 1 ? -1 : last
          mkButtonFunction = "mkWeaponryItemByTrigger"
          shortcut = "ID_SHIP_WEAPON_ALL"
          selShortcut = shipSelectShortcuts?[trigger]
          hasCrosshair = true
        }
      }
    })
    .filter(@(g) g != null)

  return { insertIdx = shipGunInsertIdx, guns }
})

local visibleWeaponsList = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = []

  let res = []
  let { insertIdx = 0, guns = [] } = gunsList.value
  local gunsIdx = 0
  foreach (idx, weapon in weaponsList.value) {
    let config = weaponsButtonsConfig[weapon]
    local actionItem = null
    if (!(config?.isAlwaysVisible ?? false)) {
      if (config?.flag != null) {
        if (((1 << config.flag) & MainMask.value) == 0)
          continue
      }
      else if (config?.actionType != null) {
        actionItem = actionBarItems.value?[config.actionType]
        if (actionItem == null)
          continue
      }
    }
    res.append({ id = weapon, actionItem })
    if (idx < insertIdx)
      gunsIdx = res.len()
  }

  foreach (gun in guns)
    res.insert(gunsIdx++, gun)

  return isEqual(res, prev) ? prev : res
})

let visibleWeaponsMap = Computed(function() {
  let res = {}
  foreach (item in visibleWeaponsList.value)
    if ("viewCfg" in item)
      res[item.viewCfg.selShortcut] <- {
        actionItem = item.actionItem,
        buttonConfig = item.viewCfg,
        id = item.viewCfg.selShortcut
      }
    else
      res[item.id] <- {
        actionItem = item.actionItem,
        id = item.id
      }
  return res
})

let visibleWeaponsDynamic = Computed(@()
  visibleWeaponsMap.value.filter(@(_, id) id not in fixedPositionWeapons)
    .values().sort(@(a, b) (a?.actionItem.id ?? 0) <=> (b?.actionItem.id ?? 0)))

let userHoldWeapKeys = Watched({})
let userHoldWeapInside = Watched({})
let holdTimers = {}

function markWeapKeyHold(key) {
  if (key in userHoldWeapKeys.value)
    return
  userHoldWeapKeys.mutate(@(v) v[key] <- false)
  function onTimer() {
    holdTimers?.$rawdelete(key)
    userHoldWeapKeys.mutate(@(v) v[key] <- true)
  }
  holdTimers[key] <- onTimer
  setTimeout(REPAY_TIME, onTimer)
}

function unmarkWeapKeyHold(key) {
  if (key in holdTimers) {
    clearTimer(holdTimers[key])
    holdTimers.$rawdelete(key)
  }
  if (key in userHoldWeapKeys.value)
    userHoldWeapKeys.mutate(@(v) v.$rawdelete(key))
  selectActionBarAction("")
}

let defWeaponKey = Computed(@() unitType.value == AIR ? "ID_BOMBS" : TRIGGER_GROUP_PRIMARY)
let currentWeaponInfo = Computed(function() {
  let key = userHoldWeapKeys.value.findindex(@(v) v)
    ?? defWeaponKey.value
  return visibleWeaponsList.value.findvalue(@(v) v.id == key)
})

let currentWeaponKey = keepref(Computed(@() currentWeaponInfo.value?.id))
let getViewCfg = @(curWeaponInfoVal) curWeaponInfoVal?.viewCfg ?? weaponsButtonsConfig?[currentWeaponInfo.value?.id]

function selectActionByViewCfg(viewCfg) {
  let { shortcut = null, getShortcut = null, actionType = null } = viewCfg
  let sc = shortcut ?? getShortcut?(unitType.value, actionBarItems.value?[actionType])
  if (sc != null)
    selectActionBarAction(sc)
}

currentWeaponKey.subscribe(function(id) {
  selectActionByViewCfg(getViewCfg(currentWeaponInfo.value))
  if ((id ?? defWeaponKey.value) != defWeaponKey.value) {
    playSound("weapon_choose")
    playHapticPattern(HAPT_WEAP_SELECT)
  }
})

let currentHoldWeaponName = Computed(function() {
  if (!userHoldWeapKeys.value.findvalue(@(v) v))
    return null
  let { id = null, actionItem = null } = currentWeaponInfo.value
  if (id == null || actionItem == null)
    return null

  local weaponName = actionItem?.weaponName ?? ""
  if (weaponName == "")
    weaponName = actionItem?.bulletName ?? ""

  if (id == "EII_SUPPORT_PLANE" || id == "EII_SUPPORT_PLANE_2" ||
      id == "EII_SUPPORT_PLANE_3" || id == "EII_SUPPORT_PLANE_4")
    return loc(getUnitLocId(weaponName))
  return loc($"weapons/{weaponName}/short")
})

ecs.register_es("on_support_unit_spawned", {
  [EventOnSupportUnitSpawn] = @(_evt, _eid, _comp)
    selectActionByViewCfg(getViewCfg(currentWeaponInfo.value))
})

let hasCrosshairForWeapon = Computed(@() unitType.value == TANK
  || (getViewCfg(currentWeaponInfo.value)?.hasCrosshair ?? false))
let hasAimingModeForWeapon = Computed(@() unitType.value == TANK
  || (getViewCfg(currentWeaponInfo.value)?.hasAimingMode ?? true))
let isCurHoldWeaponInCancelZone = Computed(@() !(userHoldWeapInside.value.findvalue(@(v) !v) ?? true))

let isChainedWeapons = mkWatched(persist, "isChainedWeapons", true)

return {
  visibleWeaponsList
  visibleWeaponsMap
  visibleWeaponsDynamic
  hasCrosshairForWeapon
  hasAimingModeForWeapon
  isCurHoldWeaponInCancelZone
  currentHoldWeaponName
  markWeapKeyHold
  unmarkWeapKeyHold
  userHoldWeapKeys
  userHoldWeapInside
  isChainedWeapons
}
