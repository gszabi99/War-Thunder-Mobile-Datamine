let { loc } = require("dagor.localize")
let { Computed } = require("frp")
let { set_current_unit, curUnitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { curUnit, myUnits, playerLevelInfo, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")


let US_UNKNOWN = 0
let US_OWN = 1
let US_CAN_BUY = 2
let US_TOO_LOW_LEVEL = 3
let US_NOT_FOR_SALE = 4

let buyUnitsData = Computed(function() {
  let { level, isReadyForLevelUp } = playerLevelInfo.value
  let canBuy = {}
  let canBuyOnLvlUp = {}
  local hasOwnUnitForCurrentLevelUp = false
  let unitStatus = allUnitsCfg.value.map(function(unit) {
    if (unit.name in myUnits.value) {
      if (unit.costWp > 0 && !unit.isPremium && unit.rank == level + 1)
        hasOwnUnitForCurrentLevelUp = true
      return US_OWN
    }
    if (unit.costGold <= 0 && unit.costWp <= 0)
      return US_NOT_FOR_SALE
    if (unit.isPremium || unit.rank <= level) {
      canBuy[unit.name] <- unit
      return US_CAN_BUY
    }
    else if (unit.rank == level + 1)
      canBuyOnLvlUp[unit.name] <- unit
    return US_TOO_LOW_LEVEL
  })
  if (isReadyForLevelUp)
    canBuy.__update(canBuyOnLvlUp)
  return { canBuy, canBuyOnLvlUp, unitStatus,
    canLevelUpWithoutBuy = isReadyForLevelUp && hasOwnUnitForCurrentLevelUp
  }
})

let canBuyUnits = Computed(@() buyUnitsData.value.canBuy)
let canBuyUnitsStatus = Computed(@() buyUnitsData.value.unitStatus)

let function getUnitLockedShortText(unit, status, reqPlayerLevel) {
  if (unit == null || status == null || reqPlayerLevel == null)
    return ""
  switch (status) {
    case US_TOO_LOW_LEVEL:
      return " ".concat(loc("multiplayer/level"), reqPlayerLevel)
    case US_NOT_FOR_SALE:
      return loc("options/unavailable")
  }
  return ""
}

let function setCurrentUnit(unitName) {
  if (curUnitInProgress.value != null)
    return "unitInProgress"
  if (unitName not in myUnits.value)
    return "unitNotOwn"
  if (unitName == curUnit.value)
    return "unitIsAlreadyCurrent"

  set_current_unit(unitName)
  return ""
}

return {
  US_UNKNOWN
  US_OWN
  US_NOT_FOR_SALE
  US_CAN_BUY
  US_TOO_LOW_LEVEL

  buyUnitsData
  canBuyUnits
  canBuyUnitsStatus

  getUnitLockedShortText

  setCurrentUnit
}
