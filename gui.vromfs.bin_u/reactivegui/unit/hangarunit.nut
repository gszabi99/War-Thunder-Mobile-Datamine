from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { hangar_load_model_with_skin,
  hangar_get_current_unit_name, hangar_get_loaded_unit_name, is_hangar_model_upgraded,
  change_one_background_model, change_background_models_list_with_skin,
  change_one_background_model_with_skin, hangar_get_current_unit_skin
} = require("hangar")
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { isInMenu, isInMpSession, isInLoadingScreen, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let isHangarUnitLoaded = mkWatched(persist, "isHangarUnitLoaded", false)

let loadedInfo = Watched({
  name = hangar_get_current_unit_name()
  isUpgraded = is_hangar_model_upgraded()
  skin = hangar_get_current_unit_skin()
})
let loadedHangarUnitName = Computed(@() loadedInfo.value.name)
let isLoadedHangarUnitUpgraded = Computed(@() loadedInfo.value.isUpgraded)
let currentLoadedUnitSkin = Computed(@() loadedInfo.value.skin)
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
let hangarUnitSkin = Computed(@() isHangarUnitUpgraded.get() ? "upgraded" : "")
local skinChanged = false

function loadModel(unitName, isUpgraded) {
  if ((unitName ?? "") == "" && hangar_get_current_unit_name() == "")
    //fallback to any unit from config units
    unitName = (myUnits.value.findvalue(@(_) true) ?? allUnitsCfg.value.findvalue(@(_) true))?.name

  if ((unitName ?? "") == "")
    return

  hangar_load_model_with_skin(unitName, hangarUnitSkin.value, isUpgraded)
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
    skin = hangar_get_current_unit_skin()
  })
  loadCurrentHangarUnitModel()
})

function reloadBGModels() {
  let unitName = hangarUnitName.value
  if (unitName == "")
    return
  let platoonUnits = (allUnitsCfg.value?[unitName].platoonUnits ?? []).map(@(pu) {name=pu.name skin=hangarUnitSkin.value})
  if (platoonUnits.len() == 0) {
    hangarPlatoonMainUnit = null
    return
  }

  hangarPlatoonMainUnit = {name=unitName skin=hangarUnitSkin.value}
  isHangarPlatoonUpgraded = isHangarUnitUpgraded.value
  hangarPlatoonUnits = platoonUnits

  change_background_models_list_with_skin(unitName, platoonUnits)
}
reloadBGModels()

loadedInfo.subscribe(function(lInfo) {
  let unitName = lInfo?.name
  let { isUpgraded = false } = lInfo

  skinChanged = unitName != null && unitName == hangarUnitName.value && currentLoadedUnitSkin.value != hangarUnitSkin.value

  if (unitName == null || unitName != hangarUnitName.value || (isUpgraded != isHangarUnitUpgraded.value && !skinChanged))
    return //wait for load finalization

  let idx = hangarPlatoonUnits.findindex(@(v) v.name == unitName)
  if (idx == null || hangarPlatoonMainUnit == null || isHangarPlatoonUpgraded != isHangarUnitUpgraded.value || skinChanged)
    reloadBGModels()
  else {
    hangarPlatoonUnits[idx] = hangarPlatoonMainUnit

    if (skinChanged)
      change_one_background_model_with_skin(unitName, hangarPlatoonMainUnit.name, currentLoadedUnitSkin.value)
    else
      change_one_background_model(unitName, hangarPlatoonMainUnit.name)

    hangarPlatoonMainUnit = {name=unitName skin=hangarUnitSkin.value}
    isHangarPlatoonUpgraded = isHangarUnitUpgraded.value
  }

  skinChanged = false
})

let setHangarUnit = @(unitName, isFullChange = true)
  hangarUnitData({ name = unitName ?? "", isFullChange })

function setCustomHangarUnit(customUnit, isFullChange = true) {
  if (hangarUnitDataBackup.value == null)
    hangarUnitDataBackup(hangarUnitData.value)
  hangarUnitData({ name = customUnit.name, custom = customUnit, isFullChange })
}

function resetCustomHangarUnit() {
  if (hangarUnitDataBackup.value) {
    hangarUnitData(hangarUnitDataBackup.value)
    hangarUnitDataBackup(null)
  }
}

eventbus_subscribe("downloadAddonsFinished", function(_) {
  if (isInBattle.value || isInLoadingScreen.value)
    return
  hangarPlatoonUnits = []
  loadCurrentHangarUnitModel()
  reloadBGModels()
})

eventbus_subscribe("onHangarModelStartLoad", @(_) isHangarUnitLoaded(false))

eventbus_subscribe("onHangarModelLoaded", function(_) {
  isHangarUnitLoaded(true)
  if (hangar_get_loaded_unit_name() != hangar_get_current_unit_name())
    return
  let lInfo = {
    name = hangar_get_current_unit_name()
    isUpgraded = is_hangar_model_upgraded()
    skin = hangar_get_current_unit_skin()
  }
 if (!isEqual(loadedInfo.value, lInfo))
   loadedInfo(lInfo)
})

return {
  loadedHangarUnitName //already loaded hangar unit name
  isLoadedHangarUnitUpgraded
  hangarUnitName //wanted hangar unit name
  hangarUnit //wanted hangar unit
  hangarUnitDataBackup

  setHangarUnit  //unit will be used from own units or from allUnitsCfg
  setCustomHangarUnit  //will be forced cutsom unit params
  resetCustomHangarUnit //restore previous unit after custom one
  isHangarUnitLoaded
}