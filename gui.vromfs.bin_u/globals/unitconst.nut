//checked for explicitness
#no-root-fallback
#explicit-this

let unitTypes = {
  AIR = "air"
  TANK = "tank"
  SHIP = "ship"
  HELICOPTER = "helicopter"
  BOAT = "boat"
  SUBMARINE = "submarine"
}

let bitsOrder = ["AIR", "TANK", "SHIP", "HELICOPTER", "BOAT", "SUBMARINE"]
let bits = {}
let unitTypeToBitTbl = {}
let bitToUnitTypeTbl = {}
local ALL_UNIT_TYPE_MASK = 0
foreach (idx, id in bitsOrder) {
  let bit = 1 << idx
  bits[$"BIT_{id}"] <- bit
  unitTypeToBitTbl[unitTypes[id]] <- bit
  bitToUnitTypeTbl[bit] <- unitTypes[id]
  ALL_UNIT_TYPE_MASK = ALL_UNIT_TYPE_MASK | bit
}

return freeze(unitTypes.__merge(bits, {
  ALL_UNIT_TYPE_MASK
  unitTypeToBit = @(ut) unitTypeToBitTbl?[ut] ?? 0
  bitToUnitType = @(bit) bitToUnitTypeTbl?[bit] ?? ""
  unitTypeOrder = [unitTypes.SHIP, unitTypes.BOAT, unitTypes.SUBMARINE, unitTypes.AIR, unitTypes.HELICOPTER, unitTypes.TANK]
}))