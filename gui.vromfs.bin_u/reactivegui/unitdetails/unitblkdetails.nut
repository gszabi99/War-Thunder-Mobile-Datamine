from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { getUnitFileName } = require("vehicleModel")
let { blkOptFromPath } = require("%sqstd/datablock.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")

let detailsCache = persist("detailsCache", @() {})

function loadUnitBlkDetails(unitName) {
  let unitBlk = blkOptFromPath(getUnitFileName(unitName))
  let { modifications = null, ForceFiniteFuel0 = false, ForceFiniteFuel1 = false, ForceFiniteFuel2 = false } = unitBlk
  return {
    hasShipSmokeScreen = "ship_smoke_screen_system_mod" in modifications
    hasFuel = ForceFiniteFuel0 || ForceFiniteFuel1 || ForceFiniteFuel2
  }
}

function getUnitBlkDetails(realUnitName) {
  let unitName = getTagsUnitName(realUnitName)
  if (unitName not in detailsCache)
    detailsCache[unitName] <- loadUnitBlkDetails(unitName)
  return detailsCache[unitName]
}

register_command(@(unitName) log($"Unit {unitName} blk details: ", getUnitBlkDetails(unitName)),
  "debug.get_unit_blk_details")

return {
  getUnitBlkDetails
}