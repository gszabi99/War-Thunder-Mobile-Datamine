from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { subscribe } = require("eventbus")
let { hangar_load_model, hangar_load_upgraded_model,
  hangar_get_current_unit_name, hangar_get_loaded_unit_name, is_hangar_model_upgraded,
  change_background_models_list, change_one_background_model
} = require("hangar")
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { isInMenu, isInMpSession, isInLoadingScreen, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let isHangarUnitLoaded = mkWatched(persist, "isHangarUnitLoaded", false)

let loadedInfo = Watched({
  name = hangar_get_current_unit_name()
  isUpgraded = is_hangar_model_upgraded()
})
let loadedHangarUnitName = Computed(@() loadedInfo.value.name)
let isLoadedHangarUnitUpgraded = Computed(@() loadedInfo.value.isUpgraded)
let hangarUnitData = mkWatched(persist, "hangarUnitData", null)
let hangarUnitDataBackup = mkWatched(persist, "hangarUnitDataBackup", null)
let hangarUnitName = Computed(@() hangarUnitData.value?.name ?? loadedHangarUnitName.value ?? "")

let hangarUnit = Computed(function() {
  let { name = loadedHangarUnitName.value, custom = null } = hangarUnitData.value
  if (custom != null)
    return custom

  local unit = myUnits.value?[name] ?? allUnitsCfg.value?[name]
  if (unit != null || name == "")
    return unit

  foreach (src in [ myUnits, allUnitsCfg ]) {
    unit = src.value.findvalue(@(u) u.platoonUnits.findvalue(@(pu) pu.name == name) != null)
    if (unit != null)
      return unit.__merge(unit.platoonUnits.findvalue(@(pu) pu.name == name))
  }
  return null
})
let isHangarUnitUpgraded = Computed(@() hangarUnit.value?.isUpgraded ?? false)

let function loadModel(unitName, isUpgraded) {
  if ((unitName ?? "") == "" && hangar_get_current_unit_name() == "")
    //fallback to any unit from config units
    unitName = (myUnits.value.findvalue(@(_) true) ?? allUnitsCfg.value.findvalue(@(_) true))?.name

  if ((unitName ?? "") == ""
      || (unitName == hangar_get_current_unit_name() && isUpgraded == is_hangar_model_upgraded()))
    return

  if (isUpgraded)
    hangar_load_upgraded_model(unitName)
  else
    hangar_load_model(unitName)
}

let loadCurrentHangarUnitModel = @() loadModel(hangarUnitName.value, isHangarUnitUpgraded.value)
loadCurrentHangarUnitModel()
hangarUnitName.subscribe(@(_) loadCurrentHangarUnitModel())
isHangarUnitUpgraded.subscribe(@(_) loadCurrentHangarUnitModel())

local hangarPlatoonUnits = []
local hangarPlatoonMainUnit = null
local isHangarPlatoonUpgraded = false

isInMenu.subscribe(function(v) {
  if (v)
    return
  hangarPlatoonUnits = []
  hangarPlatoonMainUnit = null
})

isInMpSession.subscribe(function(v) {
  if (v || !isInMenu.value || hangar_get_current_unit_name() == loadedInfo.value.name)
    return
  hangarPlatoonUnits = []
  hangarPlatoonMainUnit = null
  loadedInfo({
    name = hangar_get_current_unit_name()
    isUpgraded = is_hangar_model_upgraded()
  })
  loadCurrentHangarUnitModel()
})

let function reloadBGModels() {
  let unitName = hangarUnitName.value
  if (unitName == "")
    return
  let platoonUnits = (allUnitsCfg.value?[unitName].platoonUnits ?? []).map(@(pu) pu.name)
  if (platoonUnits.len() == 0) {
    hangarPlatoonMainUnit = null
    return
  }

  hangarPlatoonMainUnit = unitName
  isHangarPlatoonUpgraded = isHangarUnitUpgraded.value
  hangarPlatoonUnits = platoonUnits
  change_background_models_list(unitName, platoonUnits)
}
reloadBGModels()

loadedInfo.subscribe(function(lInfo) {
  let unitName = lInfo?.name
  let { isUpgraded = false } = lInfo
  if (unitName == null || unitName != hangarUnitName.value || isUpgraded != isHangarUnitUpgraded.value)
    return //wait for load finalization

  let idx = hangarPlatoonUnits.findindex(@(v) v == unitName)
  if (idx == null || hangarPlatoonMainUnit == null || isHangarPlatoonUpgraded != isHangarUnitUpgraded.value)
    reloadBGModels()
  else {
    hangarPlatoonUnits[idx] = hangarPlatoonMainUnit
    change_one_background_model(unitName, hangarPlatoonMainUnit)
    hangarPlatoonMainUnit = unitName
    isHangarPlatoonUpgraded = isHangarUnitUpgraded.value
  }
})

let setHangarUnit = @(unitName, isFullChange = true)
  hangarUnitData({ name = unitName ?? "", isFullChange })

let function setCustomHangarUnit(customUnit, isFullChange = true) {
  if (hangarUnitDataBackup.value == null)
    hangarUnitDataBackup(hangarUnitData.value)
  hangarUnitData({ name = customUnit.name, custom = customUnit, isFullChange })
}

let function resetCustomHangarUnit() {
  if (hangarUnitDataBackup.value) {
    hangarUnitData(hangarUnitDataBackup.value)
    hangarUnitDataBackup(null)
  }
}

subscribe("downloadAddonsFinished", function(_) {
  if (isInBattle.value || isInLoadingScreen.value)
    return
  hangarPlatoonUnits = []
  loadCurrentHangarUnitModel()
  reloadBGModels()
})

subscribe("onHangarModelStartLoad", @(_) isHangarUnitLoaded(false))

subscribe("onHangarModelLoaded", function(_) {
  isHangarUnitLoaded(true)
  if (hangar_get_loaded_unit_name() != hangar_get_current_unit_name())
    return
  let lInfo = {
    name = hangar_get_current_unit_name()
    isUpgraded = is_hangar_model_upgraded()
  }
 if (!isEqual(loadedInfo.value, lInfo))
   loadedInfo(lInfo)
})

return {
  loadedHangarUnitName //already loaded hangar unit name
  isLoadedHangarUnitUpgraded
  hangarUnitName //wanted hangar unit name
  hangarUnit //wanted hangar unit

  setHangarUnit  //unit will be used from own units or from allUnitsCfg
  setCustomHangarUnit  //will be forced cutsom unit params
  resetCustomHangarUnit //restore previous unit after custom one
  isHangarUnitLoaded
}