from "%globalsDarg/darg_library.nut" import *
from "math" import ceil
from "%appGlobals/unitConst.nut" import AIR, SAILBOAT
from "%appGlobals/unitTags.nut" import getUnitType
from "%rGui/unitMods/unitModsSlotsState.nut" import getUnitBeltsNonUpdatable
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitBulletsChoice


const MAX_SLOTS = 2
const MAX_SLOTS_SAILBOAT = 3

function collectBulletsCount(bulletsCfg, level, maxSlots, mods) {
  let { fromUnitTags, bulletsOrder, total, catridge, guns } = bulletsCfg
  let allowed = bulletsOrder.filter(@(bullet) (fromUnitTags?[bullet].reqLevel ?? -1) <= level
    && (fromUnitTags?[bullet].reqModification == null || mods?[fromUnitTags?[bullet].reqModification]))
  if (allowed.len() > maxSlots)
    allowed.resize(maxSlots)
  let stepSize = guns
  local leftSteps = ceil(total.tofloat() / stepSize / catridge) 
  return allowed.map(function(name, idx) {
    let steps = ceil(leftSteps / (allowed.len() - idx)).tointeger()
    leftSteps -= steps
    return { name, count = steps * stepSize }
  })
}

function getDefaultBulletsForSpawn(unitName, level, mods = null) {
  let res = []
  let unitType = getUnitType(unitName)
  if (unitType == AIR) {
    foreach (weaponId, name in getUnitBeltsNonUpdatable(unitName, mods))
      res.append({ weaponId, name, count = 10000 })

    return res
  }

  let { primary = null, secondary = null, special = null } = loadUnitBulletsChoice(unitName)?.commonWeapons
  if (primary == null)
    return [{ name = "", count = 10000 }]

  local maxSlots = unitType == SAILBOAT ? MAX_SLOTS_SAILBOAT : MAX_SLOTS

  res.extend(collectBulletsCount(primary, level, maxSlots, mods))
  if (secondary != null)
    res.extend(collectBulletsCount(secondary, level, maxSlots, mods))

  if (special != null)
    res.append({ name = special.bulletsOrder[0], count = special.total })
  return res
}

return {
  getDefaultBulletsForSpawn
}