from "%globalsDarg/darg_library.nut" import *
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { add_unit_attributes } = require("%appGlobals/pServer/pServerApi.nut")
let { selAttributes, curCategoryId, attrPresets, calcStatus, sumCost, MAX_AVAIL_STATUS
} = require("%rGui/attributes/attrState.nut")

let isUnitAttrOpened = mkWatched(persist, "isUnitAttrOpened", false)

let attrUnitData = Computed(function() {
  let unit = myUnits.get()?[hangarUnitName.get()]
  return {
    unit
    preset = attrPresets.get()?[unit?.attrPreset] ?? []
  }
})

let attrUnitName = Computed(@() attrUnitData.get().unit?.name)
let attrUnitType = Computed(@() attrUnitData.get().unit?.unitType)
let unitAttributes = Computed(@() attrUnitData.get().unit?.attrLevels)
let attrUnitPreset = Computed(@() attrUnitData.get().unit?.preset)
let attrUnitLevelsToMax = Computed(@() (attrUnitData.get().unit?.levels.len() ?? 0) - (attrUnitData.get().unit?.level ?? 0))

function resetAttrState() {
  selAttributes({})
  curCategoryId(attrUnitData.get().preset?[0].id)
}
resetAttrState()
attrUnitName.subscribe(@(_) resetAttrState())

let curCategory = Computed(@() attrUnitData.get().preset.findvalue(@(p) p.id == curCategoryId.value))

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

function applyAttributes() {
  if (selAttrSpCost.value <= 0)
    return
  add_unit_attributes(attrUnitName.value, selAttributes.value, selAttrSpCost.value)
}



return {
  openUnitAttrWnd = @() isUnitAttrOpened(true)
  isUnitAttrOpened

  attrUnitData
  attrUnitName
  attrUnitType
  attrUnitPreset
  attrUnitLevelsToMax
  curCategory
  unitAttributes
  selAttrSpCost
  totalUnitSp
  leftUnitSp
  isUnitMaxSkills
  availableAttributes

  resetAttrState
  applyAttributes
}
