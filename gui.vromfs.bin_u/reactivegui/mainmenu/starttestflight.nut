from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { ceil } = require("%sqstd/math.nut")
let { SHIP, SUBMARINE } = require("%appGlobals/unitConst.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")

let MAX_SLOTS = 6

let function getBulletsForTestFlight(unitName) {
  let { primary = null, secondary = null } = loadUnitBulletsChoice(unitName)?.commonWeapons
  if (primary == null)
    return null
  let { bulletsOrder, total, catridge, guns } = primary
  let allowed = clone bulletsOrder
  let maxSlots = secondary == null ? MAX_SLOTS : MAX_SLOTS - 1
  if (allowed.len() > maxSlots)
    allowed.resize(maxSlots)
  let stepSize = guns
  local leftSteps = ceil(total.tofloat() / stepSize / catridge) //need send catriges count for spawn instead of bullets count
  let res = allowed.map(function(name, idx) {
    let steps = ceil(leftSteps / (allowed.len() - idx)).tointeger()
    leftSteps -= steps
    return { name, count = steps * stepSize }
  })

  if (secondary != null)
    res.append({ name = secondary.bulletsOrder[0], count = secondary.total })

  return res
}

let function startTestFlight(unitName, missionName = null) {
  if (unitName == null) {
    openMsgBox(loc("No selected unit"))
    return
  }

  let unitType = getUnitType(unitName)
  let params = {
    unitName
    missionName = missionName ?? (unitType == SHIP || unitType == SUBMARINE
      ? "testFlight_destroyer_usa_tfs"
      : "testFlight_ussr_tft")
    bullets = getBulletsForTestFlight(unitName)
  }
  let pkgs = getUnitPkgs(unitName, serverConfigs.value?.allUnits[unitName].mRank ?? 1)
    .filter(@(v) !hasAddons.value?[v])
  if (pkgs.len() == 0)
    send("startTestFlight", params)
  else
    openDownloadAddonsWnd(pkgs, "startTestFlight", params)
}

return startTestFlight