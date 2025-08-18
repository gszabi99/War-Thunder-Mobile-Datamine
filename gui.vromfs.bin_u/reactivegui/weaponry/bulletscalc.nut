from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { AIR, SAILBOAT } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getUnitBeltsNonUpdatable } = require("%rGui/unitMods/unitModsSlotsState.nut")


let MAX_SLOTS = 2
let MAX_SLOTS_SAILBOAT = 3

function collectBulletsCount(bulletsCfg, level, maxSlots) {
  let { fromUnitTags, bulletsOrder, total, catridge, guns } = bulletsCfg
  let allowed = bulletsOrder.filter(@(bullet) (fromUnitTags?[bullet].reqLevel ?? -1) <= level)
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
    let belts = getUnitBeltsNonUpdatable(unitName, mods)
    foreach(name in belts)
      res.append({ name, count = 10000 })
    return res
  }

  let { primary = null, secondary = null, special = null } = loadUnitBulletsChoice(unitName)?.commonWeapons
  if (primary == null)
    return [{ name = "", count = 10000 }]

  local maxSlots = unitType == SAILBOAT ? MAX_SLOTS_SAILBOAT : MAX_SLOTS

  res.extend(collectBulletsCount(primary, level, maxSlots))
  if (secondary != null)
    res.extend(collectBulletsCount(secondary, level, maxSlots))

  if (special != null)
    res.append({ name = special.bulletsOrder[0], count = special.total })
  return res
}

return {
  getDefaultBulletsForSpawn
}