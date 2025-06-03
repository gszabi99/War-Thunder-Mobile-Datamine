from "%globalsDarg/darg_library.nut" import *
let { getUnitTagsShop } = require("%appGlobals/unitTags.nut")
let { getAttrValRaw, applyAttrLevels } = require("%rGui/attributes/attrValues.nut")

function getUnitStats(commonData) {
  let { unitDataCache, sharedWatches } = commonData
  let { serverConfigsW, servProfileW, attrPresetsW } = sharedWatches
  if (unitDataCache?.unitStats == null) {
    let { unit } = commonData
    let shopCfg = getUnitTagsShop(unit.name)
    let unitCampaignCfg = serverConfigsW.get()?.campaignCfg[unit.campaign]
    let slotAttrPreset = unitCampaignCfg?.slotAttrPreset
    let attrLevels = slotAttrPreset != ""
      ? servProfileW.get()?.campaignSlots[unit.campaign]?.slots
          .findvalue(@(slot) slot.name == unit.name)?.attrLevels ?? {}
      : unit?.attrLevels ?? {}
    let attrPreset = slotAttrPreset != ""
      ? attrPresetsW.get()?[slotAttrPreset] ?? []
      : attrPresetsW.get()?[unit?.attrPreset] ?? []
    unitDataCache.unitStats <- applyAttrLevels(unit.unitType, shopCfg, attrLevels, attrPreset, unit?.mods)
  }
  return unitDataCache.unitStats
}

function getUnitAttrValRaw(commonData, catId, attrId) {
  let { unit, sharedWatches } = commonData
  let { serverConfigsW, servProfileW, attrPresetsW } = sharedWatches
  let shopCfg = getUnitTagsShop(unit.name)
  let unitCampaignCfg = serverConfigsW.get()?.campaignCfg[unit.campaign]
  let slotAttrPreset = unitCampaignCfg?.slotAttrPreset
  let attrLevels = slotAttrPreset != ""
    ? servProfileW.get()?.campaignSlots[unit.campaign]?.slots
        .findvalue(@(slot) slot.name == unit.name)?.attrLevels ?? {}
    : unit?.attrLevels ?? {}
  let attrPreset = slotAttrPreset != ""
    ? attrPresetsW.get()?[slotAttrPreset] ?? []
    : attrPresetsW.get()?[unit?.attrPreset] ?? []
  let attr = attrPreset.findvalue(@(v) v.id == catId)?.attrList.findvalue(@(v) v.id == attrId)
  let step = attrLevels?[catId][attrId] ?? 0
  return getAttrValRaw(unit.unitType, attr, step, shopCfg, unit?.mods)
}

return {
  getUnitStats
  getUnitAttrValRaw
}
