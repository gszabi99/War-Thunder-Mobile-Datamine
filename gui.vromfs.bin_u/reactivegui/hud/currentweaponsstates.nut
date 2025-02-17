from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
import "%sqstd/ecs.nut" as ecs
let { EventOnSupportUnitSpawn } = require("dasevents")
let { setTimeout, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { actionBarItems } = require("actionBar/actionBarState.nut")
let { unitType, HM_MANUAL_ANTIAIR } = require("%rGui/hudState.nut")
let { MainMask } = require("%rGui/hud/airState.nut")
let { selectActionBarAction } = require("hudActionBar")
let weaponsButtonsConfig = require("%rGui/hud/weaponsButtonsConfig.nut")
let { playHapticPattern, HAPT_WEAP_SELECT } = require("hudHaptic.nut")
let { playSound } = require("sound_wt")


const REPAY_TIME = 0.3

let shipWeaponsList = [
  "EII_ROCKET"
  "EII_ROCKET_SECONDARY"
  "EII_TORPEDO"
  "EII_MINE"
  "EII_DEPTH_CHARGE"
  "EII_MORTAR"
]

let shipGunInsertIdx = 1
let shipGunTriggers = [
  TRIGGER_GROUP_PRIMARY
  TRIGGER_GROUP_SECONDARY
  TRIGGER_GROUP_EXTRA_GUN_1
  TRIGGER_GROUP_EXTRA_GUN_2
  TRIGGER_GROUP_EXTRA_GUN_3
  TRIGGER_GROUP_EXTRA_GUN_4
  TRIGGER_GROUP_MACHINE_GUN
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

let shipRocketShortcuts = {
  EII_ROCKET = "ID_SHIP_WEAPON_ROCKETS",
  EII_ROCKET_SECONDARY = "ID_SHIP_WEAPON_ROCKETS_SECONDARY",
}

let shipGunHudModes = {
  [TRIGGER_GROUP_MACHINE_GUN] = HM_MANUAL_ANTIAIR
}

let weaponsList = Computed(@() unitType.get() == AIR || unitType.get() == TANK ? []
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
        hudMode = shipGunHudModes?[trigger]
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
  let explosiveMass = {}
  foreach (_, weapon in weaponsList.value) {
    let actionType = weaponsButtonsConfig[weapon]?.actionType
    if(actionType != null) {
      let mass = actionBarItems.value?[actionType]?.explosiveMass
      if (mass != null && mass > 0)
        explosiveMass[mass] <- (explosiveMass?[mass] ?? 0) + 1
    }
  }
  let counts = {}
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

    if ((weapon == "EII_ROCKET" || weapon == "EII_ROCKET_SECONDARY")
      && "explosiveMass" in actionItem && actionItem.explosiveMass > 0) {
      counts[actionItem.explosiveMass] <- (counts?[actionItem.explosiveMass] ?? -1) + 1
      let viewCfg = {
        selShortcut = shipRocketShortcuts?[weapon]
        number = explosiveMass[actionItem.explosiveMass] == 0 ? -1 : counts[actionItem.explosiveMass]
      }.__merge(config)
      if(counts[actionItem.explosiveMass] > 0)
        viewCfg.getImage <- weaponsButtonsConfig["EII_ROCKET"].getImage
      res.append({ id = weapon, actionItem, viewCfg })
    }
    else
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
        hudMode = item?.hudMode
      }
    else
      res[item.id] <- {
        actionItem = item.actionItem,
        id = item.id
        hudMode = item?.hudMode
      }
  return res
})

let visibleWeaponsDynamic = Computed(@()
  visibleWeaponsMap.get()
    .values().sort(@(a, b) (a?.actionItem.id ?? 0) <=> (b?.actionItem.id ?? 0)))

let userHoldWeapKeys = Watched({})
let userHoldWeapInside = Watched({})
let holdTimers = {}

function markWeapKeyHold(key, name = null, isOnlyHint = false) {
  if (key in userHoldWeapKeys.get() && userHoldWeapKeys.get()[key].name == name)
    return
  userHoldWeapKeys.mutate(@(v) v[key] <- { name, isHold = false, isOnlyHint })

  if (key in holdTimers)
    return
  function onTimer() {
    holdTimers?.$rawdelete(key)
    userHoldWeapKeys.mutate(@(v) v[key] <- v[key].__merge({ isHold = true }))
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
  let key = userHoldWeapKeys.value.findindex(@(v) v.isHold && !v.isOnlyHint)
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
  let weapInfo = userHoldWeapKeys.value.findvalue(@(v) v.isHold)
  if (weapInfo == null)
    return null
  if (weapInfo.name != null)
    return weapInfo.name
  let { id = null, actionItem = null } = currentWeaponInfo.value
  if (id == null || actionItem == null)
    return null

  local weaponName = actionItem?.weaponName ?? ""
  if (weaponName == "")
    weaponName = actionItem?.bulletName ?? ""

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

return {
  visibleWeaponsList
  visibleWeaponsDynamic
  hasCrosshairForWeapon
  hasAimingModeForWeapon
  isCurHoldWeaponInCancelZone
  currentHoldWeaponName
  markWeapKeyHold
  unmarkWeapKeyHold
  userHoldWeapKeys
  userHoldWeapInside
}
