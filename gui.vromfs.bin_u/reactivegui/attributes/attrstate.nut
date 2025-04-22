from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")

let selAttributes = mkWatched(persist, "selAttributes", {})
let curCategoryId = mkWatched(persist, "curCategoryId", null)
let lastModifiedAttr = Watched(null)

const AVAIL_PART_FOR_GROUP = 0.7
const MAX_AVAIL_STATUS = 3

let hasSlotAttrPreset = Computed(@() campConfigs.get()?.campaignCfg.slotAttrPreset != "")

let attrPresets = Computed(function() {
  let { unitAttrPresets = [], unitAttrCostTables = null } = serverConfigs.get()
  return unitAttrPresets.map(@(preset)
    preset.map(@(category)
      category.__merge({
        attrList = (category?.attrList ?? []).map(@(attr)
          attr.__merge({
            levelCost = unitAttrCostTables?[attr?.levelCostTbl] ?? []
          }))
      }))
  )
})

function sumCost(costTbl, curLvl, finalLvl) {
  local res = 0
  for (local i = curLvl; i < finalLvl; i++)
    res += costTbl?[i] ?? 0
  return res
}

function calcStatus(avail) {
  let minCount = AVAIL_PART_FOR_GROUP * avail[0]
  if (minCount == 0 || avail[1] == 0)
    return -1 
  for (local i = avail.len() - 1; i > 0; i--)
    if (avail[i] >= minCount)
      return i + 1
  return 0 
}

function getMaxAttrLevelData(attr, fromLevel, availSp) {
  local maxLevel = fromLevel
  local maxLevelSp = 0
  for (maxLevel; maxLevel < attr.levelCost.len(); maxLevel++) {
    let cost = attr.levelCost[maxLevel]
    if (availSp < cost)
      break
    availSp -= cost
    maxLevelSp += cost
  }
  return { maxLevel, maxLevelSp }
}

function setAttribute(catId, attrId, value) {
  selAttributes(selAttributes.get().__merge({
    [catId] = (selAttributes.get()?[catId] ?? {}).__merge({
      [attrId] = value
    })
  }))
  lastModifiedAttr(attrId)
}

let getSpCostText = @(val) $"⋥{val}"

return {
  hasSlotAttrPreset,
  lastModifiedAttr,
  selAttributes,
  curCategoryId,
  attrPresets,

  getMaxAttrLevelData,
  getSpCostText,
  setAttribute,
  calcStatus,
  sumCost,

  AVAIL_PART_FOR_GROUP,
  MAX_AVAIL_STATUS
}