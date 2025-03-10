from "%globalsDarg/darg_library.nut" import *
let { AIR, HELICOPTER, TANK, SHIP, BOAT, SUBMARINE } = require("%appGlobals/unitConst.nut")
let { S_UNDEFINED, S_AIRCRAFT, S_HELICOPTER, S_TANK, S_SHIP, S_BOAT, S_SUBMARINE
} = require("%globalScripts/modeXrayLib.nut")

let unitTypeToSimpleUnitTypeMap = {
  [AIR] = S_AIRCRAFT,
  [HELICOPTER] = S_HELICOPTER,
  [TANK] = S_TANK,
  [SHIP] = S_SHIP,
  [BOAT] = S_BOAT,
  [SUBMARINE] = S_SUBMARINE,
}

let getSimpleUnitType = @(unit) unitTypeToSimpleUnitTypeMap?[unit?.unitType] ?? S_UNDEFINED

return {
  getSimpleUnitType
}
