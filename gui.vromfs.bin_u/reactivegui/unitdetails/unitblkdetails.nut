from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "vehicleModel" import getUnitFileName
from "%sqstd/datablock.nut" import blkOptFromPath


let detailsCache = persist("detailsCache", @() {})

function loadUnitBlkDetails(unitName) {
  let unitBlk = blkOptFromPath(getUnitFileName(unitName))
  let { modifications = null, ForceFiniteFuel0 = false, ForceFiniteFuel1 = false, ForceFiniteFuel2 = false } = unitBlk
  return {
    hasShipSmokeScreen = "ship_smoke_screen_system_mod" in modifications
    hasFuel = ForceFiniteFuel0 || ForceFiniteFuel1 || ForceFiniteFuel2
  }
}

function getUnitBlkDetails(unitName) {
  if (unitName not in detailsCache)
    detailsCache[unitName] <- loadUnitBlkDetails(unitName)
  return detailsCache[unitName]
}

register_command(@(unitName) log($"Unit {unitName} blk details: ", getUnitBlkDetails(unitName)),
  "debug.get_unit_blk_details")

return {
  getUnitBlkDetails
}