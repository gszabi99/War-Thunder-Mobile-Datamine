from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { eventbus_subscribe } = require("eventbus")
local compatibilitBGModels = []
let { hangar_load_model_with_skin,
  hangar_get_current_unit_name, hangar_get_loaded_unit_name, change_background_models_list_with_skin,
  change_one_background_model_with_skin, hangar_get_current_unit_skin, get_current_background_models_list = @() compatibilitBGModels
} = require("hangar")
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { isInMenu, isInMpSession, isInLoadingScreen, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let isHangarUnitLoaded = mkWatched(persist, "isHangarUnitLoaded", false)

let loadedInfo = Watched({
  name = hangar_get_current_unit_name()
  skin = hangar_get_current_unit_skin()
})
let loadedHangarUnitName = Computed(@() loadedInfo.value.name)
let hangarUnitData = mkWatched(persist, "hangarUnitData", null)
let hangarUnitDataBackup = mkWatched(persist, "hangarUnitDataBackup", null)
let hangarUnitName = Computed(@() hangarUnitData.value?.name ?? loadedHangarUnitName.value ?? "")
local wasLoadBgModelsAfterLoading = false

let mainHangarUnit = Computed(function() {
  let { name = loadedHangarUnitName.value, custom = null } = hangarUnitData.value
  if (custom != null) {
    if (custom.name not in allUnitsCfg.get()) {
      let mainName = allUnitsCfg.get().findindex(@(u) u.platoonUnits.findvalue(@(pu) pu.name == custom.name) != null)
      if (mainName != null)
        return custom.__merge({ name = mainName })
    }
    return custom
  }

  local unit = myUnits.get()?[name] ?? allUnitsCfg.get()?[name]
  if (unit != null || name == "")
    return unit

  foreach (src in [ myUnits, allUnitsCfg ]) {
    unit = src.get().findvalue(@(u) u.platoonUnits.findvalue(@(pu) pu.name == name) != null)
    if (unit != null)
      return unit
  }
  return null
})

let hangarUnit = Computed(function() {
  let mainUnit = mainHangarUnit.get()
  let { name = loadedHangarUnitName.value } = hangarUnitData.value
  if (mainUnit == null || name == mainUnit.name)
    return mainUnit
  return mainUnit.__merge(mainUnit.platoonUnits.findvalue(@(pu) pu.name == name) ?? {})
})

let nameAndSkin = @(name, skin, currentSkins, defSkin) { name, skin = skin ?? currentSkins?[name] ?? defSkin }

let hangarBgUnits = Computed(function(prevC) {
  if (hangarUnit.get() == null || (hangarUnit.get()?.platoonUnits.len() ?? 0) == 0)
    return []
  let skin = hangarUnitData.get()?.skin
  let { platoonUnits, currentSkins = {}, isUpgraded = false } = mainHangarUnit.get()
  let mainName = mainHangarUnit.get().name
  let fgName = hangarUnit.get().name
  let allNames = platoonUnits.reduce(@(res, p) res.$rawset(p.name, true), { [mainName] = true })
  let defSkin = isUpgraded ? "upgraded" : ""

  let prev = type(prevC) == "array" ? prevC : get_current_background_models_list()
  if (prev.len() + 1 == allNames.len() && prev.findvalue(@(p) p.name not in allNames) == null) {
    //previous bh units are from the same squad
    let leftNames = clone allNames
    delete leftNames[fgName]
    return prev
      .map(function(p) {
        if (p.name not in leftNames)
          return null
        delete leftNames[p.name]
        return nameAndSkin(p.name, skin, currentSkins, defSkin)
      })
     .map(function(p) {
       if (p != null)
         return p
       let name = mainName in leftNames ? mainName
         : leftNames.findindex(@(_) true)
       if (name in leftNames)
         delete leftNames[name]
       return nameAndSkin(name, skin, currentSkins, defSkin)
     })
  }

  //previuos bg units are from othe squad
  let res = platoonUnits.map(@(p) nameAndSkin(p.name, skin, currentSkins, defSkin))
  if (mainName != fgName) {
    let idx = res.findindex(@(p) p.name == fgName)
    if (idx != null)
      res[idx] = nameAndSkin(mainName, skin, currentSkins, defSkin)
  }
  return res
})

let hangarUnitSkin = Computed(@() hangarUnitData.get()?.skin
  ?? hangarUnit.get()?.currentSkins[hangarUnit.get()?.name]
  ?? (hangarUnit.get()?.isUpgraded ? "upgraded" : ""))

function loadModel(unitName, skin) {
  if ((unitName ?? "") == "" && hangar_get_current_unit_name() == "")
    //fallback to any unit from config units
    unitName = (myUnits.value.findvalue(@(_) true) ?? allUnitsCfg.value.findvalue(@(_) true))?.name

  if ((unitName ?? "") == "")
    return

  if (hangar_load_model_with_skin.getfuncinfos().paramscheck == 3)
    hangar_load_model_with_skin(unitName, skin)
  else
    hangar_load_model_with_skin(unitName, skin, hangarUnit.get()?.isUpgraded ?? false)
}

let loadCurrentHangarUnitModel = @() loadModel(hangarUnitName.value, hangarUnitSkin.value)
loadCurrentHangarUnitModel()
hangarUnitName.subscribe(@(_) loadCurrentHangarUnitModel())
hangarUnitSkin.subscribe(@(_) loadCurrentHangarUnitModel())

isInMpSession.subscribe(function(v) {
  if (v || !isInMenu.value || hangar_get_current_unit_name() == loadedInfo.value.name)
    return
  loadedInfo({
    name = hangar_get_current_unit_name()
    skin = hangar_get_current_unit_skin()
  })
  loadCurrentHangarUnitModel()
})

let function reloadAllBgModels() {
  compatibilitBGModels = hangarBgUnits.get()
  change_background_models_list_with_skin(hangarUnitName.get(), hangarBgUnits.get())
}

function loadBGModels() {
  let bgUnits = hangarBgUnits.get()
  if (bgUnits.len() == 0)
    return
  let { name, skin } = loadedInfo.get()
  if (name == null || name != hangarUnitName.get() || skin != hangarUnitSkin.get())
    return //wait for load finalization

  if (!wasLoadBgModelsAfterLoading) {
    reloadAllBgModels()
    wasLoadBgModelsAfterLoading = true
    return
  }

  local wasBgUnits = get_current_background_models_list()
  if (wasBgUnits.len() != bgUnits.len()) {
    reloadAllBgModels()
    return
  }

  local changedIdx = null
  foreach(i, u in wasBgUnits)
    if (u.name != bgUnits[i].name || u.skin != bgUnits[i].skin) {
      if (changedIdx == null)
        changedIdx = i
      else {
        reloadAllBgModels()
        return
      }
    }

  if (changedIdx == null)
    return

  change_one_background_model_with_skin(wasBgUnits[changedIdx].name, bgUnits[changedIdx].name, bgUnits[changedIdx].skin)
}
loadBGModels()

loadedInfo.subscribe(@(_) loadBGModels())
hangarBgUnits.subscribe(@(_) loadBGModels())

isInLoadingScreen.subscribe(function(v) {
  if (v)
    wasLoadBgModelsAfterLoading = false
})

let setHangarUnit = @(unitName) hangarUnitData({ name = unitName ?? "" })

let setHangarUnitWithSkin = @(name, skin) hangarUnitData({ name, skin })

function setCustomHangarUnit(customUnit) {
  if (hangarUnitDataBackup.value == null)
    hangarUnitDataBackup(hangarUnitData.value)
  hangarUnitData({ name = customUnit.name, custom = customUnit })
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
  loadCurrentHangarUnitModel()
  reloadAllBgModels()
})

