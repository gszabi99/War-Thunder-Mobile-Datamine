from "%globalsDarg/darg_library.nut" import *
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { add_unit_attributes } = require("%appGlobals/pServer/pServerApi.nut")

let isUnitAttrOpened = mkWatched(persist, "isUnitAttrOpened", false)

let selAttributes = mkWatched(persist, "selAttributes", {})
let curCategoryId = mkWatched(persist, "curCategoryId", null)
let lastModifiedAttr = Watched(null)

const AVAIL_PART_FOR_GROUP = 0.7
const MAX_AVAIL_STATUS = 3

let attrPresets = Computed(function() {
  let { unitAttrPresets = [], unitAttrCostTables = null } = campConfigs.value
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

let attrUnitData = Computed(function() {
  let unit = myUnits.value?[hangarUnitName.value]
  return {
    unit
    preset = attrPresets.value?[unit?.attrPreset] ?? []
  }
})

let attrUnitName = Computed(@() attrUnitData.value.unit?.name)
let attrUnitType = Computed(@() attrUnitData.value.unit?.unitType)
let unitAttributes = Computed(@() attrUnitData.value.unit?.attrLevels)
let attrUnitPreset = Computed(@() attrUnitData.value.unit?.preset)
let attrUnitLevelsToMax = Computed(@() (attrUnitData.value.unit?.levels.len() ?? 0) - (attrUnitData.value.unit?.level ?? 0))

function resetAttrState() {
  selAttributes({})
  curCategoryId(attrUnitData.value.preset?[0].id)
}
resetAttrState()
attrUnitName.subscribe(@(_) resetAttrState())

let curCategory = Computed(@() attrUnitData.value.preset.findvalue(@(p) p.id == curCategoryId.value))

function sumCost(costTbl, curLvl, finalLvl) {
  local res = 0
  for (local i = curLvl; i < finalLvl; i++)
    res += costTbl?[i] ?? 0
  return res
}

let selAttrSpCost = Computed(function() {
  local res = 0
  let { unit, preset } = attrUnitData.value
  if (unit == null)
    return 0
  foreach (cat in preset)
    foreach (attr in cat.attrList)
      res += sumCost(attr.levelCost, unit.attrLevels?[cat.id][attr.id] ?? 0, selAttributes.value?[cat.id][attr.id])
  return res
})

let totalUnitSp = Computed(@() attrUnitData.value.unit?.sp ?? 0)
let leftUnitSp = Computed(@() totalUnitSp.value - selAttrSpCost.value)
let isUnitMaxSkills = Computed(function() {
  let { unit, preset } = attrUnitData.value
  if (unit == null)
    return false
  return null == preset.findvalue(@(cat)
    null != cat.attrList.findvalue(@(attr) attr.levelCost.len() > (unit.attrLevels?[cat.id][attr.id] ?? 0)))
})

function calcStatus(avail) {
  let minCount = AVAIL_PART_FOR_GROUP * avail[0]
  if (minCount == 0 || avail[1] == 0)
    return -1 //nothing
  for (local i = avail.len() - 1; i > 0; i--)
    if (avail[i] >= minCount)
      return i + 1
  return 0 //something to upgrade
}

let availableAttributes = Computed(function() {
  let { unit = null, preset = null } = attrUnitData.value
  let { attrLevels = null } = unit
  let leftSp = leftUnitSp.value
  if (attrLevels == null || preset == null || leftSp <= 0 || isUnitMaxSkills.get())
    return { status = -1, statusByCat = [] }
  let selAttr = selAttributes.value
  let avail = array(MAX_AVAIL_STATUS, 0)
  let availCats = []
  foreach (cat in preset) {
    let cAvail = array(MAX_AVAIL_STATUS, 0)
    foreach (attr in cat.attrList) {
      let level = selAttr?[cat.id][attr.id] ?? attrLevels?[cat.id][attr.id] ?? 0
      if (attr.levelCost.len() <= level)
        continue
      avail[0]++
      cAvail[0]++
      local cost = 0
      for (local inc = 0; inc < MAX_AVAIL_STATUS - 1; inc++) {
        cost += attr.levelCost?[level + inc] ?? 0
        if (cost <= leftSp) {
          avail[inc + 1]++
          cAvail[inc + 1]++
        }
        else
          break
      }
    }
    availCats.append(cAvail)
  }
  return {
    status = calcStatus(avail)
    statusByCat = availCats.map(calcStatus)
  }
})

let getSpCostText = @(val) $"⋥{val}"

function applyAttributes() {
  if (selAttrSpCost.value <= 0)
    return
  add_unit_attributes(attrUnitName.value, selAttributes.value, selAttrSpCost.value)
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
  selAttributes(selAttributes.value.__merge({
    [catId] = (selAttributes.value?[catId] ?? {}).__merge({
      [attrId] = value
    })
  }))
  lastModifiedAttr(attrId)
}

return {
  openUnitAttrWnd = @() isUnitAttrOpened(true)
  isUnitAttrOpened

  attrUnitData
  attrUnitName
  attrUnitType
  attrUnitPreset
  attrUnitLevelsToMax
  curCategoryId
  curCategory
  unitAttributes
  selAttributes
  selAttrSpCost
  totalUnitSp
  leftUnitSp
  isUnitMaxSkills
  availableAttributes
  lastModifiedAttr

  attrPresets

  resetAttrState
  applyAttributes
  getMaxAttrLevelData
  setAttribute
  sumCost
  getSpCostText
}
