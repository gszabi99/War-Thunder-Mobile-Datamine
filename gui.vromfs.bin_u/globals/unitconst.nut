
let unitTypes = {
  AIR = "air"
  TANK = "tank"
  SHIP = "ship"
  HELICOPTER = "helicopter"
  BOAT = "boat"
  SUBMARINE = "submarine"
  SAILBOAT = "sailboat"
}

let bitsOrder = ["AIR", "TANK", "SHIP", "HELICOPTER", "BOAT", "SUBMARINE", "SAILBOAT"]
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

function calcUnitTypeFromTags(tagsCfg) {
  let { tags = null } = tagsCfg
  if ("submarine" in tags)
    return unitTypes.SUBMARINE
  if ("sailboat" in tags)
    return unitTypes.SAILBOAT
  if ("boat" in tags)
    return unitTypes.BOAT
  if ("ship" in tags)
    return unitTypes.SHIP
  if ("tank" in tags)
    return unitTypes.TANK
  if (tags?.type == "aircraft")
    return unitTypes.AIR
  return tags?.type ?? unitTypes.AIR
}

return freeze(unitTypes.__merge(bits, {
  ALL_UNIT_TYPE_MASK
  unitTypeOrder = [unitTypes.SHIP, unitTypes.BOAT, unitTypes.SUBMARINE, unitTypes.AIR, unitTypes.HELICOPTER, unitTypes.TANK]
  unitTypeToBit = @(ut) unitTypeToBitTbl?[ut] ?? 0
  bitToUnitType = @(bit) bitToUnitTypeTbl?[bit] ?? ""
  calcUnitTypeFromTags
}))