eventbus_subscribe("onHangarModelStartLoad", @(_) isHangarUnitLoaded(false))

eventbus_subscribe("onHangarModelLoaded", function(_) {
  isHangarUnitLoaded(true)
  if (hangar_get_loaded_unit_name() != hangar_get_current_unit_name())
    return
  let lInfo = {
    name = hangar_get_current_unit_name()
    skin = hangar_get_current_unit_skin()
  }

  if (!isEqual(loadedInfo.value, lInfo))
    loadedInfo(lInfo)
  if (lInfo.name != hangarUnitName.get() || lInfo.skin != hangarUnitSkin.get()) {
    log("Reload hangar unit because of wrong skin")
    loadCurrentHangarUnitModel()
  }
})

return {
  loadedHangarUnitName //already loaded hangar unit name
  hangarUnitName //wanted hangar unit name
  hangarUnit //wanted hangar unit
  hangarUnitSkin
  hangarUnitDataBackup

  setHangarUnit  //unit will be used from own units or from allUnitsCfg
  setHangarUnitWithSkin
  setCustomHangarUnit  //will be forced cutsom unit params
  resetCustomHangarUnit //restore previous unit after custom one
  isHangarUnitLoaded

  mainHangarUnit
  mainHangarUnitName = Computed(@() mainHangarUnit.get()?.name)
}