let { loc } = require("dagor.localize")
let { Computed } = require("frp")
let { set_current_unit, curUnitInProgress, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { campMyUnits, campUnitsCfg, selectedUnitByPlayer, curUnitName } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let US_UNKNOWN = 0
let US_OWN = 1
let US_CAN_BUY = 2
let US_NOT_FOR_SALE = 4
let US_NOT_RESEARCHED = 5
let US_NEED_BLUEPRINTS = 6
let US_CAN_RESEARCH = 7

let UUP_NOT_UPGRADEABLE = 0x01
let UUP_UPGRADEABLE = 0x02
let UUP_UPGRADED = 0x04

let UC_RESEARCHABLE = 0x01
let UC_BLUEPRINT = 0x02
let UC_COLLECTIBLE = 0x04
let UC_PREMIUM = 0x08
let UC_SEASON_PREMIUM = 0x10
let UC_OTHER = 0x20


let buyUnitsData = Computed(function() {
  let { unitsResearch = {}, blueprints = {} } = servProfile.get()
  let { unitResearchExp = {}, allBlueprints = {} } = serverConfigs.get()
  let canBuy = {}
  let unitStatus = campUnitsCfg.get().map(function(unit) {
    let { name } = unit
    if (name in campMyUnits.get())
      return US_OWN
    if (unit.costGold <= 0 && unit.costWp <= 0)
      return US_NOT_FOR_SALE

    if (name in allBlueprints) {
      if ((blueprints?[name] ?? 0) >= (allBlueprints?[name]?.targetCount ?? 0)) {
        canBuy[name] <- unit
        return US_CAN_BUY
      }
      return US_NEED_BLUEPRINTS
    }
    if (unitsResearch?[name].canResearch && name in unitResearchExp)
      return US_CAN_RESEARCH
    if (unit.isPremium
        || (name in unitResearchExp && unitsResearch?[name].canBuy)) {
      canBuy[name] <- unit
      return US_CAN_BUY
    }
    return US_NOT_RESEARCHED
  })
  return { canBuy, unitStatus }
})

let unlockedPlatoonUnits = Computed(function() {
  let res = []
  foreach(unit in campMyUnits.get()) {
    let { level = 0, platoonUnits = [] } = unit
    platoonUnits.each(function(pu) {
      if (level >= pu.reqLevel)
        res.append(pu.name)
    })
  }
  return res
})

let canBuyUnits = Computed(@() buyUnitsData.get().canBuy)
let canBuyUnitsStatus = Computed(@() buyUnitsData.get().unitStatus)

function getUnitLockedShortText(unit, status, reqPlayerLevel) {
  if (unit == null || status == null || reqPlayerLevel == null)
    return ""
  else if (status == US_NOT_FOR_SALE)
    return loc("options/unavailable")
  return ""
}

function setCurrentUnit(unitName) {
  if (unitName not in campMyUnits.get())
    return "unitNotOwn"
  if (curUnitName.get() == unitName)
    return "unitIsAlreadyCurrent"
  selectedUnitByPlayer.set(unitName)
  return ""
}

registerHandler("onSetCurrentUnit", function(_, context) {
  if (context.unit == selectedUnitByPlayer.get())
    selectedUnitByPlayer.set(null)
  else if (selectedUnitByPlayer.get() != null)
    set_current_unit(selectedUnitByPlayer.get(), { id = "onSetCurrentUnit", unit = selectedUnitByPlayer.get() })
})

selectedUnitByPlayer.subscribe(@(v) v == null || curUnitInProgress.get() != null ? null
  : set_current_unit(v, { id = "onSetCurrentUnit", unit = v }))

let getUnitCategory = @(unit, unitResearchExp, allBlueprints)
  unit.name in unitResearchExp ? UC_RESEARCHABLE
    : unit.name in allBlueprints ? UC_BLUEPRINT
    : unit.isCollectible ? UC_COLLECTIBLE
    : unit.isPremium && !unit.isHidden ? UC_PREMIUM
    : unit.isPremium ? UC_SEASON_PREMIUM
    : UC_OTHER

return {
  US_UNKNOWN
  US_OWN
  US_NOT_FOR_SALE
  US_CAN_BUY
  US_NOT_RESEARCHED
  US_NEED_BLUEPRINTS
  US_CAN_RESEARCH

  UUP_NOT_UPGRADEABLE
  UUP_UPGRADEABLE
  UUP_UPGRADED

  UC_RESEARCHABLE
  UC_BLUEPRINT
  UC_COLLECTIBLE
  UC_PREMIUM
  UC_SEASON_PREMIUM
  UC_OTHER

  getUnitCategory

  canBuyUnits
  canBuyUnitsStatus

  getUnitLockedShortText

  unlockedPlatoonUnits

  setCurrentUnit
}
