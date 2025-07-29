let { loc } = require("dagor.localize")
let { Computed } = require("frp")
let { set_current_unit, curUnitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { campMyUnits, playerLevelInfo, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")


let US_UNKNOWN = 0
let US_OWN = 1
let US_CAN_BUY = 2
let US_TOO_LOW_LEVEL = 3
let US_NOT_FOR_SALE = 4
let US_NOT_RESEARCHED = 5
let US_NEED_BLUEPRINTS = 6
let US_CAN_RESEARCH = 7

let buyUnitsData = Computed(function() {
  let { level, isReadyForLevelUp } = playerLevelInfo.get()
  let { unitsResearch = {}, blueprints = {} } = servProfile.get()
  let { unitTreeNodes = {}, unitResearchExp = {}, allBlueprints = {} } = serverConfigs.get()
  let canBuy = {}
  let canBuyOnLvlUp = {}
  local hasOwnUnitForCurrentLevelUp = false
  let unitStatus = campUnitsCfg.get().map(function(unit) {
    let { name, rank } = unit
    if (name in campMyUnits.get()) {
      if (rank == level + 1)
        hasOwnUnitForCurrentLevelUp = true
      return US_OWN
    }
    if (unit.costGold <= 0 && unit.costWp <= 0)
      return US_NOT_FOR_SALE

    if (name in allBlueprints) {
      if ((blueprints?[name] ?? 0) >= (allBlueprints?[name]?.targetCount ?? 0)) {
        canBuy[name] <- unit
        return US_CAN_BUY
      }
      return US_NEED_BLUEPRINTS
    }
    if(unitsResearch?[name].canResearch)
      return US_CAN_RESEARCH
    if (unit.isPremium
        || (name not in unitTreeNodes?[unit.campaign] && rank <= level)
        || (name in unitResearchExp && unitsResearch?[name].canBuy)) {
      canBuy[name] <- unit
      return US_CAN_BUY
    }
    else if (rank == level + 1 && !isCampaignWithUnitsResearch.get())
      canBuyOnLvlUp[name] <- unit
    return name in unitTreeNodes?[unit.campaign] ? US_NOT_RESEARCHED : US_TOO_LOW_LEVEL
  })
  let canLevelUpWithoutBuy = (isReadyForLevelUp && hasOwnUnitForCurrentLevelUp)
    || isCampaignWithUnitsResearch.get()
  if (isReadyForLevelUp)
    canBuy.__update(canBuyOnLvlUp)
  return { canBuy, canBuyOnLvlUp, unitStatus, canLevelUpWithoutBuy }
})

let unlockedPlatoonUnits = Computed(function() {
  let res = []
  foreach(unit in campMyUnits.get()) {
    let { level = 0, platoonUnits = [] } = unit
    platoonUnits.each(@(pu) level >= pu.reqLevel ? res.append(pu.name) : null)
  }
  return res
})

let canBuyUnits = Computed(@() buyUnitsData.value.canBuy)
let canBuyUnitsStatus = Computed(@() buyUnitsData.value.unitStatus)

function getUnitLockedShortText(unit, status, reqPlayerLevel) {
  if (unit == null || status == null || reqPlayerLevel == null)
    return ""
  if (status == US_TOO_LOW_LEVEL)
    return " ".concat(loc("multiplayer/level"), reqPlayerLevel)
  else if (status == US_NOT_FOR_SALE)
    return loc("options/unavailable")
  return ""
}

function setCurrentUnit(unitName) {
  if (curUnitInProgress.get() != null)
    return "unitInProgress"
  if (unitName not in campMyUnits.get())
    return "unitNotOwn"
  if (campMyUnits.get()[unitName].isCurrent)
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
  US_NOT_RESEARCHED
  US_NEED_BLUEPRINTS
  US_CAN_RESEARCH

  buyUnitsData
  canBuyUnits
  canBuyUnitsStatus

  getUnitLockedShortText

  unlockedPlatoonUnits

  setCurrentUnit
}
